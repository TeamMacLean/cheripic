require 'test_helper'

class CmdTest < Minitest::Test

  context 'cmd_test' do

    setup do
      @file1 = File.join(File.dirname(__FILE__), 'data', 'input.fasta')
      @file2 = File.join(File.dirname(__FILE__), 'data', 'file1.pileup')
      delete_outdir
    end

    should 'fail if output directory is present' do
      Dir.mkdir('test/test_output')
      assert_raises Cheripic::CheripicArgError do
        Cheripic::Cmd.new('--output test/test_output'.split)
      end
      Dir.rmdir('test/test_output')
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
        Cheripic::Cmd.new("--assembly #{@file1} --mut-bulk foo.pileup".split)
      end
    end

    should 'fail if at least one input files are missing' do
      assert_raises Cheripic::CheripicArgError do
        Cheripic::Cmd.new("--assembly #{@file1}".split)
      end
    end

    should 'fail if polyploid parent files are missing' do
      assert_raises Cheripic::CheripicIOError do
        Cheripic::Cmd.new("--assembly #{@file1} --polyploidy true  --mut-bulk foo.pileup".split)
      end
    end

    should 'print help message' do
      begin
        puts '  -- printing help message to /dev/null'
        orig_stdout = $stdout.clone
        $stdout.reopen File.new('/dev/null', 'w')
        Cheripic::Cmd.new('-h'.split)
      rescue SystemExit
        $stdout.reopen orig_stdout
        # puts 'rescued a system exit from help printing'
      end
    end

    should 'print help examples' do
      begin
        puts '  -- printing help examples to /dev/null'
        orig_stdout = $stdout.clone
        $stdout.reopen File.new('/dev/null', 'w')
        Cheripic::Cmd.new('--examples'.split)
      rescue SystemExit
        $stdout.reopen orig_stdout
        # puts 'rescued a system exit from example printing'
      end
    end

    # should 'get some value from analysis run' do
    #   testcmd = Cheripic::Cmd.new("--assembly #{@file1} --mut-bulk #{@file2} --bg-bulk #{@file2} --output test/cheripic_results".split)
    #   assert_equal(1, testcmd.run)
    #   delete_outdir
    # end

  end

end