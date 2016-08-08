require 'test_helper'

class ImplementerTest < Minitest::Test

  context 'implementer_test' do

    setup do
      file1 = File.join(File.dirname(__FILE__), 'data', 'picked_fasta.fa')
      file2 = File.join(File.dirname(__FILE__), 'data', 'mut_bulk.pileup')
      file3 = File.join(File.dirname(__FILE__), 'data', 'wt_bulk.pileup')
      file4 = File.join(File.dirname(__FILE__), 'data', 'mut_parent.pileup')
      file5 = File.join(File.dirname(__FILE__), 'data', 'wt_parent.pileup')
      testcmd = Cheripic::Cmd.new("--assembly #{file1} --mut-bulk #{file2} --bg-bulk #{file3} --mut-parent #{file4}
--bg-parent #{file5} --polyploidy true --no-only-frag-with-vars --no-filter-out-low-hmes --output test/cheripic_results".split)
      @options = testcmd.options
    end

    teardown do
      delete_outdir
    end

    should 'successfully complete analysis run' do
      @implementing = Cheripic::Implementer.new(@options)
      @implementing.run
      assert_equal(true, @implementing.has_run)
    end

  end

end