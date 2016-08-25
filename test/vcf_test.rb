require 'test_helper'

class VcfTest < Minitest::Test

  context 'vcf_test' do

    should 'get a hash of variants after filtering' do
      file1 = File.join(File.dirname(__FILE__), 'data', 'ngs.vcf')
      file2 = File.join(File.dirname(__FILE__), 'data', 'ngs_bg.vcf')
      vars = Cheripic::Vcf.filtering(file1, file2)
      result = {"frag1"=>{:het=>{5=>0.4375}, :hom=>{}}, "frag3"=>{:hom=>{}}}
      assert_equal(result, vars)
    end

    should 'get allele frequency from GATK vcf' do
      line = "chr1	10740313	.	A	G	188.30	PASS	AC=2;AF=1.00;AN=2;DP=11;Dels=0.00;HRun=1;HaplotypeScore=6.9635;MQ=26.82;MQ0=0;QD=17.12;SB=-72.04;sumGLbyD=20.12	GT:AD:DP:GQ:PL	1/1:1,10:7:21.05:221,21,0"
      vcf_obj = Bio::DB::Vcf.new(line)
      allele_freq = Cheripic::Vcf.get_allele_freq(vcf_obj)
      assert_equal(0.909, allele_freq.round(3))
    end

    should 'get allele frequency from samtools vcf' do
      line = "3	2611	.	C	CCTTCCA	217	.	INDEL;DP=49;AF1=0.5;AC1=1;DP4=18,8,8,2;MQ=60;FQ=217;PV4=0.69,0.41,1,1	PL	255,0,255"
      vcf_obj = Bio::DB::Vcf.new(line)
      allele_freq = Cheripic::Vcf.get_allele_freq(vcf_obj)
      assert_equal(0.278, allele_freq.round(3))
    end

    should 'get allele frequency from v4.0 vcf' do
      line = "20	14370	.	G	A	29	PASS	NS=3;DP=14;AF=0.5;DB;H2	GT:GQ:DP:HQ	0|0:48:1:51,51"
      vcf_obj = Bio::DB::Vcf.new(line)
      allele_freq = Cheripic::Vcf.get_allele_freq(vcf_obj)
      assert_equal(0.5, allele_freq)
    end

    should 'fail if polyploid parent files are missing' do
      line = "20	14370	.	G	A	29	PASS	NS=3;DP=14;DB;H2	GQ:DP:HQ	48:1:51,51"
      vcf_obj = Bio::DB::Vcf.new(line)
      assert_raises Cheripic::VcfError do
        Cheripic::Vcf.get_allele_freq(vcf_obj)
      end
    end

  end

end
