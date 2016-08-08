
# sets up a global logger object to access across module
require 'yell'

# Computing Homozygosity Enriched Regions In genomes to Prioritize Identification of Candidate variants (CHERIPIC)
# Cheripic module provides tools and pipeline to extract potential candidate mutations
# in around the region of the genome hosting the causative mutation behind the phenotype of interest.
module Cheripic

  # custom error handling
  class CheripicError < StandardError; end
  # custom error handling for IO
  class CheripicIOError < CheripicError; end
  # custom error handling for Arg
  class CheripicArgError < CheripicError; end

  # Define a logger and pass `Object` as name.
  # Yell adds this logger to the repository where you can access it later on.
  format = Yell::Formatter.new('[%5L] %d : %m', '%Y-%m-%d %H:%M:%S')
  Yell.new(:format => format) do |l|
    l.level = :info
    l.name = Object
    l.adapter STDOUT, level: [:debug, :info, :warn]
    l.adapter STDERR, level: [:error, :fatal]
  end
  # Enable logging for the class that (almost) every Ruby class inherits from
  Object.send :include, Yell::Loggable

end # Cheripic

require 'cheripic/cmd'
require 'cheripic/version'
require 'cheripic/implementer'
require 'cheripic/variants'
require 'cheripic/contig'
require 'cheripic/pileup'
require 'cheripic/options'
require 'cheripic/contig_pileups'
require 'cheripic/bfr'
require 'cheripic/regions'
