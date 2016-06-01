# encoding: utf-8
require 'bio'
require 'bio-samtools'
require 'bio/db/pileup'

class Pileup < Bio::DB::Pileup

  attr_accessor :defaults

  def initialize(string, opts={})
    super(string)
    set_defaults(opts)
    adj_read_bases
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
    self.read_bases.gsub!(/\$/, '')
    self.read_bases.gsub!(/\*/, '')
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
    elsif self.read_bases =~ /\-/
      bases_hash = indels_to_hash('-')
    else
      bases_hash = hash_base_counts(self.read_bases)
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
      number += /^(\d+)[acgtryswkmbdhvnACGTRYSWKMBDHVN]/.match(element)[1].to_i
    end
    number
  end

  # count bases matching reference and non-reference
  # and calculate ratio of non_ref allele to total bases
  def non_ref_count
    read_bases = self.read_bases
    if read_bases =~ /\+/
      non_ref_count = read_bases.count('atgcnATGCN')
      pluscounts = read_bases.count('+')
      indel_bases = count_indel_bases('+')
      non_ref_count += pluscounts - indel_bases
    elsif read_bases =~ /\-/
      non_ref_count = read_bases.count('acgtryswkmbdhvnACGTRYSWKMBDHVN')
      minuscounts = read_bases.count('-')
      indel_bases = count_indel_bases('-')
      non_ref_count += minuscounts - indel_bases
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

  private

  # count number of indels and number non-indel base
  # and return a hash with bases and indel counts
  def indels_to_hash(delimiter)
    indel_bases = 'acgtryswkmbdhvnACGTRYSWKMBDHVN'
    non_indel_bases = String.new
    array = self.read_bases.split(delimiter)
    non_indel_bases << array.shift
    array.each do |element|
      # get number of nucleotides inserted or deleted
      number = /^(\d+)[#{indel_bases}]/.match(element)[1].to_i
      # capture remaining nucleotides
      non_indel_bases << element.gsub(/^#{number}\w{#{number}}/, '')
    end
    bases_hash = hash_base_counts(non_indel_bases)
    # check at least three reads are supporting indel
    indel_count = self.read_bases.count(delimiter)
    if indel_count >= @defaults[:min_indel_count_support]
      bases_hash[:indel] = indel_count
    end
    bases_hash
  end

  def hash_base_counts(readbases)
    return @hash_base_counts if @hash_base_counts
    @hash_base_counts = {}
    @hash_base_counts[:ref] = readbases.count('.,')
    @hash_base_counts[:A] = readbases.count('aA')
    @hash_base_counts[:C] = readbases.count('cC')
    @hash_base_counts[:G] = readbases.count('gG')
    @hash_base_counts[:T] = readbases.count('tT')
    # @hash_base_counts[:N] = read_bases.count('nN')
    @hash_base_counts
  end

end
