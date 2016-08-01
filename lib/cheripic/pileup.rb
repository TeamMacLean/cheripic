# encoding: utf-8
module Cheripic

  class PileupError < CheripicError; end

  require 'bio'
  require 'bio-samtools'
  require 'bio/db/pileup'

  class Pileup < Bio::DB::Pileup

    attr_accessor :defaults

    def initialize(string, opts={})
      super(string)
      set_defaults(opts)
      adj_read_bases
      @indelbases = 'acgtryswkmbdhvnACGTRYSWKMBDHVN'
    end

    def set_defaults(opts)
      @defaults = {
        noise: 0.1,                  # noise level for read depth
        ht_low: 0.2,                 # min allele freq for heterozygosity
        ht_high: 0.9,                # max allele freq for heterozygosity
        min_depth: 6,                # minimum coverage for variant
        min_non_ref_count: 3,
        ignore_reference_n: true,
        min_indel_count_support: 3,
      }
      @defaults.merge(opts)
    end

    # removes mapping quality information
    def adj_read_bases
      # mapping quality after '^' symbol is substituted
      # to avoid splitting at non indel + or - characters
      # read ends marking by '$' symbol is substituted
      # insertion and deletion marking by '*' symbol is substituted
      self.read_bases.gsub!(/\^./, '')
      self.read_bases.delete! '$'
      self.read_bases.delete! '*'
      # warn about reads with ambiguous codes
      # if self.read_bases.match(/[^atgcATGC,\.\+\-0-9]/)
      #   warn "Ambiguous nucleotide\t#{self.read_bases}"
      # end
    end

    # count bases matching reference and non-reference
    # from snp variant and make a hash of bases with counts
    # for indels return the read bases information instead
    def bases_hash
      if self.read_bases =~ /\+/
        bases_hash = indels_to_hash('+')
      elsif self.read_bases =~ /-/
        bases_hash = indels_to_hash('-')
      else
        bases_hash = snp_base_hash(self.read_bases)
      end
      # some indels will have ref base in the read and using
      # sum of hash values is going to give wrong additional coverage
      # from indels so including actual coverage from pileup
      # bases_hash keys are :A, :C, :G, :T, :N, :ref, :indel and :cov
      bases_hash[:cov] = self.coverage
      bases_hash
    end

    # count bases from indels
    # array of pileup bases is split at + / -
    # and number after each + / - is counted
    def count_indel_bases(delimiter)
      array = self.read_bases.split(delimiter)
      number = 0
      array.shift
      array.each do |element|
        # deletions in reference could contain ambiguous codes,
        number += /^(\d+)[#{@indelbases}]/.match(element)[1].to_i
      end
      number
    end

    # count bases matching reference and non-reference
    # and calculate ratio of non_ref allele to total bases
    def non_ref_count
      read_bases = self.read_bases
      if read_bases =~ /\+/
        non_ref_count = indel_non_ref_count('+')
      elsif read_bases =~ /-/
        non_ref_count = indel_non_ref_count('-')
      else
        non_ref_count = read_bases.count('atgcATGC')
      end
      non_ref_count
    end

    # check if the pileup has the parameters we are looking for
    def is_var
      ignore_reference_n = @defaults[:ignore_reference_n]
      min_depth  = @defaults[:min_depth]
      min_non_ref_count = @defaults[:min_non_ref_count]

      return false if self.ref_base == '*'
      return false if ignore_reference_n and self.ref_base =~ /^[nN]$/
      return true if self.coverage >= min_depth and self.non_ref_count >= min_non_ref_count
      false
    end

    # count bases matching reference and non-reference
    # and calculate ratio of non_ref allele to total bases
    def non_ref_ratio
      self.non_ref_count.to_f / self.coverage.to_f
    end

    # calculate var zygosity for non-polyploid variants
    # increased range is used for heterozygosity for RNA-seq data
    # def var_mode
    #   ht_low = @defaults[:ht_low]
    #   ht_high = @defaults[:ht_high]
    #   mode = ''
    #   if self.non_ref_ratio.between?(ht_low, ht_high)
    #     mode = :het
    #   elsif self.non_ref_ratio > ht_high
    #     mode = :hom
    #   end
    #   mode
    # end

    # form hash of base information, [ATGC] counts for snp
    # a hash of base proportion is calculated
    # base proportion hash below a selected depth is empty
    # base proportion below or equal to a noise factor are discarded
    def var_base_frac
      hash = self.bases_hash
      snp_hash = {}
      coverage = hash[:cov]
      return snp_hash if coverage < @defaults[:min_depth]
      # calculate proportion of each base in coverage
      hash.each_key do | base |
        next if base == :cov
        freq = hash[base].to_f/coverage.to_f
        next if freq <= @defaults[:noise]
        snp_hash[base] = freq
      end
      snp_hash
    end


    private

    # count number of indels and number non-indel base
    # and return a hash with bases and indel counts
    def indels_to_hash(delimiter)
      non_indel_bases = String.new
      array = self.read_bases.split(delimiter)
      non_indel_bases << array.shift
      array.each do |element|
        # get number of nucleotides inserted or deleted
        number = /^(\d+)[#{@indelbases}]/.match(element)[1].to_i
        # capture remaining nucleotides
        non_indel_bases << element.gsub(/^#{number}\w{#{number}}/, '')
      end
      bases_hash = snp_base_hash(non_indel_bases)
      # check at least three reads are supporting indel
      indel_count = self.read_bases.count(delimiter)
      if indel_count >= @defaults[:min_indel_count_support]
        bases_hash[:indel] = indel_count
      end
      bases_hash
    end

    def snp_base_hash(readbases)
      non_indel_base_hash = {}
      non_indel_base_hash[:ref] = readbases.count('.,')
      non_indel_base_hash[:A] = readbases.count('aA')
      non_indel_base_hash[:C] = readbases.count('cC')
      non_indel_base_hash[:G] = readbases.count('gG')
      non_indel_base_hash[:T] = readbases.count('tT')
      # non_indel_base_hash[:N] = read_bases.count('nN')
      non_indel_base_hash
    end

    def indel_non_ref_count(delimitter)
      read_bases = self.read_bases
      non_ref_count = read_bases.count(@indelbases)
      indelcounts = read_bases.count(delimitter)
      indel_bases = count_indel_bases(delimitter)
      non_ref_count + indelcounts - indel_bases
    end

  end

end
