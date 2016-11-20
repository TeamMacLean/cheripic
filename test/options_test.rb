require 'test_helper'
require 'ostruct'
class OptionsTest < Minitest::Test

  context 'options_test' do

    should 'get default params' do
      defaults = {
          :hmes_adjust => 0.5,
          :htlow => 0.25,
          :hthigh => 0.75,
          :mindepth => 6,
          :maxdepth => 0,
          :max_d_multiple=>5,
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
      assert_equal(defaults, Cheripic::Options::defaults)
      assert_equal(0.5, Cheripic::Options::hmes_adjust)
      assert_equal(0.25, Cheripic::Options::htlow)
      assert_equal(0.75, Cheripic::Options::hthigh)
      assert_equal(6, Cheripic::Options::mindepth)
      assert_equal(0, Cheripic::Options::maxdepth)
      assert_equal(5, Cheripic::Options::max_d_multiple)
      assert_equal(3, Cheripic::Options::min_non_ref_count)
      assert_equal(3, Cheripic::Options::min_indel_count_support)
      assert_equal(true, Cheripic::Options::ignore_reference_n)
      assert_equal(20, Cheripic::Options::mapping_quality)
      assert_equal(15, Cheripic::Options::base_quality)
      assert_equal(0.1, Cheripic::Options::noise)
      assert_equal('back', Cheripic::Options::cross_type)
      assert_equal(false, Cheripic::Options::use_all_contigs)
      assert_equal(false, Cheripic::Options::include_low_hmes)
      assert_equal(false, Cheripic::Options::polyploidy)
      assert_equal(0.05, Cheripic::Options::bfr_adjust)
      assert_equal(50, Cheripic::Options::sel_seq_len)
    end

    should 'get updated params' do
      newset = {
          :hmes_adjust => 1.0,
          :htlow => 0.3,
          :hthigh => 0.8,
          :mindepth => 6,
          :maxdepth => 0,
          :max_d_multiple=>3,
          :min_non_ref_count => 3,
          :min_indel_count_support => 3,
          :ambiguous_ref_bases => false,
          :mapping_quality => 20,
          :base_quality => 15,
          :noise => 0.2,
          :cross_type => 'back',
          :use_all_contigs => false,
          :include_low_hmes => false,
          :polyploidy => false,
          :bfr_adjust => 0.05,
          :sel_seq_len => 50
      }
      assert_equal(newset, Cheripic::Options::update(newset))
      assert_equal(newset, Cheripic::Options::current_values)
    end

    should 'get udpated max depth' do
      Cheripic::Options::maxdepth = 50
      assert_equal(50, Cheripic::Options::maxdepth)
      # reset maxdepth to zero for default comparison
      Cheripic::Options::maxdepth = 0
    end


  end

end