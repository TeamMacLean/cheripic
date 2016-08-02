# encoding: utf-8

module Cheripic

  # Custom error handling for Bfr class
  class BfrError < CheripicError; end

  # A class to calculate bulk frequency ratio (bfr) using one or two hashes of base fractions resulted from pileup
  #
  # @!attribute [rw] bfr_adj
  #   @return [Float] a float value to adjust the bfr calculation
  class Bfr

    attr_accessor :bfr_adj

    # A method to get bulk frequency ratio (bfr) for selected hemi snps.
    #   This is done by selecting which hash (mutant or background) to use for bfr calculation
    #   either calculates fraction or bfr
    #   and ignores positions with complex variants.
    # @param mut_hash [Hash] a hash of base fractions from pileup of mutant bulk
    # @param bg_hash [Hash] a hash of base fractions from pileup of background bulk
    # @return [Float] a ratio calculated
    def self.get_bfr(mut_hash, bg_hash='')
      @bfr_adj = Options.bfr_adjust
      if bg_hash != ''
        # checking if only two vars in base hash and that includes ref
        # checking if only one var in hemi snp
        # suggests enrichment for one of two alleles
        if mut_hash.length == 2 and mut_hash.key?(:ref)
          bfr = calculate_bfr(mut_hash, bg_hash)
        elsif bg_hash.length == 2  and bg_hash.key?(:ref)
          bfr = calculate_bfr(bg_hash, mut_hash)
        elsif mut_hash.length == 1 and mut_hash[:ref] == nil
          bfr = calculate_bfr(mut_hash, bg_hash)
        elsif bg_hash.length == 1 and bg_hash[:ref] == nil
          bfr = calculate_bfr(bg_hash, mut_hash)
        else # complex
          bfr = ''
        end
      elsif mut_hash.length == 2 and mut_hash.key?(:ref)
        bfr = calc_fraction(mut_hash)[0]/ @bfr_adj
      elsif mut_hash.length == 1 and mut_hash[:ref] == nil
        bfr = calc_fraction(mut_hash)[0]/ @bfr_adj
      else
        bfr = ''
      end
      bfr
    end

    # A method to calculate bfr using a base fraction hash with hemi-snp
    # @param two_key_hash [Hash] a hash of base fractions from pileup with 2 keys (a ref and variant base)
    # @param other_hash [Hash] a hash of base fractions from pileup
    # @return [Float] a ratio calculated
    def self.calculate_bfr(two_key_hash, other_hash)
      # if :ref is absent such as below noise depth, then set to zero
      unless two_key_hash.key?(:ref)
        two_key_hash[:ref] = 0
      end
      unless other_hash.key?(:ref)
        other_hash[:ref] = 0
      end
      frac_1, base = calc_fraction(two_key_hash)
      if other_hash.key?(base)
        sum = other_hash[base] + other_hash[:ref] + @bfr_adj
        frac_2 = (other_hash[base] + @bfr_adj)/sum
      else
        sum = other_hash[:ref] + @bfr_adj
        frac_2 = @bfr_adj/sum
      end
      # making sure ratio is always 1 or grater
      if frac_1 > frac_2
        bfr = frac_1/frac_2
      else
        bfr = frac_2/frac_1
      end
      bfr
    end

    # A method to calculate ratio using a base fraction hash
    # @param hash [Hash] a hash of base fractions from pileup with 2 or 1 keys
    # @return [Array<Float><String>] an array of ratio calculated and base character
    def self.calc_fraction(hash)
      unless hash.key?(:ref)
        hash[:ref] = 0
      end
      array = hash.keys
      sum = hash[array[0]] + hash[array[1]] + @bfr_adj
      if array[0] == :ref
        frac = (hash[array[1]] + @bfr_adj)/sum
        base = array[1]
      else
        frac = (hash[array[0]] + @bfr_adj)/sum
        base = array[0]
      end
      [frac, base]
    end

  end

end
