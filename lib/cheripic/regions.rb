#!/usr/bin/env ruby
require 'bio-samtools'
require 'forwardable'

module Cheripic

  # Custom error handling for Regions class
  class RegionsError < CheripicError; end

  # An application of Bio::DB::Fasta object that lets to extract selected regions of the fasta entries
  #
  # @!attribute [r] reference_db
  #   @return [Bio::DB::Fasta::FastaFile] indexed fasta object
  # @!attribute [r] id_len
  #   @return [Hash] a hash of fasta entry ids as keys and sequence length as values
  class Regions

    include Enumerable
    extend Forwardable
    def_delegators :@id_len, :each, :each_key, :each_value, :length, :[]
    attr_reader :reference_db, :id_len

    # creates a Regions object using fasta
    #
    # @param assembly [String] path to a fasta file
    def initialize(assembly)
      @reference_db = Bio::DB::Fasta::FastaFile.new({:fasta=>assembly})
      @id_len = {}
      self.get_id_len
    end

    # A method to extract fasta entry ids and length and make a hash
    #
    # @return [Hash] a hash of fasta entry ids as keys and sequence length as values
    def get_id_len
      @reference_db.load_fai_entries
      @reference_db.index.entries.each_entry do | entry |
        @id_len[entry.id] = entry.length
      end
    end

    # A method to returns left and right sequence of specified length, for a provided id and position
    # @note this method excludes the base at the position provided
    # @param id [String]
    # @param pos [Integer]
    # @return [Array<String>]
    def fetch_seq(id, pos)
      limit = Options.sel_seq_len + 1
      len = @id_len[id]
      low = pos-limit <= 0 ? 0 : pos-limit
      high = pos+limit >= len ? len : pos+limit
      region = Bio::DB::Fasta::Region.parse_region("#{id}:#{low}-#{pos-1}")
      seq_left = @reference_db.fetch_sequence(region)
      region = Bio::DB::Fasta::Region.parse_region("#{id}:#{pos+1}-#{high}")
      seq_right = @reference_db.fetch_sequence(region)
      [seq_left, seq_right]
    end

  end

end

