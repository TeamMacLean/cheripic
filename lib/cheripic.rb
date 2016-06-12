
# set up a golbal logger object to access across module
require 'yell'
module Cheripic

  # custom error handling
  class CheripicError < StandardError; end
  class CheripicIOError < CheripicError; end
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
