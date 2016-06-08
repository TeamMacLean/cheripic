#!/usr/bin/env ruby

module Cheripic

  class Options

    require 'ostruct'
    # class << self; attr_accessor :params end

    @defaults = {
        :hmes_adjust => 0.5,
        :htlow => 0.2,
        :hthigh => 0.9,
        :mindepth => 6,
        :min_non_ref_count => 3,
        :min_indel_count_support => 3,
        :ignore_reference_n => true,
        :mapping_quality => 20,
        :base_quality => 15,
        :noise => 0.1,
        :cross_type => 'back',
        :only_frag_with_vars => true,
        :filter_out_low_hmes => true,
        :polyploidy => false,
        :br_adjust => 0.05
    }
    # @params = OpenStruct.new(@defaults)

    def self.update(newset)
      @defaults.merge!(newset)
      self.params
      # @params = OpenStruct.new(@defaults)
    end

    def self.params
      OpenStruct.new(@defaults)
    end

  end

end
