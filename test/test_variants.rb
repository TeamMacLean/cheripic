require 'test_helper'

class VariantsTest < Minitest::Test

  context 'variants_test' do

    setup do
      @file1 = File.join(File.dirname(__FILE__), 'data', 'picked_fasta.fa')
      @file2 = File.join(File.dirname(__FILE__), 'data', 'mut_bulk.pileup')
      @file3 = File.join(File.dirname(__FILE__), 'data', 'wt_bulk.pileup')
      @file4 = File.join(File.dirname(__FILE__), 'data', 'mut_parent.pileup')
      @file5 = File.join(File.dirname(__FILE__), 'data', 'wt_parent.pileup')

      @testcmd = Cheripic::Cmd.new("--assembly #{@file1} --mut-bulk #{@file2} --bg-bulk #{@file3} --mut-parent #{@file4} --bg-parent #{@file5} --output test/cheripic_results".split)
      FileUtils.mkdir_p @testcmd.output
      @variants = Cheripic::Variants.new(@testcmd)
    end

    should 'run' do
      #skip('skip for the moment')
      @variants.analyse
      assert_equal true, @variants.has_run
    end

    Dir.rmdir('test/cheripic_results')

  end

end