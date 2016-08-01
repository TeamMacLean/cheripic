#!/usr/bin/env ruby

module Cheripic

  class Options

    @def_settings = {
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
        :bfr_adjust => 0.05,
        :sel_seq_len => 50
    }

    @user_settings = @def_settings

    def self.hmes_adjust
      @user_settings[:hmes_adjust]
    end

    def self.htlow
      @user_settings[:htlow]
    end

    def self.hthigh
      @user_settings[:hthigh]
    end

    def self.mindepth
      @user_settings[:mindepth]
    end

    def self.min_non_ref_count
      @user_settings[:min_non_ref_count]
    end

    def self.min_indel_count_support
      @user_settings[:min_indel_count_support]
    end

    def self.ignore_reference_n
      @user_settings[:ignore_reference_n]
    end

    def self.mapping_quality
      @user_settings[:mapping_quality]
    end

    def self.base_quality
      @user_settings[:base_quality]
    end

    def self.noise
      @user_settings[:noise]
    end

    def self.cross_type
      @user_settings[:cross_type]
    end

    def self.only_frag_with_vars
      @user_settings[:only_frag_with_vars]
    end

    def self.filter_out_low_hmes
      @user_settings[:filter_out_low_hmes]
    end

    def self.polyploidy
      @user_settings[:polyploidy]
    end

    def self.bfr_adjust
      @user_settings[:bfr_adjust]
    end

    def self.sel_seq_len
      @user_settings[:sel_seq_len]
    end

    def self.update(newset)
      @user_settings = @def_settings.merge(newset)
    end

    def self.defaults
      @user_settings = @def_settings
    end

  end

end
