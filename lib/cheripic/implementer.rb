#!/usr/bin/env ruby

module Cheripic

  class ImplementerError < CheripicError; end

  class Implementer

    attr_accessor :options

    def initialize(inputs)
      @options = inputs
      FileUtils.mkdir_p @options.output
      Dir.chdir @options.output
    end

    def extract_vars
      variants = Variants.new(@options)
      variants.analyse
    end

    def run
      # return some value for now
      value = 1
      Dir.chdir('../')
      value
    end

  end

end
