#!/usr/bin/env ruby

module Cheripic

  # Custom error handling for Implementer class
  class ImplementerError < CheripicError; end

  # An Implementer object for running pipeline from Cmd object options
  #
  # @!attribute [r] options
  #   @return [Hash] a hash of required input files names as keys and
  #   user provided file paths as values taken from Cmd object
  # @!attribute [r] variants
  #   @return [<Cheripic::Variants>] a Variants object initialized using options from Cmd object
  class Implementer

    require 'ostruct'
    require 'fileutils'
    attr_reader :options, :variants, :has_run

    # Initializes an Implementer object using inputs from cmd object
    # @param inputs [Hash] a hash of trollop option names as keys and user or default setting as values from Cmd object
    def initialize(inputs)
      set1 = %i{assembly
                input_format
                mut_bulk
                bg_bulk
                hmes_frags
                bfr_frags
                mut_parent
                bg_parent}
      @options = OpenStruct.new(inputs.select { |k| set1.include?(k) })

      set2 = %i{hmes_adjust
                htlow
                hthigh
                mindepth
                min_non_ref_count
                min_indel_count_support
                ambiguous_ref_bases
                mapping_quality
                base_quality
                noise
                cross_type
                use_all_contigs
                include_low_hmes
                polyploidy
                bfr_adjust}
      settings = inputs.select { |k| set2.include?(k) }
      Options.update(settings)
      @vars_extracted = false
      @has_run = false
    end

    # Initializes a Variants object using using input options (files).
    # Each pileup file is processed and bulks are compared
    def extract_vars
      @variants = Variants.new(@options)
      @variants.compare_pileups
      @vars_extracted = true
    end

    # Extracted variants from bulk comparison are re-analysed
    # and selected variants are written to a file
    def process_variants(pos_type)
      if pos_type == :hmes_frags
        @variants.verify_bg_bulk_pileup
      end
      # print selected variants that could be potential markers or mutation
      out_file = File.open(@options[pos_type], 'w')
      out_file.puts "Score\tAlleleFreq\tseq_id\tposition\tref_base\tcoverage\tbases\tbase_quals\tsequence_left\tAlt_seq\tsequence_right"
      regions = Regions.new(@options.assembly)
      @variants.send(pos_type).each_key do | frag |
        contig_obj = @variants.assembly[frag]
        if pos_type == :hmes_frags
          positions = contig_obj.hm_pos.keys
        else
          positions = contig_obj.hemi_pos.keys
        end
        positions.each do | pos |
          pileup = @variants.pileups[frag].mut_bulk[pos]
          seqs = regions.fetch_seq(frag,pos)
          out_file.puts "#{contig_obj.hme_score}\t#{contig_obj.hm_pos[pos]}\t#{pileup.to_s.chomp}\t#{seqs[0]}\t#{pileup.consensus}\t#{seqs[1]}"
        end
      end
      out_file.close
    end

    # Wrapper to extract and isolate selected variants
    # implements extract_vars and process_variants and
    # if data is from polyploids extracts contigs with high bfr
    def run
      unless @vars_extracted
        self.extract_vars
      end
      self.process_variants(:hmes_frags)
      if Options.polyploidy
        self.process_variants(:bfr_frags)
      end
      @has_run = true
    end

  end

end
