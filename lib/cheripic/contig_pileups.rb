# encoding: utf-8
require 'bio'
require 'forwardable'

module Cheripic

  class ContigPileupsError < CheripicError; end

  class ContigPileups

    include Enumerable
    extend Forwardable
    def_delegators :@mut_bulk, :each, :each_key, :each_value, :length, :[], :store
    def_delegators :@bg_bulk, :each, :each_key, :each_value, :length, :[], :store
    def_delegators :@mut_parent, :each, :each_key, :each_value, :length, :[], :store
    def_delegators :@bg_parent, :each, :each_key, :each_value, :length, :[], :store
    attr_accessor :id, :parent_hemi
    attr_accessor :mut_bulk, :bg_bulk, :mut_parent, :bg_parent

    def initialize (fasta)
      @id = fasta
      @mut_bulk = {}
      @bg_bulk = {}
      @mut_parent = {}
      @bg_parent = {}
      @parent_hemi = {}
    end

    def bulks_compared
      @hm_pos = []
      @ht_pos = []
      @hemi_pos = {}
      @mut_bulk.each_key do | pos |
        if Options.params.polyploidy
          if @parent_hemi.key?(pos)
            bg_bases = ''
            if @bg_bulk.key?(pos)
              bg_bases = @bg_bulk[pos].var_base_frac
            end
            mut_bases = @mut_bulk[pos].var_base_frac
            bfr = Bfr.get_bfr(mut_bases, :bg_hash => bg_bases)
            @hemi_pos[pos] = bfr
          else
            compare_pileup(pos)
          end
        else
          self.compare_pileup(pos)
        end
      end
      [@hm_pos, @ht_pos, @hemi_pos]
    end

    # we are only dealing with single element hashes
    # so discard hashes with more than one element and empty hashes
    # empty hash results from position below selected coverage or bases freq below noise
    def compare_pileup(pos)
      base_hash = @mut_bulk[pos].var_base_frac
      base_hash.delete(:ref)
      return nil if base_hash.empty?
      # we could ignore complex loci or
      # take the variant type based on predominant base
      if base_hash.length > 1
        mut_type = var_mode(base_hash.values.max)
        if @bg_bulk.key?(pos)
          bg_type = bg_bulk_var(pos)
          return nil if mut_type == :hom and bg_type == :hom
        end
        categorise_pos(mut_type, pos)
      else
        base = base_hash.keys[0]
        mut_type = var_mode(base_hash[base])
        if @bg_bulk.key?(pos)
          bg_type = bg_bulk_var(pos)
          return nil if mut_type == :hom and bg_type == :hom
          categorise_pos(mut_type, pos)
        else
          categorise_pos(mut_type, pos)
        end
      end
    end

    def bg_bulk_var(pos)
      bg_base_hash = @bg_bulk[pos].var_base_frac
      if bg_base_hash.length > 1
        var_mode(bg_base_hash.values.max)
      else
        var_mode(bg_base_hash[0])
      end
    end

    def categorise_pos(var_type, pos)
      if var_type == :hom
        @hm_pos << pos
      elsif var_type == :het
        @ht_pos << pos
      end
    end

    # calculate var zygosity for non-polyploid variants
    # increased range is used for heterozygosity for RNA-seq data
    def var_mode(ratio)
      ht_low = Options.params.htlow
      ht_high = Options.params.hthigh
      mode = ''
      if ratio.between?(ht_low, ht_high)
        mode = :het
      elsif ratio > ht_high
        mode = :hom
      end
      mode
    end

    def hemisnps_in_parent
      # mark all the hemi snp based on both parents
      self.mut_parent.each_key do |pos|
        mut_parent_frac = @mut_parent[pos].var_base_frac
        if self.bg_parent.key?(pos)
          bg_parent_frac = @bg_parent[pos].var_base_frac
          if mut_parent_frac.length == 2 and mut_parent_frac.key?(:ref)
            bfr = Bfr.get_bfr(mut_parent_frac, :bg_hash => bg_parent_frac)
            @parent_hemi[pos] = bfr
          elsif bg_parent_frac.length == 2 and bg_parent_frac.key?(:ref)
            bfr = Bfr.get_bfr(mut_parent_frac, :bg_hash => bg_parent_frac)
            @parent_hemi[pos] = bfr
          end
          self.bg_parent.delete(pos)
        else
          if mut_parent_frac.length == 2 and mut_parent_frac.key?(:ref)
            bfr = Bfr.get_bfr(mut_parent_frac)
            @parent_hemi[pos] = bfr
          end
        end
      end

      # now include all hemi snp unique background parent
      self.bg_parent.each_key do |pos|
        unless @parent_hemi.key?(pos)
          bg_parent_frac = @bg_parent[pos].var_base_frac
          if bg_parent_frac.length == 2 and bg_parent_frac.key?(:ref)
            bfr = Bfr.get_bfr(bg_parent_frac)
            @parent_hemi[pos] = bfr
          end
        end
      end
    end

  end

end
