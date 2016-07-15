require 'test_helper'

class VariantsTest < Minitest::Test

  context 'variants_test' do

    setup do
      @file1 = File.join(File.dirname(__FILE__), 'data', 'picked_fasta.fa')
      @file2 = File.join(File.dirname(__FILE__), 'data', 'mut_bulk.pileup')
      @file3 = File.join(File.dirname(__FILE__), 'data', 'wt_bulk.pileup')
      @file4 = File.join(File.dirname(__FILE__), 'data', 'mut_parent.pileup')
      @file5 = File.join(File.dirname(__FILE__), 'data', 'wt_parent.pileup')

      @testcmd = Cheripic::Cmd.new("--assembly #{@file1} --mut-bulk #{@file2} --bg-bulk #{@file3} --mut-parent #{@file4} --bg-parent #{@file5} --polyploidy true --output test/cheripic_results".split)
      @options = @testcmd.options
      @implementing = Cheripic::Implementer.new(@options)
      @variants = Cheripic::Variants.new(@options)
    end

    teardown do
      delete_outdir
    end

    should 'extract pileups' do
      @variants.analyse_pileups
      assert_equal true, @variants.has_run
    end

    should 'select hmes contigs' do
      @variants.compare_pileups
      hash = @variants.hmes_frags
      assert_equal %w{CL22874Contig1 scaffold6147}, hash.keys
    end

    should 'select bfrcontigs' do
      @variants.compare_pileups
      hash = @variants.bfr_frags
      assert_equal %w{scaffold6147 scaffold1920}, hash.keys
    end

  end

end