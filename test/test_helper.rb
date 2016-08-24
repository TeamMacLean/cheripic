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
  if File.exist?('cheripic_results_selected_hme_variants.txt')
    File.delete('cheripic_results_selected_hme_variants.txt')
  end
  if File.exist?('cheripic_results_selected_bfr_variants.txt')
    File.delete('cheripic_results_selected_bfr_variants.txt')
  end
end