#!/usr/bin/env ruby
require 'bio-samtools'
require 'forwardable'

module Cheripic

  class RegionsError < CheripicError; end

  class Regions

    include Enumerable
    extend Forwardable
    def_delegators :@id_len, :each, :each_key, :each_value, :length, :[]
    attr_accessor :reference_db, :id_len

    def initialize(assembly)
      @reference_db = Bio::DB::Fasta::FastaFile.new({:fasta=>assembly})
      @id_len = {}
      self.get_id_len
    end

    def get_id_len
      @reference_db.load_fai_entries
      @reference_db.index.entries.each_entry do | entry |
        @id_len[entry.id] = entry.length
      end
    end

    # for each id and position returns left and right sequence
    # of pre-selected length
    def fetch_seq(id, pos)
      limit = Options.params.sel_seq_len + 1
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

