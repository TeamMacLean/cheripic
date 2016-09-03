#!/usr/bin/env ruby

module Cheripic

  # A class to get default settings and update user settings for parameters
  # and facilitate retrieval of settings any where in the module
  class Options

    # Default parameter settings
    @def_settings = {
        :hmes_adjust => 0.5,
        :htlow => 0.2,
        :hthigh => 0.9,
        :mindepth => 6,
        :maxdepth => 300,
        :min_non_ref_count => 3,
        :min_indel_count_support => 3,
        :ambiguous_ref_bases => false,
        :mapping_quality => 20,
        :base_quality => 15,
        :noise => 0.1,
        :cross_type => 'back',
        :use_all_contigs => false,
        :include_low_hmes => false,
        :polyploidy => false,
        :bfr_adjust => 0.05,
        :sel_seq_len => 50
    }

    # set defaults as user settings
    @user_settings = @def_settings

    # A value to adjust calculation of Homozygosity Enrichment Score (HMES)
    # @return [Float]
    def self.hmes_adjust
      @user_settings[:hmes_adjust]
    end

    # Lower cut off of Allele fraction for categorization of an variant to heterozygous
    # @return [Float]
    def self.htlow
      @user_settings[:htlow]
    end

    # Higher cut off of Allele fraction for categorization of an variant to heterozygous
    # @return [Float]
    def self.hthigh
      @user_settings[:hthigh]
    end

    # Minimum read coverage at the variant position to be considered for analysis
    # @return [Integer]
    def self.mindepth
      @user_settings[:mindepth]
    end

    # Maximum read coverage at the variant position to be considered for analysis
    # @return [Integer]
    def self.maxdepth
      @user_settings[:maxdepth]
    end

    # Minimum non reference count at the variant position to be considered for analysis
    # @return [Integer]
    def self.min_non_ref_count
      @user_settings[:min_non_ref_count]
    end

    # Minimum reads supporting an indel at the variant position to be considered for analysis as indel
    # @return [Integer]
    def self.min_indel_count_support
      @user_settings[:min_indel_count_support]
    end

    # Option to whether to ignore or consider the reference positions which are ambiguous
    # @note switching option name here so Pileup options are same
    # @return [Boolean]
    def self.ignore_reference_n
      @user_settings[:ambiguous_ref_bases] ? false : true
    end

    # Minimum alignment mapping quality of the read to be used for bam files
    # @return [Integer]
    def self.mapping_quality
      @user_settings[:mapping_quality]
    end

    # Minimum aligned base quality at the variant position to be considered for analysis
    # @return [Integer]
    def self.base_quality
      @user_settings[:base_quality]
    end

    # Threshold for fraction of read bases at variant position below which are ignored as noise
    # @return [Float]
    def self.noise
      @user_settings[:noise]
    end

    # Option for cross type used for generating bulk population
    # @note options are either 'back' or 'out'
    # @return [String]
    def self.cross_type
      @user_settings[:cross_type]
    end

    # Option to whether to ignore or consider the contigs with out any variants
    # @return [Boolean]
    def self.use_all_contigs
      @user_settings[:use_all_contigs]
    end

    # Option to whether to ignore or consider the contigs with low HME score
    # @return [Boolean]
    def self.include_low_hmes
      @user_settings[:include_low_hmes]
    end

    # Option to whether to set the input data is from polyploid or not
    # @return [Boolean]
    def self.polyploidy
      @user_settings[:polyploidy]
    end

    # A value to adjust calculation of bulk frequency ratio (bfr)
    # @return [Float]
    def self.bfr_adjust
      @user_settings[:bfr_adjust]
    end

    # Number of nucleotides of sequence to select from each side of the selected variant
    # @return [Integer]
    def self.sel_seq_len
      @user_settings[:sel_seq_len]
    end

    # Updates the values of options using a hash generated from user inputs
    # @param newset [Hash] a hash of option names as keys user settings as values
    def self.update(newset)
      @user_settings = @def_settings.merge(newset)
    end

    # Resets the values of options to defaults
    def self.defaults
      @user_settings = @def_settings
    end

  end

end
