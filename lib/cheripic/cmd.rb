#!/usr/bin/env ruby

module Cheripic

  class Cmd

    require 'trollop'
    require 'pathname'
    require 'ostruct'

    def initialize (args)
      @options = OpenStruct.new
      @options = parse_arguments (args)
      if @options.examples
        print_examples
      end
      check_arguments
    end

    def parse_arguments (args)
      Trollop::with_standard_exception_handling argument_parser do
        if args.empty? || args.include?('-h') || args.include?('--help')
          raise Trollop::HelpNeeded
        end
        argument_parser.parse args
      end
    end

    def argument_parser
      Trollop::Parser.new do
        banner self.help_message
        opt :fasta, 'Assembly file in FASTA format',
            :short => '-f',
            :type => String
        opt :input_format, 'bulk and parent alignment file format types - set either pileup or bam',
            :short => '-F',
            :type => String,
            :default => 'pileup'
        opt :mut_bulk, 'Pileup or sorted BAM file alignments from mutant/trait of interest bulk 1',
            :short => '-b1',
            :type => String
        opt :bg_bulk, 'Pileup or sorted BAM file alignments from background/wildtype bulk 2',
            :short => '-b2',
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
            :short => '-p1',
            :type => String,
            :default => ''
        opt :bg_parent, 'Pileup or sorted BAM file alignments from background/wildtype parent',
            :short => '-p2',
            :type => String,
            :default => ''
        opt :br_adjust, 'factor added to hemi snp frequency of each parent to adjust for bfr calculations',
            :type => Float,
            :default => 0.05
        opt :examples, 'Show some example commands with explanation'
      end
    end

    def help_message
      <<-EOS

Cheripic-Mut v#{Cheripic::VERSION.dup}
Authors: Shyam Rallapalli and Dan MacLean

Description: Candidate mutation and closely linked marker selection for non reference genomes
Uses bulk segregant data from non-reference sequence genomes

Inputs:
1. Needs a reference fasta file of asssembly use for variant analysis
2. Pileup files for mutant (phenotype of interest) bulks and background (wildtype phenotype) bulks
3. If polyploid species, include of pileup from one or both parents

USAGE:
cheripic-mut <options>

OPTIONS:

      EOS
    end

    def print_examples
      msg = <<-EOS

    Cheripic-mut v#{Cheripic::VERSION.dup}

    EXAMPLE COMMANDS:

    # basic assembly metrics only
    cheripic-mut --assembly contigs.fa

    # basic and reference-based metrics with 8 threads
    cheripic-mut --assembly contigs.fa --reference ref.fa --threads 8

    # contig and read-based metrics for two assemblies with 32 threads
    cheripic-mut --assembly one.fa,two.fa --left l.fq --right r.fq --threads 32

      EOS
      puts msg.split("\n").map{ |line| line.lstrip }.join("\n")
      exit(0)
    end

    def check_arguments
      check_inputfiles
      check_output
      check_loglevel
    end

    def check_input_types
      if @options.input_format == 'vcf'

      end
    end

    def check_inputfiles
      if @options.polyploidy
        inputfiles = %w[assembly, mut_bulk, bg_bulk, mut_parent, bg_parent]
      else
        inputfiles = %w[assembly, mut_bulk, bg_bulk]
      end
      inputfiles.each do | file |
        check_file(@options, file.to_sym)
      end
    end

    def check_file(options, symbol)
      if options.respond_to?(symbol)
        file = options.send(symbol)
        options[symbol] = File.expand_path(file)
        unless File.exist?(file)
          raise CheripicIOError.new "#{symbol.to_s} file does not exist: " +
                                           " #{file}"
        end
      else
        raise CheripicArgError.new "Option --#{symbol.to_s} must be specified. " +
                                          'Try --help for help.'
      end
    end

    def check_output
      if Dir.exist?(@options.output)
        msg = "#{@options.output} directory exists"
        msg << 'please choose a different output directory name'
        raise CheripicArgError.new msg
      end
    end

    def check_loglevel
      unless %w[error info warn debug].include?(@options.log_level)
        raise CheripicError.new "Loglevel #{@options.log_level} is not valid. " +
                                       'It must be one of: error, info, warn, debug.'
      end
      logger.level = Yell::Level.new @options.log_level.to_sym
    end

    def run
      @options.output = File.expand_path @options.output
      FileUtils.mkdir_p @options.output
      Dir.chdir @options.output
      analyse_bulks(@options)
    end

    def analyse_bulks(options)
      assembly = options.fasta
      logger.info "Loading assembly: #{assembly}"
      # a = Assembly.new assembly
      logger.info "Analysing assembly: #{assembly}"

    end

  end # Cmd

end # Cheripic
