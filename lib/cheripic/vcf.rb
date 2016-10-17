# encoding: utf-8

module Cheripic

  # Custom error handling for Vcf class
  class VcfError < CheripicError; end

  require 'bio-samtools'

  class Vcf

    def self.get_allele_depth(vcf_obj)
      # check if the vcf is from samtools (has DP4 and AF1 fields in INFO)
      if vcf_obj.info.key?('DP4')
        freq = vcf_obj.info['DP4'].split(',')
        ref = freq[0].to_f + freq[1].to_f
        alt = freq[2].to_f + freq[3].to_f
      # check if the vcf is from VarScan (has RD, AD and FREQ fields in FORMAT)
      elsif vcf_obj.samples['1'].key?('RD')
        ref = vcf_obj.samples['1']['RD'].to_f
        alt = vcf_obj.samples['1']['AD'].to_f
      # check if the vcf is from GATK (has AD and GT fields in FORMAT)
      elsif vcf_obj.samples['1'].key?('AD') and vcf_obj.samples['1']['AD'].include?(',')
        freq = vcf_obj.samples['1']['AD'].split(',')
        ref = freq[0].to_i
        alt = freq[1].to_i
      # check if the vcf has has AF fields in INFO
      elsif vcf_obj.info.key?('AF')
        allele_freq = vcf_obj.info['AF'].to_f
        depth = vcf_obj.info['DP'].to_i
        alt = (depth * allele_freq).round
        ref = depth - alt
      else
        raise VcfError.new 'not a supported vcf format (VarScan, GATK, Bcftools(Samtools), Vcf 4.0, 4.1 and 4.2)' +
                               " and check that it is one sample vcf\n"
      end
      [ref, alt]
    end

    def self.get_allele_freq(vcf_obj)
      ref, alt = get_allele_depth(vcf_obj)
      alt.to_f/(ref + alt)
    end

    ##Input: vcf file
    ##Ouput: lists of hm and ht SNPS and hash of all fragments with variants
    def self.get_vars(vcf_file)
      ht_low = Options.htlow
      ht_high = Options.hthigh

      # hash of :het and :hom with frag ids and respective variant positions
      var_pos = Hash.new{ |h,k| h[k] = Hash.new(&h.default_proc) }
      File.foreach(vcf_file) do |line|
        next if line =~ /^#/
        v = Bio::DB::Vcf.new(line)
        unless v.alt == '.'
          allele_freq = get_allele_freq(v)
          if allele_freq.between?(ht_low, ht_high)
            var_pos[v.chrom][:het][v.pos] = allele_freq
          elsif allele_freq > ht_high
            var_pos[v.chrom][:hom][v.pos] = allele_freq
          end
        end
      end
      var_pos
    end

    def self.filtering(mutant_vcf, bgbulk_vcf)
      var_pos_mut = get_vars(mutant_vcf)
      return var_pos_mut if bgbulk_vcf == ''
      var_pos_bg = get_vars(bgbulk_vcf)

      # if both bulks have homozygous mutations at same positions then deleting them
      var_pos_mut.each_key do | frag |
        positions = var_pos_mut[frag][:hom].keys
        pos_bg_bulk = var_pos_bg[frag][:hom].keys
        positions.each do |pos|
          if pos_bg_bulk.include?(pos)
            var_pos_mut[frag][:hom].delete(pos)
          end
        end
      end
      var_pos_mut
    end

  end

end