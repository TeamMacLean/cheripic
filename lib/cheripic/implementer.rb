#!/usr/bin/env ruby

module Cheripic

  class ImplementerError < CheripicError; end

  class Implementer

    attr_accessor :inputs

    def initialize(inputs)
      @inputs = inputs
      FileUtils.mkdir_p @inputs.output
      Dir.chdir @inputs.output
    end

    def extract_vars

    end

    def run
      # return some value for now
      value = 1
      Dir.chdir('../')
      value
    end

  end

end
