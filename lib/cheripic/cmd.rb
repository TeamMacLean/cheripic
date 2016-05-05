#!/usr/bin/env ruby

module Cheripic

  class Cmd

    require 'trollop'
    require 'pathname'
    require 'ostruct'

    def initialize(args)
      @options = OpenStruct.new
      @options = parse_arguments (args)
      check_arguments
    end

    def parse_arguments(args)
      Trollop::with_standard_exception_handling argument_parser do
        if args.empty? || args.include?('-h') || args.include?('--help')
          raise Trollop::HelpNeeded
        elsif args.include?('--examples')
          print_examples
        end
        argument_parser.parse args
      end
    end

    def argument_parser
      cmds = self
      Trollop::Parser.new do
        banner cmds.help_message
        opt :assembly, 'Assembly file in FASTA format',
            :short => '-f',
            :type => String
        opt :input_format, 'bulk and parent alignment file format types - set either pileup or bam',
            :short => '-F',
            :type => String,
            :default => 'pileup'
        opt :mut_bulk, 'Pileup or sorted BAM file alignments from mutant/trait of interest bulk 1',
            :short => '-a',
            :type => String
        opt :bg_bulk, 'Pileup or sorted BAM file alignments from background/wildtype bulk 2',
            :short => '-b',
            :type => String
        opt :output, 'Directory to store results, will be created if not existing',
            :default => 'cheripic_results'
        opt :loglevel, 'Choose any one of "info / warn / debug" level for logs generated',
            :default => 'info'
        opt :hmes_adjust, 'factor added to snp count of each contig to adjust for hme score calculations',
            :type => Float,
            :default => 0.5
        opt :htlow, 'lower level for categorizing heterozygosity',
            :type => Float,
            :default => 0.2
        opt :hthigh, 'high level for categorizing heterozygosity',
            :type => Float,
            :default => 0.9
        opt :mindepth, 'minimum read depth to conisder a position for variant calls',
            :type => Integer,
            :default => 6
        opt :min_non_ref_count, 'minimum read depth supporting non reference base at each position',
            :type => Integer,
            :default => 3
        opt :min_indel_count_support, 'minimum read depth supporting an indel at each position',
            :type => Integer,
            :default => 3
        opt :ignore_reference_n, 'ignore variant calls at N (completely ambigous) bases in the reference',
            :type => FalseClass,
            :default => true
        opt :mapping_quality, 'minimum mapping quality of read covering the position',
            :short => '-q',
            :type => Integer,
            :default => 20
        opt :base_quality, 'minimum base quality of bases covering the position',
            :short => '-Q',
            :type => Integer,
            :default => 15
        opt :noise, 'praportion of reads for a variant to conisder as noise',
            :type => Float,
            :default => 0.1
        opt :cross_type, 'type of cross used to generated mapping population - back or out',
            :type => String,
            :default => 'back'
        opt :only_frag_with_vars, 'select only contigs containing variants for analysis',
            :type => FalseClass,
            :default => true
        opt :filter_out_low_hmes, 'ignore variants from contigs with low hmescore or bfr to list in the final output',
            :type => FalseClass,
            :default => true
        opt :polyploidy, 'Set if the data input is from polyploids',
            :type => FalseClass,
            :default => false
        opt :mut_parent, 'Pileup or sorted BAM file alignments from mutant/trait of interest parent',
            :short => '-p',
            :type => String,
            :default => ''
        opt :bg_parent, 'Pileup or sorted BAM file alignments from background/wildtype parent',
            :short => '-r',
            :type => String,
            :default => ''
        opt :br_adjust, 'factor added to hemi snp frequency of each parent to adjust for bfr calculations',
            :type => Float,
            :default => 0.05
        opt :examples, 'shows some example commands with explanation'
      end
    end

    def help_message
      <<-EOS

Cheripic v#{Cheripic::VERSION.dup}
Authors: Shyam Rallapalli and Dan MacLean

Description: Candidate mutation and closely linked marker selection for non reference genomes
Uses bulk segregant data from non-reference sequence genomes

Inputs:
1. Needs a reference fasta file of asssembly use for variant analysis
2. Pileup files for mutant (phenotype of interest) bulks and background (wildtype phenotype) bulks
3. If polyploid species, include of pileup from one or both parents

USAGE:
cheripic <options>

OPTIONS:

      EOS
    end

    def print_examples
      msg = <<-EOS

    Cheripic v#{Cheripic::VERSION.dup}

    EXAMPLE COMMANDS:

      EOS
      puts msg.split("\n").map{ |line| line.lstrip }.join("\n")
      exit(0)
    end

    def check_arguments
      check_output_dir
      check_log_level
      check_input_files
    end

    # TODO: check bulk input types and process associated files
    # def check_input_types
    #   if @options.input_format == 'vcf'
    #
    #   end
    # end

    def check_input_files
      if @options.polyploidy
        inputfiles = %i{assembly mut_bulk bg_bulk mut_parent bg_parent}
      else
        inputfiles = %i{assembly mut_bulk bg_bulk}
      end
      inputfiles.each do | symbol |
        if @options[symbol]
          file = @options[symbol]
          @options[symbol] = File.expand_path(file)
          unless File.exist?(file)
            raise CheripicIOError.new "#{symbol} file, #{file} does not exist: "
          end
        else
          raise CheripicArgError.new "Options #{inputfiles}, all must be specified. " +
                                            'Try --help for help.'
        end
      end
    end

    def check_output_dir
      if Dir.exist?(@options.output)
        raise CheripicArgError.new "#{@options.output} directory exists" +
                                       'please choose a different output directory name'
      end
    end

    def check_log_level
      unless %w(error info warn debug).include?(@options.loglevel)
        raise CheripicArgError.new "Loglevel #{@options.loglevel} is not valid. " +
                                       'It must be one of: error, info, warn, debug.'
      end
      logger.level = Yell::Level.new @options.loglevel.to_sym
    end

    def run
      @options.output = File.expand_path @options.output
      FileUtils.mkdir_p @options.output
      Dir.chdir @options.output
      analysis = Cheripic::Implementer.new(@options)
      analysis.run
    end

  end # Cmd

end # Cheripic
