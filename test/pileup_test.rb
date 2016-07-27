require 'test_helper'

class PileupTest < Minitest::Test

  context 'pileup_test' do

    should 'correct pileup' do
      pile = Cheripic::Pileup.new('scaffold21	15820	C	45	,,,,.,,,,......,...,,,,.,,,,$.,...*..,,..,.^].^],^],	FFHHEJJIJEEEEFFIHHCJIJIJI@ICJIJJJFJJADFFDC1DD')
      output = ',,,,.,,,,......,...,,,,.,,,,.,.....,,..,..,,'
      assert_equal output, pile.read_bases
    end

    should 'get insertion pileup' do
      pile = Cheripic::Pileup.new('scaffold81	21198	A	28	.$,$.$.+1T,+1t.+1T.+1T,+1t,+1t.+1T.+1T,+1t.+1T.+1T.+1T.+1T,+1t,+1t.+1T.+1T.+1T,+1t.+1T.+1T.+1T,+1t,+1t,+1t	AFEAHDEJJGHJJJHJDIJJIJJJJEEE')
      outhash = {:ref=>28, :A=>0, :C=>0, :G=>0, :T=>0, :indel=>25, :cov=>28.0}
      assert_equal outhash, pile.bases_hash
    end

    should 'get deletion pileup' do
      pile = Cheripic::Pileup.new('scaffold6	539	A	34	....,.,,,,,,,,,,,..,-2at.-2AT.-2AT.-2AT,,.-2AT..,-2at,,.,,	IGGJGIIIHFDD>E<FEJICHIJGGJJAAADHCC')
      outhash = {:ref=>34, :A=>0, :C=>0, :G=>0, :T=>0, :indel=>6, :cov=>34.0}
      assert_equal outhash, pile.bases_hash
    end

    should 'get deletion nonrefratio' do
      pile = Cheripic::Pileup.new('scaffold6	539	A	34	....,.,,,,,,,,,,,..,-2at.-2AT.-2AT.-2AT,,.-2AT..,-2at,,.,,	IGGJGIIIHFDD>E<FEJICHIJGGJJAAADHCC')
      nonrefratio = 0.176 # 6/34
      assert_equal nonrefratio, pile.non_ref_ratio.round(3)
    end

  end

end
