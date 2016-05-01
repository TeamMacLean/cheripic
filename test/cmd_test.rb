require 'test_helper'

class CmdTest < Minitest::Test

  context 'cmd_test' do

    should 'fail if output directory is present' do
      %x[mkdir test_output]
      assert_raises Cheripic::CheripicArgError do
        Cheripic::Cmd.new('--output test_output'.split)
      end
      %x[rmdir test_output]
    end

    should 'fail on non recognised log level' do
      assert_raises Cheripic::CheripicArgError do
        Cheripic::Cmd.new('--loglevel details'.split)
      end
    end

    should 'fail on non available fasta file' do
      assert_raises Cheripic::CheripicIOError do
        Cheripic::Cmd.new('--assembly foo.fasta'.split)
      end
    end

    should 'fail on non available bulk file' do
      assert_raises Cheripic::CheripicIOError do
        Cheripic::Cmd.new('--assembly test/data/input.fasta --mut-bulk foo.pileup'.split)
      end
    end

    should 'fail if at least one input files are missing' do
      assert_raises Cheripic::CheripicArgError do
        Cheripic::Cmd.new('--assembly test/data/input.fasta'.split)
      end
    end

  end

end