# encoding: utf-8
require 'bio'
require 'forwardable'

module Cheripic

  class ContigError < CheripicError; end

  # A contig object from assembly that stores positions of
  # homozygous, heterozygous and hemi-variants
  #
  # @!attribute [rw] hm_pos
  #   @return [Hash] a hash of homozygous variant positions as keys and allele frequency as values
  # @!attribute [rw] ht_pos
  #   @return [Hash] a hash of heterozygous variant positions as keys and allele frequency as values
  # @!attribute [rw] hemi_pos
  #   @return [Hash] a hash of hemi-variant positions as keys and allele frequency as values
  # @!attribute [r] id
  #   @return [String] id of the contig in assembly taken from fasta file
  # @!attribute [r] length
  #   @return [Integer] length of contig in bases
  class Contig

    attr_accessor :hm_pos, :ht_pos, :hemi_pos
    attr_reader :id, :length

    # creates a Contig object using fasta entry
    #
    # @param fasta [Bio::FastaFormat] an individual fasta entry from input assembly file
    def initialize (fasta)
      @id = fasta.entry_id
      @length = fasta.length
      @hm_pos = {}
      @ht_pos = {}
      @hemi_pos = {}
    end

    # Number of homozygous variants identified in the contig
    # @return [Integer]
    def hm_num
      self.hm_pos.length
    end

    # Number of heterozygous variants identified in the contig
    # @return [Integer]
    def ht_num
      self.ht_pos.length
    end

    # Homozygosity enrichment score calculated using
    # hm_num and ht_num of the contig object
    # @return [Float]
    def hme_score
      hmes_adjust = Options.hmes_adjust
      if self.hm_num == 0 and self.ht_num == 0
        0.0
      else
        (self.hm_num + hmes_adjust) / (self.ht_num + hmes_adjust)
      end
    end

    # Number of hemi-variants identified in the contig
    # @return [Integer]
    def hemi_num
      self.hemi_pos.length
    end

    # Mean of bulk frequency ratios (bfr) calculated using
    # bfr values all hemi_pos of the contig
    # @return [Float]
    def bfr_score
      if self.hemi_pos.values.empty?
        0.0
      else
        geom_mean(self.hemi_pos.values)
      end
    end

    # Calculates mean of an array of numbers
    # @param array [Array] an array of bfr values from hemi_snp
    # @returns [Float] mean value as float
    def geom_mean(array)
      return array[0].to_f if array.length == 1
      array.reduce(:+) / array.size.to_f
      # sum = 0.0
      # array.each{ |v| sum += Math.log(v.to_f) }
      # sum /= array.size
      # Math.exp sum
    end

  end # Contig

end # Cheripic
