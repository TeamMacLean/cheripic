$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'simplecov'
require 'coveralls'

SimpleCov.formatters = [
    SimpleCov::Formatter::HTMLFormatter,
    Coveralls::SimpleCov::Formatter
]
SimpleCov.start

require 'cheripic'

require 'stringio'
require 'minitest/autorun'
require 'minitest/reporters'
Minitest::Reporters.use! Minitest::Reporters::SpecReporter.new

require 'shoulda/context'

def delete_outdir
  if Dir.exist?('test/cheripic_results')
    if File.exist?('test/cheripic_results/selected_variants.txt')
      File.delete('test/cheripic_results/selected_variants.txt')
    end
    Dir.rmdir('test/cheripic_results')
  end
end