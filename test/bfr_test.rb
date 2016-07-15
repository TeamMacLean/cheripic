require 'test_helper'

class BfrTest < Minitest::Test

  context 'bfr_test' do

    should 'get bfr with both 2 key hash' do
      mut_hash = {:ref=>0.75, :C=>0.25}
      bg_hash = {:ref=>0.32, :C=>0.68}
      value = Cheripic::Bfr.get_bfr(mut_hash, bg_hash)
      assert_equal 2.43, value.round(2)
    end

    should 'get bfr with one 2 key hash' do
      mut_hash = {:C=>0.95}
      bg_hash = {:ref=>0.32, :A=>0.68}
      value = Cheripic::Bfr.get_bfr(mut_hash, bg_hash)
      assert_equal 1.44, value.round(2)
    end

    should 'get bfr with both 1 key hash' do
      mut_hash = {:C=>0.95}
      bg_hash = {:ref=>0.95}
      value = Cheripic::Bfr.get_bfr(mut_hash, bg_hash)
      assert_equal 20, value
    end

    should 'get bfr with one 1 key hash' do
      mut_hash = {:C=>0.35, :ref=>0.55, :A=>0.10}
      bg_hash = {:A=>0.95}
      value = Cheripic::Bfr.get_bfr(mut_hash, bg_hash)
      assert_equal 4.67, value.round(2)
    end

    should 'get no bfr with both more than two key hash' do
      mut_hash = {:C=>0.35, :ref=>0.55, :A=>0.10}
      bg_hash = {:C=>0.35, :ref=>0.55, :A=>0.10}
      value = Cheripic::Bfr.get_bfr(mut_hash, bg_hash)
      assert_equal '', value
    end

    should 'get no bfr with more than two key hash' do
      mut_hash = {:C=>0.35, :ref=>0.55, :A=>0.10}
      value = Cheripic::Bfr.get_bfr(mut_hash)
      assert_equal '', value
    end

  end

end