require 'test_helper'

class CmdTest < Minitest::Test

  context 'cmd_test' do

    should 'fail on non available fasta file' do
      assert_raises Cheripic::CheripicIOError do
        Cheripic::Cmd.new('--assembly foo.fasta'.split)
      end
    end

    should 'fail on non recognised log level' do
      assert_raises Cheripic::CheripicError do
        Cheripic::Cmd.new('--assembly foo.fasta --loglevel details'.split)
      end
    end

  end

end