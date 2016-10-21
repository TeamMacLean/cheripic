# encoding: utf-8
require 'bio'
require 'forwardable'

module Cheripic


  # Custom error handling for Variants class
  class VariantsError < CheripicError; end

  # A Variants object for each analysis pipeline that stores
  # assembly details and extracts pileups for each contig
  # assembly and pileup details are stored as
  # hashes of Contig and ContigPileups objects
  #
  # @!attribute [r] assembly
  #   @return [Hash] a hash of contig ids from assembly as keys and respective Contig objects as values
  # @!attribute [r] pileups
  #   @return [Hash] a hash of contig ids from assembly as keys and respective ContigPileups objects as values
  # @!attribute [r] hmes_frags
  #   @return [Hash] a hash of contigs with selected hme score, a subset of assembly hash
  # @!attribute [r] bfr_frags
  #   @return [Hash] a hash of contigs with selected bfr score, a subset of assembly hash
  # @!attribute [r] pileups_analyzed
  #   @return [Boolean] a Boolean option to check if pileups for the assembly are analyzed or not
  class Variants

    include Enumerable
    extend Forwardable
    def_delegators :@assembly, :each, :each_key, :each_value, :size, :length, :[]
    attr_reader :assembly, :pileups, :pileups_analyzed

    # creates a Variants object using user input files
    # @param options [OpenStruct] a hash of required input files as keys and file paths as values
    def initialize(options)
      @params = options
      @assembly = {}
      @pileups = {}
      Bio::FastaFormat.open(@params.assembly).each do |entry|
        if entry.seq.length == 0
          logger.error "No sequence found for entry #{entry.entry_id}"
          raise VariantsError
        end
        contig = Contig.new(entry)
        if @assembly.key?(contig.id)
          logger.error "fasta id already found in the file for #{contig.id}"
          logger.error 'make sure there are no duplicate entries in the fasta file'
          raise VariantsError
        end
        @assembly[contig.id] = contig
        @pileups[contig.id] = ContigPileups.new(contig.id)
      end
      @pileups_analyzed = false
      unless @params.repeats_file == ''
        store_repeat_regions
      end
    end

    # reads repeat masker output file and stores masked regions to ignore variants in thos regions
    def store_repeat_regions
      File.foreach(@params.repeats_file) do |line|
        line.strip!
        next if line =~ /^SW/ or line =~ /^score/ or line == ''
        info = line.split("\s")
        pileups_obj = @pileups[info[4]]
        index = pileups_obj.masked_regions.length
        pileups_obj.masked_regions[index + 1][:begin] = info[5].to_i
        pileups_obj.masked_regions[index + 1][:end] = info[6].to_i
      end
    end

    # Reads and store pileup data for each of input bulk and parents pileup files
    # And sets pileups_analyzed to true that pileups files are processed
    def analyse_pileups
      if @params.input_format == 'bam'
        @vcf_hash = Vcf.filtering(@params.mut_bulk_vcf, @params.bg_bulk_vcf)
      end
      %i{mut_bulk bg_bulk mut_parent bg_parent}.each do | input |
        infile = @params[input]
        if infile != ''
          logger.info "processing #{input} file"
          if @params.input_format == 'pileup'
            extract_pileup(infile, input)
          elsif @params.input_format == 'vcf'
            extract_vcfs(infile, input)
          else
            extract_bam_pileup(infile, input)
          end
        end
      end

      @pileups_analyzed = true
    end

    # Input vcf file is read and positions are selected that pass the thresholds
    # @param vcffile [String] path to the pileup file to read
    # @param sym [Symbol] Symbol of the pileup file used to write selected variants
    # pileup information to respective ContigPileups object
    def extract_vcfs(vcffile, sym)
      # read vcf file and process each variant
      File.foreach(vcffile) do |line|
        next if line =~ /^#/
        v = Bio::DB::Vcf.new(line)
        unless v.alt == '.'
          pileup_string = Vcf.to_pileup(v)
          pileup = Pileup.new(pileup_string)
          store_pileup_info(pileup, sym)
        end
      end
    end

    # Input pileup file is read and positions are selected that pass the thresholds
    # @param pileupfile [String] path to the pileup file to read
    # @param sym [Symbol] Symbol of the pileup file used to write selected variants
    # pileup information to respective ContigPileups object
    def extract_pileup(pileupfile, sym)
      # read mpileup file and process each variant
      File.foreach(pileupfile) do |line|
        pileup = Pileup.new(line)
        if pileup.is_var
          store_pileup_info(pileup, sym)
        end
      end
    end

    # Input bamfile is read and selected positions pileups are stored
    # @param bamfile [String] path to the bam file to read
    # @param sym [Symbol] Symbol of the bam file used to write selected variants
    # pileup information to respective ContigPileups object
    def extract_bam_pileup(bamfile, sym)
      bq = Options.base_quality
      mq = Options.mapping_quality
      bamobject = Bio::DB::Sam.new(:bam=>bamfile, :fasta=>@params.assembly)
      bamobject.index unless bamobject.indexed?

      # or calculate from bamfile
      set_max_depth(bamobject, bamfile) if Options.max_d_multiple > 0 and sym == :mut_bulk
      # check if user has set max depth or set to zero to ignore
      max_d = Options.maxdepth
      logger.info "max depth used for #{sym} file\t#{max_d}"

      @vcf_hash.each_key do | id |
        positions = @vcf_hash[id][:het].keys
        positions << @vcf_hash[id][:hom].keys
        positions.flatten!
        next if positions.empty?
        positions.each do | pos |
          command = "#{bamobject.samtools} mpileup -r #{id}:#{pos}-#{pos} -Q #{bq} -q #{mq} -B -f #{@params.assembly} #{bamfile}"
          stdout = capture_command(command)
          if stdout == '' or stdout.split("\t")[3].to_i == 0 or stdout =~ /^\t0/
            logger.info "pileup data empty for\t#{id}\t#{pos}"
          else
            pileup = Pileup.new(stdout)
            store_pileup_info(pileup, sym)
          end
        end
      end
    end

    # Bam object is read and each contig mean and std deviation of depth calculated
    # @param bamobject [Bio::DB::Sam]
    # Open3 capture returns string output, so careful not to give whole genome or big contigs for depth analysis
    def set_max_depth(bamobject, bamfile)
      logger.info "processing #{bamfile} file for depth"
      all_depths = []
      bq = Options.base_quality
      mq = Options.mapping_quality
      @assembly.each_key do | id |
        contig_obj = @assembly[id]
        len = contig_obj.length
        command = "#{bamobject.samtools} depth -r #{id} -Q #{bq} -q #{mq} #{bamfile}"
        data = capture_command(command)
        if data == ''
          logger.info "depth data empty for\t#{id}"
          next
        end
        depths = []
        data.split("\n").each do |line|
          info = line.split("\t")
          depths << info[2].to_i
        end
        variance = 0
        mean_depth = depths.reduce(0, :+) / len.to_f
        depths.each do |value|
          variance += (value.to_f - mean_depth)**2
        end
        all_depths << mean_depth
        contig_obj.sd_depth = Math.sqrt(variance)
        contig_obj.mean_depth = mean_depth
      end
      # setting max depth as 3 times the average depth
      mean_coverage = all_depths.reduce(0, :+) / @assembly.length.to_f
      Options.maxdepth = Options.max_d_multiple * mean_coverage
    end

    def capture_command(command)
      stdout, stderr, status = Open3.capture3(command)
      unless status.success?
        logger.error "resulted in exit code #{status.exitstatus} using #{command}"
        logger.error "stderr output is: #{stderr}"
        raise CheripicError
      end
      stdout.chomp!
    end

    # stores pileup information provided to respective contig_pileup object using sym input
    # @param pileup [Pileup] Pileup objects
    # @param sym [Symbol] Symbol of the input file used to write selected variants
    # pileup information stored to respective ContigPileups object
    def store_pileup_info(pileup, sym)
      unless Options.maxdepth == 0 or pileup.coverage <= Options.maxdepth
        logger.info "pileup coverage is higher than max\t#{pileup.ref_name}\t#{pileup.pos}\t#{pileup.coverage}"
        return nil
      end
      contig_obj = @pileups[pileup.ref_name]
      contig_obj.send(sym).store(pileup.pos, pileup)

    end

    # Once pileup files are analysed and variants are extracted from each bulk;
    # bulks are compared to identify and isolate variants for downstream analysis.
    # If polyploidy set to trye and mut_parent and bg_parent bulks are provided
    # hemisnps in parents are extracted for bulk frequency ratio analysis
    def compare_pileups
      unless @pileups_analyzed
        self.analyse_pileups
      end
      @assembly.each_key do | id |
        contig = @assembly[id]
        # extract parental hemi snps for polyploids before bulks are compared
        if Options.polyploidy
          if @params.mut_parent != '' or @params.bg_parent != ''
            @pileups[id].hemisnps_in_parent
          end
        end
        contig.hm_pos, contig.ht_pos, contig.hemi_pos = @pileups[id].bulks_compared
      end
    end

    # From Assembly contig objects, contigs are selected based on user selected options
    # for homozygosity enrichment score (hme_score)
    def hmes_frags
      # calculate every time method gets called
      @hmes_frags = select_contigs(:hme_score)
    end

    # From Assembly contig objects, contigs are selected based on user selected options
    # for bulk frequency ratio (bfr_score)
    def bfr_frags
      unless defined?(@bfr_frags)
        @bfr_frags = select_contigs(:bfr_score)
      end
      @bfr_frags
    end

    # Applies selection procedure on assembly contigs based on the ratio_type provided.
    # If use_all_contigs is set to false then contigs without any variant are discarded for :hme_score
    # while contigs without any hemisnps are discarded for :bfr_score
    # If include_low_hmes is set to false then contigs are further filtered based on a cut off value of the score
    # @param ratio_type [Symbol] ratio_type is either :hme_score or :bfr_score
    def select_contigs(ratio_type)
      selected_contigs ={}
      use_all_contigs = Options.use_all_contigs
      @assembly.each_key do | frag |
        if use_all_contigs
          selected_contigs[frag] = @assembly[frag]
        else
          if ratio_type == :hme_score
            # selecting fragments which have a variant
            if @assembly[frag].hm_num + @assembly[frag].ht_num > 2 * Options.hmes_adjust
              selected_contigs[frag] = @assembly[frag]
            end
          else # ratio_type == :bfr_score
            # in polyploidy scenario selecting fragments with at least one bfr position
            if @assembly[frag].hemi_num > 0
              selected_contigs[frag] = @assembly[frag]
            end
          end
        end
      end
      selected_contigs = filter_contigs(selected_contigs, ratio_type)
      if use_all_contigs
        logger.info "No filtering was applied to fragments\n"
      else
        logger.info "Selected #{selected_contigs.length} out of #{@assembly.length} fragments with #{ratio_type} score\n"
      end
      selected_contigs
    end

    # Filters out contigs below a cutoff for selected ratio_type
    # a cutoff value is calculated based on ratio_type provided
    # @param ratio_type [Symbol] ratio_type is either :hme_score or :bfr_score
    # @param selected_contigs [Hash] a hash of contigs with selected ratio_type, a subset of assembly hash
    def filter_contigs(selected_contigs, ratio_type)
      cutoff = get_cutoff(selected_contigs, ratio_type)
      selected_contigs.each_key do | frag |
        if selected_contigs[frag].send(ratio_type) < cutoff
          selected_contigs.delete(frag)
        end
      end
      selected_contigs
    end

    # Cut off value calculation used to filter out low scored contigs.
    #
    # @param ratio_type [Symbol] ratio_type is either :hme_score or :bfr_score
    # @param selected_contigs [Hash] a hash of contigs with selected ratio_type, a subset of assembly hash
    def get_cutoff(selected_contigs, ratio_type)
      include_low_hmes = Options.include_low_hmes
      # set minimum cut off hme_score or bfr_score to pick fragments with variants
      # calculate min hme score for back or out crossed data or bfr_score for polypoidy data
      # if no filtering applied set cutoff to 1.1
      if include_low_hmes
        cutoff = 0.0
      else
        if ratio_type == :hme_score
          adjust = Options.hmes_adjust
          if Options.cross_type == 'back'
            cutoff = (1.0/adjust) + 1.0
          else # outcross
            cutoff = (2.0/adjust) + 1.0
          end
        else # ratio_type is bfr_score
          cutoff = bfr_cutoff(selected_contigs)
        end
      end
      cutoff
    end

    # Cut off value calculation for bfr contigs.
    # ratio value at index 0.1% length of an array or at index zero of an array that contains decreasing order of bfr ratios
    # @param selected_contigs [Hash] a hash of contigs with selected bfr score, a subset of assembly hash
    def bfr_cutoff(selected_contigs, prop=0.1)
      ratios = []
      selected_contigs.each_key do | frag |
        ratios << selected_contigs[frag].bfr_score
      end
      ratios.sort!.reverse!
      index = (ratios.length * prop)/100
      # set a minmum index to get at least one contig
      if index < 1
        index = 1
      end
      ratios[index - 1]
    end

    # Method is to discard homozygous variant positions for which background bulk
    # pileup shows a fraction value higher than 0.35 for variant allele/non-reference allele
    # a recessive variant is expected to have 1/3rd frequency in background bulk
    def verify_bg_bulk_pileup
      unless defined?(@hmes_frags)
        self.hmes_frags
      end
      @hmes_frags.each_key do | frag |
        positions = @assembly[frag].hm_pos.keys
        contig_pileup_obj = @pileups[frag]
        positions.each do | pos |
          if contig_pileup_obj.mut_bulk.key?(pos)
            mut_pileup = contig_pileup_obj.mut_bulk[pos]
            if mut_pileup.is_var
              if contig_pileup_obj.bg_bulk.key?(pos)
                bg_pileup = contig_pileup_obj.bg_bulk[pos]
                if bg_pileup.non_ref_ratio > 0.35
                  @assembly[frag].hm_pos.delete(pos)
                end
              end
            else
              # this should not happen, may be catch as as an error
              @assembly[frag].hm_pos.delete(pos)
            end
          else
            # this should not happen, may be catch as as an error
            @assembly[frag].hm_pos.delete(pos)
          end
        end
      end
      # recalculate hmes_frags once pileups are verified
      self.hmes_frags
    end

  end # Variants

end # Cheripic
