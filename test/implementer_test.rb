require 'test_helper'

class ImplementerTest < Minitest::Test

  context 'implementer_test' do

    setup do
      a = File.join(File.dirname(__FILE__), 'data', 'input.fasta')
      b = File.join(File.dirname(__FILE__), 'data', 'file1.pileup')
      testcmd = Cheripic::Cmd.new("--assembly #{a} --mut-bulk  #{b} --bg-bulk  #{b} --output test/cheripic_results".split)
      @options = testcmd.options
      @implementing = Cheripic::Implementer.new(@options)
    end

    should 'when run gives result of 1' do
      assert_equal(1, @implementing.run)
      if Dir.exist?('test/cheripic_results')
        Dir.rmdir('test/cheripic_results')
      end
    end

    should 'do some analysis if inputs are provide' do
      if Dir.exist?('test/cheripic_results')
        Dir.rmdir('test/cheripic_results')
      end
      skip('skipping analysis for the moment, until dependencies are fixed')
    end

  end

end