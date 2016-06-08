# encoding: utf-8
require 'bio'
require 'forwardable'

module Cheripic

  class ContigError < CheripicError; end

  class ContigPileups

    include Enumerable
    extend Forwardable
    def_delegators :@mut_bulk, :each, :each_key, :each_value, :length, :[], :store
    def_delegators :@bg_bulk, :each, :each_key, :each_value, :length, :[], :store
    def_delegators :@mut_parent, :each, :each_key, :each_value, :length, :[], :store
    def_delegators :@bg_parent, :each, :each_key, :each_value, :length, :[], :store
    attr_accessor :contig, :pos, :polyploidy
    attr_accessor :mut_bulk, :bg_bulk, :mut_parent, :bg_parent

    def initialize (fasta)
      @contig = fasta
      @pos = {}
      @mut_bulk = {}
      @bg_bulk = {}
      @mut_parent = {}
      @bg_parent = {}
      @polyploidy = Options.params.polyploidy
    end

  end

end
