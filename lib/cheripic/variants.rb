# encoding: utf-8
require 'bio'
require 'forwardable'

module Cheripic

  # Custom error handling for Variants class
  class VariantsError < CheripicError; end

  class Variants

    include Enumerable
    extend Forwardable
    def_delegators :@assembly, :each, :each_key, :each_value, :size, :length, :[]
    attr_accessor :assembly, :has_run, :pileups, :hmes_frags, :bfr_frags

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
    end

    # Read and store pileup data for each bulk and parents
    #
    def analyse_pileups
      @bg_bulk = @params.bg_bulk
      @mut_parent = @params.mut_parent
      @bg_parent = @params.bg_parent

      %i{mut_bulk bg_bulk mut_parent bg_parent}.each do | input |
        infile = @params[input]
        if infile != ''
          extract_pileup(infile, input)
        end
      end

      @has_run = true
    end

    def extract_pileup(pileupfile, sym)
      # read mpileup file and process each variant
      File.foreach(pileupfile) do |line|
        pileup = Pileup.new(line)
        if pileup.is_var
          contig_obj = @pileups[pileup.ref_name]
          contig_obj.send(sym).store(pileup.pos, pileup)
        end
      end
    end

    def compare_pileups
      unless defined?(@has_run)
        self.analyse_pileups
      end
      @assembly.each_key do | id |
        contig = @assembly[id]
        # extract parental hemi snps for polyploids before bulks are compared
        if @mut_parent != '' or @bg_parent != ''
          @pileups[id].hemisnps_in_parent
        end
        contig.hm_pos, contig.ht_pos, contig.hemi_pos = @pileups[id].bulks_compared
      end
    end

    def hmes_frags
      # calculate every time method gets called
      @hmes_frags = select_contigs(:hme_score)
    end

    def bfr_frags
      unless defined?(@bfr_frags)
        @bfr_frags = select_contigs(:bfr_score)
      end
      @bfr_frags
    end

    def select_contigs(ratio_type)
      selected_contigs ={}
      only_frag_with_vars = Options.only_frag_with_vars
      @assembly.each_key do | frag |
        if only_frag_with_vars
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
        else
          selected_contigs[frag] = @assembly[frag]
        end
      end
      selected_contigs = filter_contigs(selected_contigs, ratio_type)
      if only_frag_with_vars
        logger.info "Selected #{selected_contigs.length} out of #{@assembly.length} fragments with #{ratio_type} score\n"
      else
        logger.info "No filtering was applied to fragments\n"
      end
      selected_contigs
    end

    def filter_contigs(selected_contigs, ratio_type)
      cutoff = get_cutoff(selected_contigs, ratio_type)
      selected_contigs.each_key do | frag |
        if selected_contigs[frag].send(ratio_type) < cutoff
          selected_contigs.delete(frag)
        end
      end
      selected_contigs
    end

    def get_cutoff(selected_contigs, ratio_type)
      filter_out_low_hmes = Options.filter_out_low_hmes
      # set minimum cut off hme_score or bfr_score to pick fragments with variants
      # calculate min hme score for back or out crossed data or bfr_score for polypoidy data
      # if no filtering applied set cutoff to 1.1
      if filter_out_low_hmes
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
      else
        cutoff = 0.0
      end
      cutoff
    end

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

    # method is to discard homozygous variant positions for which background bulk
    # pileup shows proportion higher than 0.35 for variant allele/non-reference allele
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
