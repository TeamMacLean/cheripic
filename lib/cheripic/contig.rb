# encoding: utf-8
require 'bio'
require 'forwardable'

module Cheripic

  class ContigError < CheripicError; end

  class Contig

    include Enumerable
    extend Forwardable
    delegate [:size, :length] => :@contig
    def_delegator :@contig, :entry_id, :id
    attr_accessor :contig
    attr_accessor :mut_hm, :bg_hm, :mut_ht, :bg_ht
    attr_accessor :mut_hemi, :bg_hemi, :polyploidy

    def initialize (fasta, polyploidy=false)
      @contig = fasta
      @contig.data = nil
      @mut_hm = []
      @bg_hm = []
      @mut_ht =[]
      @bg_ht = []
      @mut_hemi = {}
      @bg_hemi = {}
      @polyploidy=polyploidy
    end

    def hm_pos
      if @bg_hm.empty?
        @mut_hm
      else
        return [] if @mut_hm.empty?
        @mut_hm.delete_if do | pos |
          pos.include?(@bg_hm)
        end
      end
    end

    def hm_num
      self.hm_pos.length
    end

    def ht_pos
      if @bg_hm.empty?
        @mut_hm
      else
        return [] if @mut_hm.empty?
        @mut_hm.delete_if do | pos |
          pos.include?(@bg_hm)
        end
      end
    end

    def ht_num
      self.ht_pos.length
    end

    def hme_score(hmes_adjust=0.5)
      if self.hm_num == 0 and self.ht_num == 0
        0.0
      else
        (self.hm_num + hmes_adjust) / (self.ht_num + hmes_adjust)
      end
    end

    def bfrs
      Bfr.new(self.mut_hemi, self.bg_hemi)
    end

    def bfr_score(bfr_adjust=0.05)
      if self.bfrs.values.empty?
        bfr_adjust
      else
        geom_mean(self.bfrs.values)
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
