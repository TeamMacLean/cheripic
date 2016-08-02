#!/usr/bin/env ruby

module Cheripic

  # Custom error handling for Implementer class
  class ImplementerError < CheripicError; end

  class Implementer

    require 'ostruct'
    require 'fileutils'
    attr_accessor :options, :variants

    def initialize(inputs)
      set1 = %i{assembly
                input_format
                mut_bulk
                bg_bulk
                output
                mut_parent
                bg_parent}
      @options = OpenStruct.new(inputs.select { |k| set1.include?(k) })

      set2 = %i{hmes_adjust
                htlow
                hthigh
                mindepth
                min_non_ref_count
                min_indel_count_support
                ignore_reference_n
                mapping_quality
                base_quality
                noise
                cross_type
                only_frag_with_vars
                filter_out_low_hmes
                polyploidy
                bfr_adjust}
      settings = inputs.select { |k| set2.include?(k) }
      Options.update(settings)
      FileUtils.mkdir_p @options.output
    end

    def extract_vars
      @variants = Variants.new(@options)
      @variants.compare_pileups
    end

    def process_variants
      @variants.verify_bg_bulk_pileup
      # print selected variants that could be potential markers or mutation
      out_file = File.open("#{@options.output}/selected_variants.txt", 'w')
      out_file.puts "HME_Score\tAlleleFreq\tseq_id\tposition\tref_base\tcoverage\tbases\tbase_quals\tsequence_left\tAlt_seq\tsequence_right"
      regions = Regions.new(@options.assembly)
      @variants.hmes_frags.each_key do | frag |
        contig_obj = @variants.assembly[frag]
        positions = contig_obj.hm_pos.keys
        positions.each do | pos |
          pileup = @variants.pileups[frag].mut_bulk[pos]
          seqs = regions.fetch_seq(frag,pos)
          out_file.puts "#{contig_obj.hme_score}\t#{contig_obj.hm_pos[pos]}\t#{pileup.to_s.chomp}\t#{seqs[0]}\t#{pileup.consensus}\t#{seqs[1]}"
        end
      end
      out_file.close
    end

    def run
      unless defined?(@variants.has_run)
        self.extract_vars
      end
      if Options.polyploidy
        self.process_variants
        @variants.bfr_frags
      else
        self.process_variants
      end
    end

  end

end
