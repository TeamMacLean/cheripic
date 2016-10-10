# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'cheripic/version'

Gem::Specification.new do |spec|
  spec.name          = 'cheripic'
  spec.version       = Cheripic::VERSION
  spec.authors       = ['Shyam Rallapalli']
  spec.email         = ['ghanasyam.rallapalli@tsl.ac.uk']

  spec.summary       = %q{picks causative mutation from bulks segregant sequencing}
  spec.description   = %q{a library and commandline tool to pick causative mutation from bulks segregant sequencing}
  spec.homepage      = 'https://github.com/shyamrallapalli/cheripic'
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_runtime_dependency 'yell', '~> 2.0', '>= 2.0.5'
  spec.add_runtime_dependency 'trollop', '~> 2.1', '>= 2.1.2'
  spec.add_runtime_dependency 'bio', '~> 1.5', '>= 1.5.0'
  spec.add_dependency 'bio-samtools', '~> 2.4.0'
  spec.add_dependency 'bio-gngm', '~> 0.2.1'

  spec.add_development_dependency 'activesupport', '~> 4.2.6'
  spec.add_development_dependency 'bundler', '~> 1.7.6'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'minitest'
  spec.add_development_dependency 'minitest-reporters', '>= 1.0.17'
  spec.add_development_dependency 'simplecov', '~> 0.8', '>= 0.8.2'
  spec.add_development_dependency 'shoulda', '~> 3.5', '>= 3.5.0'
  spec.add_development_dependency 'coveralls', '~> 0.7', '>= 0.7.2'
end
