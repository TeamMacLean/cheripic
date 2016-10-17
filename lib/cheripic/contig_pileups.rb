# encoding: utf-8
require 'bio'
require 'forwardable'

module Cheripic

  # Custom error handling for ContigPileup class
  class ContigPileupsError < CheripicError; end

  # A ContigPileup object for each contig from assembly that stores
  # pileup file information and variants are selected from analysis of pileup files
  # selected variants from pileup files is stored as hashes
  #
  # @!attribute [rw] id
  #   @return [String] id of the contig in assembly taken from fasta file
  # @!attribute [rw] mut_bulk
  #   @return [Hash] a hash of variant positions from mut_bulk as keys and pileup info as values
  # @!attribute [rw] bg_bulk
  #   @return [Hash] a hash of variant positions from bg_bulk as keys and pileup info as values
  # @!attribute [rw] mut_parent
  #   @return [Hash] a hash of variant positions from mut_parent as keys and pileup info as values
  # @!attribute [rw] bg_parent
  #   @return [Hash] a hash of variant positions from bg_parent as keys and pileup info as values
  # @!attribute [rw] parent_hemi
  #   @return [Hash] a hash of hemi-variant positions as keys and bfr calculated from parent bulks as values
  class ContigPileups

    include Enumerable
    extend Forwardable
    def_delegators :@mut_bulk, :each, :each_key, :each_value, :length, :[], :store
    def_delegators :@bg_bulk, :each, :each_key, :each_value, :length, :[], :store
    def_delegators :@mut_parent, :each, :each_key, :each_value, :length, :[], :store
    def_delegators :@bg_parent, :each, :each_key, :each_value, :length, :[], :store
    attr_accessor :id, :parent_hemi
    attr_accessor :mut_bulk, :bg_bulk, :mut_parent, :bg_parent, :masked_regions

    # creates a ContigPileup object using fasta entry id
    # @param fasta [String] a contig id from fasta entry
    def initialize (fasta)
      @id = fasta
      @mut_bulk = {}
      @bg_bulk = {}
      @mut_parent = {}
      @bg_parent = {}
      @parent_hemi = {}
      @masked_regions = Hash.new { |h,k| h[k] = {} }
      @hm_pos = {}
      @ht_pos = {}
      @hemi_pos = {}
    end

    # bulk pileups are compared and variant positions are selected
    # @return [Array<Hash>] variant positions are stored in hashes
    # for homozygous, heterozygous and hemi-variant positions
    def bulks_compared
      @mut_bulk.each_key do | pos |
        ignore = 0
        unless @masked_regions.empty?
          @masked_regions.each_key do | index |
            if pos.between?(@masked_regions[index][:begin], @masked_regions[index][:end])
              ignore = 1
              logger.info "variant is in the masked region\t#{@mut_bulk[pos].to_s}"
            end
          end
        end
        next if ignore == 1
        if Options.polyploidy and @parent_hemi.key?(pos)
          bg_bases = ''
          if @bg_bulk.key?(pos)
            bg_bases = @bg_bulk[pos].var_base_frac
          end
          mut_bases = @mut_bulk[pos].var_base_frac
          bfr = Bfr.get_bfr(mut_bases, bg_bases)
          @hemi_pos[pos] = bfr
        else
          self.compare_pileup(pos)
        end
      end
      [@hm_pos, @ht_pos, @hemi_pos]
    end

    # mut_bulk and bg_bulk pileups are compared at selected position of the contig.
    # Empty hash results from position below selected coverage
    # or bases freq below noise and such positions are deleted.
    # @param pos [Integer] position in the contig
    # stores variant type, position and allele fraction to either @hm_pos or @ht_pos hashes
    def compare_pileup(pos)
      mut_type, fraction = var_mode_fraction(@mut_bulk[pos])
      return nil if mut_type.nil?
      if @bg_bulk.key?(pos)
        bg_type = var_mode_fraction(@bg_bulk[pos])[0]
        mut_type = compare_var_type(mut_type, bg_type)
      end
      unless mut_type.nil?
        categorise_pos(mut_type, pos, fraction)
      end
    end


    # Method to extract var_mode and allele fraction from pileup information at a position in contig
    #
    # @param pileup_info [Pileup] pileup object
    # @return [Symbol] variant mode from pileup position (:hom or :het) at the position
    # @return [Float] allele fraction at the position
    def var_mode_fraction(pileup_info)
      base_frac_hash = pileup_info.var_base_frac
      base_frac_hash.delete(:ref)
      return [nil, nil] if base_frac_hash.empty?
      # we could ignore complex loci or
      # take the variant type based on predominant base
      if base_frac_hash.length > 1
        fraction = base_frac_hash.values.max
      else
        fraction = base_frac_hash[base_frac_hash.keys[0]]
      end
      [var_mode(fraction), fraction]
    end

    # Categorizes variant zygosity based on the allele fraction provided.
    # Uses lower and upper limit set for heterozygosity in the options.
    # @note consider increasing the range of heterozygosity limits for RNA-seq data
    # @param fraction [Float] allele fraction
    # @return [Symbol] of either :het or :hom to represent heterozygous or homozygous respectively
    def var_mode(fraction)
      ht_low = Options.htlow
      ht_high = Options.hthigh
      mode = ''
      if fraction.between?(ht_low, ht_high)
        mode = :het
      elsif fraction > ht_high
        mode = :hom
      end
      mode
    end

    # Simple comparison of variant type of mut and bg bulks at a position
    # If both bulks have homozygous variant at selected position then it is ignored
    # @param muttype [Symbol] values are either :hom or :het
    # @param bgtype [Symbol] values are either :hom or :het
    # @return [Symbol] variant mode of the mut bulk (:hom or :het) at the position or nil
    def compare_var_type(muttype, bgtype)
      if muttype == :hom and bgtype == :hom
        nil
      else
        muttype
      end
    end

    # method stores pos as key and allele fraction as value
    # to @hm_pos or @ht_pos hash based on variant type
    # @param var_type [Symbol]  values are either :hom or :het
    # @param pos [Integer] position in the contig
    # @param ratio [Float] allele fraction
    def categorise_pos(var_type, pos, ratio)
      if var_type == :hom
        @hm_pos[pos] = ratio
      elsif var_type == :het
        @ht_pos[pos] = ratio
      end
    end

    # Compares parental pileups for the contig and identify position
    # that indicate variants from homeologues called hemi-snps
    # and calculates bulk frequency ratio (bfr)
    # @return [Hash] parent_hemi hash with position as key and bfr as value
    def hemisnps_in_parent
      # mark all the hemi snp based on both parents
      @mut_parent.each_key do |pos|
        mut_parent_frac = @mut_parent[pos].var_base_frac
        if @bg_parent.key?(pos)
          bg_parent_frac = @bg_parent[pos].var_base_frac
          bfr = Bfr.get_bfr(mut_parent_frac, bg_parent_frac)
          @parent_hemi[pos] = bfr
          @bg_parent.delete(pos)
        else
          bfr = Bfr.get_bfr(mut_parent_frac)
          @parent_hemi[pos] = bfr
        end
      end

      # now include all hemi snp unique to background parent
      @bg_parent.each_key do |pos|
        unless @parent_hemi.key?(pos)
          bg_parent_frac = @bg_parent[pos].var_base_frac
          bfr = Bfr.get_bfr(bg_parent_frac)
          @parent_hemi[pos] = bfr
        end
      end
    end

  end

end
