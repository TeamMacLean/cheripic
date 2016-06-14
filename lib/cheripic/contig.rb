# encoding: utf-8
require 'bio'
require 'forwardable'

module Cheripic

  class ContigError < CheripicError; end

  class Contig

    include Enumerable
    extend Forwardable
    # delegate [:size, :length] => :@contig
    # def_delegator :@contig, :entry_id, :id
    attr_accessor :hm_pos, :ht_pos, :hemi_pos, :id, :length

    def initialize (fasta)
      @id = fasta.entry_id
      @length = fasta.length
      @hm_pos = []
      @ht_pos = []
      @hemi_pos = {}
    end

    def hm_num
      self.hm_pos.length
    end

    def ht_num
      self.ht_pos.length
    end

    def hme_score
      hmes_adjust = Options.params.hmes_adjust
      if self.hm_num == 0 and self.ht_num == 0
        0.0
      else
        (self.hm_num + hmes_adjust) / (self.ht_num + hmes_adjust)
      end
    end

    def hemi_num
      self.hemi_pos.length
    end

    def bfr_score
      if self.hemi_pos.values.empty?
        0.0
      else
        geom_mean(self.hemi_pos.values)
      end
    end

    # geometric mean of an array of numbers
    def geom_mean(array)
      return array[0].to_f if array.length == 1
      sum = 0.0
      array.each{ |v| sum += Math.log(v.to_f) }
      sum /= array.size
      Math.exp sum
    end

  end # Contig

end # Cheripic
