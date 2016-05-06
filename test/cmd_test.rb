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

    should 'fail if polyploid parent files are missing' do
      assert_raises Cheripic::CheripicIOError do
        Cheripic::Cmd.new('--assembly test/data/input.fasta --polyploidy true  --mut-bulk foo.pileup'.split)
      end
    end

    should 'print help message' do
      begin
        puts 'printing help message'
        Cheripic::Cmd.new('-h'.split)
      rescue SystemExit
        puts 'rescued a system exit from help printing'
      end
    end

    should 'print help examples' do
      begin
        puts 'printing examples'
        Cheripic::Cmd.new('--examples'.split)
      rescue SystemExit
        puts 'rescued a system exit from example printing'
      end
    end

    should 'get some value from analysis run' do
      testcmd = Cheripic::Cmd.new('--assembly test/data/input.fasta --mut-bulk test/data/file1.pileup --bg-bulk test/data/file1.pileup'.split)
      assert_equal(1, testcmd.run)
      puts "#{Dir.pwd}"
      Dir.rmdir('cheripic_results')
    end

  end

end