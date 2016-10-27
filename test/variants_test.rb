require 'test_helper'

class VariantsTest < Minitest::Test

  context 'variants_test' do

    setup do
      file1 = File.join(File.dirname(__FILE__), 'data', 'picked_fasta.fa')
      file2 = File.join(File.dirname(__FILE__), 'data', 'mut_bulk.pileup')
      file3 = File.join(File.dirname(__FILE__), 'data', 'wt_bulk.pileup')
      file4 = File.join(File.dirname(__FILE__), 'data', 'mut_parent.pileup')
      file5 = File.join(File.dirname(__FILE__), 'data', 'wt_parent.pileup')

      testcmd = Cheripic::Cmd.new("--assembly #{file1} --mut-bulk #{file2} --bg-bulk #{file3} --mut-parent #{file4} --bg-parent #{file5} --polyploidy true --output cheripic_results".split)
      options = testcmd.options
      Cheripic::Implementer.new(options)
      @variants = Cheripic::Variants.new(options)
    end

    teardown do
      delete_outdir
    end

    should 'extract pileups' do
      @variants.analyse_pileups
      assert_equal true, @variants.pileups_analyzed
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

  context 'input_seq_test' do

    setup do
      @file1 = File.join(File.dirname(__FILE__), 'data', 'picked_fasta.fa')
      @file2 = File.join(File.dirname(__FILE__), 'data', 'mut_bulk.pileup')
      @file3 = File.join(File.dirname(__FILE__), 'data', 'wt_bulk.pileup')
      @file4 = File.join(File.dirname(__FILE__), 'data', 'mut_parent.pileup')
      @file5 = File.join(File.dirname(__FILE__), 'data', 'wt_parent.pileup')
      @file6 = File.join(File.dirname(__FILE__), 'data', 'maize_data', 'sel_maize_test.fa')
      @file7 = File.join(File.dirname(__FILE__), 'data', 'maize_data', 'mutant_selected_vars.vcf')
      @file8 = File.join(File.dirname(__FILE__), 'data', 'maize_data', 'wildtype_selected_vars.vcf')
    end

    teardown do
      delete_outdir
    end

    should 'fail on empty sequence' do
      file1 = File.join(File.dirname(__FILE__), 'data', 'empty_seq.fa')
      testcmd = Cheripic::Cmd.new("--assembly #{file1} --mut-bulk #{@file2} --bg-bulk #{@file3} --output cheripic_results".split)
      options = testcmd.options
      assert_raises Cheripic::VariantsError do
        Cheripic::Variants.new(options)
      end
    end

    should 'fail on duplicate fasta ids' do
      file1 = File.join(File.dirname(__FILE__), 'data', 'dup_names.fa')
      testcmd = Cheripic::Cmd.new("--assembly #{file1} --mut-bulk #{@file2} --bg-bulk #{@file3} --output cheripic_results".split)
      options = testcmd.options
      assert_raises Cheripic::VariantsError do
        Cheripic::Variants.new(options)
      end
    end

    should 'select all contigs with vars' do
      testcmd = Cheripic::Cmd.new("--assembly #{@file1} --mut-bulk #{@file2} --bg-bulk #{@file3}
--use-all-contigs true --output cheripic_results".split)
      Cheripic::Implementer.new(testcmd.options)
      variants = Cheripic::Variants.new(testcmd.options)
      variants.compare_pileups
      hash = variants.hmes_frags
      assert_equal %w{CL22874Contig1 scaffold6147 scaffold1920}, hash.keys
    end

    should 'select all contigs' do
      testcmd = Cheripic::Cmd.new("--assembly #{@file1} --mut-bulk #{@file2} --bg-bulk #{@file3} --mut-parent #{@file4}
--bg-parent #{@file5} --polyploidy true --use-all-contigs true --include-low-hmes true --output cheripic_results".split)
      Cheripic::Implementer.new(testcmd.options)
      variants = Cheripic::Variants.new(testcmd.options)
      variants.compare_pileups
      hash = variants.hmes_frags
      assert_equal %w{CL22874Contig1 scaffold6147 scaffold1920}, hash.keys
    end

    should 'get variants' do
      testcmd = Cheripic::Cmd.new("--assembly #{@file1} --mut-bulk #{@file2} --bg-bulk #{@file3} --mut-parent #{@file4}
--bg-parent #{@file5} --polyploidy true --use-all-contigs true --include-low-hmes true --output cheripic_results".split)
      implement = Cheripic::Implementer.new(testcmd.options)
      implement.extract_vars
      implement.process_variants(:hmes_frags)
      filename = "#{testcmd.options[:hmes_frags]}"
      selected =  Hash.new { |h,k| h[k] = {} }
      File.open(filename, 'r').each do |line|
        info = line.split(/\t/)
        next if info[0] == 'Score'
        selected[info[3]][info[4].to_i] = 1
      end
      expected = { 'CL22874Contig1' => { 332 => 1, 369 => 1, 370 => 1, 390 => 1, 396 => 1, 398 => 1, 424 => 1},
                   'scaffold6147' => { 294 => 1, 452 => 1, 469 => 1, 488 => 1, 511 => 1} }
      assert_equal(expected, selected)
    end

    should 'get variants from bam files' do
      # @file6 = File.join(File.dirname(__FILE__), 'data', 'maize_data', 'mutant_selected.pleup')
      # @file9 = File.join(File.dirname(__FILE__), 'data', 'maize_data', 'wildtype_selected.pleup')
      file9 = File.join(File.dirname(__FILE__), 'data', 'maize_data', 'mutant_selected_sorted.bam')
      file10 = File.join(File.dirname(__FILE__), 'data', 'maize_data', 'wildtype_selected_sorted.bam')
      testcmd = Cheripic::Cmd.new("--assembly #{@file6} -F bam --mut-bulk #{file9} --bg-bulk #{file10}
--mut-bulk-vcf #{@file7} --bg-bulk-vcf #{@file8},#{@file8} --max-d-multiple 0 --output cheripic_results".split)
      implement = Cheripic::Implementer.new(testcmd.options)
      implement.extract_vars
      implement.process_variants(:hmes_frags)
      filename = "#{testcmd.options[:hmes_frags]}"
      selected =  Hash.new { |h,k| h[k] = {} }
      File.open(filename, 'r').each do |line|
        info = line.split(/\t/)
        next if info[0] == 'Score'
        selected[info[3]][info[4].to_i] = 1
      end
      expected = {'TR1882_c0_g1_i1'=>{257=>1, 258=>1, 245=>1}, 'TR10422_c0_g1_i1'=>{307=>1, 308=>1, 322=>1, 346=>1, 355=>1}}
      assert_equal(expected, selected)
    end

    should 'get depth from bam files' do
      # @file6 = File.join(File.dirname(__FILE__), 'data', 'maize_data', 'mutant_selected.pleup')
      # @file9 = File.join(File.dirname(__FILE__), 'data', 'maize_data', 'wildtype_selected.pleup')
      file9 = File.join(File.dirname(__FILE__), 'data', 'maize_data', 'mutant_selected_sorted.bam')
      file10 = File.join(File.dirname(__FILE__), 'data', 'maize_data', 'wildtype_selected_sorted.bam')
      testcmd = Cheripic::Cmd.new("--assembly #{@file6} -F bam --mut-bulk #{file9} --bg-bulk #{file10}
--mut-bulk-vcf #{@file7} --bg-bulk-vcf #{@file8} --output cheripic_results".split)
      implement = Cheripic::Implementer.new(testcmd.options)
      implement.extract_vars
      max_depth = 214.43
      assert_equal(max_depth, Cheripic::Options::maxdepth.round(2))
    end

    should 'get variants from vcf files' do
      testcmd = Cheripic::Cmd.new("--assembly #{@file6} -F vcf --mut-bulk #{@file7} --bg-bulk #{@file8},#{@file8} --output cheripic_results".split)
      implement = Cheripic::Implementer.new(testcmd.options)
      implement.extract_vars
      implement.process_variants(:hmes_frags)
      filename = "#{testcmd.options[:hmes_frags]}"
      selected =  Hash.new { |h,k| h[k] = {} }
      File.open(filename, 'r').each do |line|
        info = line.split(/\t/)
        next if info[0] == 'Score'
        selected[info[3]][info[4].to_i] = 1
      end
      expected = {'TR1882_c0_g1_i1'=>{257=>1, 258=>1, 245=>1}, 'TR10422_c0_g1_i1'=>{307=>1, 308=>1, 322=>1, 346=>1, 355=>1}}
      assert_equal(expected, selected)
    end

  end

end