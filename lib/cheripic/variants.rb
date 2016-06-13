# encoding: utf-8
require 'bio'
require 'forwardable'

module Cheripic

  class VariantsError < CheripicError; end

  class Variants

    include Enumerable
    extend Forwardable
    def_delegators :@assembly, :each, :each_key, :each_value, :size, :length, :[]

    attr_accessor :assembly, :mut_bulk, :bg_bulk, :mut_parent, :bg_parent
    attr_reader :has_run, :pileups

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
    def analyse
      set_defaults
      @bg_bulk ||= @params.bg_bulk
      @mut_parent ||= @params.mut_parent
      @bg_parent ||= @params.bg_parent

      %i{mut_bulk bg_bulk mut_parent bg_parent}.each do | input |
        infile = @params[input]
        if infile != ''
          extract_pileup(infile, input)
        end
      end

      @has_run = true
    end

    def set_defaults
      @bg_bulk = ''
      @mut_parent = ''
      @bg_parent = ''
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
        self.analyse
      end
      @assembly.each_key do | id |
        contig = @assembly[id]
        contig.hm_pos, contig.ht_pos, contig.hemi_pos = @pileups[id].bulks_compared
      end
    end

  end # Variants

end # Cheripic
