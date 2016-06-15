require 'test_helper'
require 'ostruct'
class OptionsTest < Minitest::Test

  context 'options_test' do

    setup do
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
          :bfr_adjust => 0.05
      }
      Cheripic::Options::update(@defaults)
    end

    should 'get default params' do
      assert_equal(OpenStruct.new(@defaults), Cheripic::Options::params)
    end

    should 'get updated params' do
      newset = {
          :hmes_adjust => 1.0,
          :htlow => 0.3,
          :hthigh => 0.8,
          :mindepth => 6,
          :min_non_ref_count => 3,
          :min_indel_count_support => 3,
          :ignore_reference_n => true,
          :mapping_quality => 20,
          :base_quality => 15,
          :noise => 0.2,
          :cross_type => 'back',
          :only_frag_with_vars => true,
          :filter_out_low_hmes => true,
          :polyploidy => false,
          :bfr_adjust => 0.05
      }
      Cheripic::Options::update(newset)
      assert_equal(OpenStruct.new(newset), Cheripic::Options::params)
    end


  end

end