require 'bundler/gem_tasks'
require 'rake/testtask'
# For Bundler.with_clean_env
require 'bundler/setup'

Rake::TestTask.new(:test) do |t|
  t.libs << 'test'
  t.libs << 'lib'
  t.test_files = FileList['test/**/*_test.rb']
end

task :default => :test


# for packaging

PACKAGE_NAME = 'cheripic'
VERSION = `bundle exec bin/cheripic -v`.chomp
TRAVELING_RUBY_VERSION = '20150210-2.1.5'

# pre-downloaded travelling ruby from following links and placed them in 'packaging' dirctory
# http://d6r77u77i8pq3.cloudfront.net/releases/traveling-ruby-20150210-2.1.5-linux-x86_64.tar.gz
# http://d6r77u77i8pq3.cloudfront.net/releases/traveling-ruby-20150210-2.1.5-osx.tar.gz

desc 'Package your app'
task :package => %w(package:linux:x86_64 package:osx)

namespace :package do

  namespace :linux do
    desc 'Package your app for Linux x86_64'
    task :x86_64 => [:bundle_install, "packaging/traveling-ruby-#{TRAVELING_RUBY_VERSION}-linux-x86_64.tar.gz"] do
      create_package('linux-x86_64')
    end
  end

  desc 'Package your app for OS X'
  task :osx => [:bundle_install, "packaging/traveling-ruby-#{TRAVELING_RUBY_VERSION}-osx.tar.gz"] do
    create_package('osx')
  end

  desc 'Install gems to local directory'
  task :bundle_install do
    if RUBY_VERSION !~ /^2\.1\./
      abort "You can only 'bundle install' using Ruby 2.1, because that's what Traveling Ruby uses."
    end
    sh 'rm -rf packaging/tmp'
    sh 'mkdir packaging/tmp'
    sh 'cp Gemfile.lock packaging/tmp/'
    sh 'cp packaging/Gemfile packaging/tmp/'
    Bundler.with_clean_env do
      sh 'env BUNDLE_IGNORE_CONFIG=1 bundle install --path packaging/vendor --without development'
    end
    sh 'rm -rf packaging/tmp'
    sh 'rm -f packaging/vendor/*/*/cache/*'
  end
end

def create_package(target)
  package_dest = "#{PACKAGE_NAME}-#{VERSION}-#{target}"
  package_dir = "packaging/#{package_dest}"
  sh "rm -rf #{package_dir}"
  sh "mkdir #{package_dir}"
  sh "mkdir -p #{package_dir}/lib/app/bin"
  sh "cp bin/cheripic #{package_dir}/lib/app/bin/"
  sh "cp -R lib #{package_dir}/lib/app/"
  sh "unzip test/data/test_data.zip -d #{package_dir}/"
  sh "mkdir #{package_dir}/lib/app/ruby"
  sh "tar -xzf packaging/traveling-ruby-#{TRAVELING_RUBY_VERSION}-#{target}.tar.gz -C #{package_dir}/lib/app/ruby"
  sh "cp packaging/wrapper.sh #{package_dir}/cheripic"
  sh "cp -pR packaging/vendor/ruby/2.1.0 #{package_dir}/lib/app/ruby/"
  sh "cp packaging/cheripic.gemspec Gemfile Gemfile.lock LICENSE.txt #{package_dir}/lib/app/"
  sh "mkdir #{package_dir}/lib/app/.bundle"
  sh "cp packaging/bundler-config #{package_dir}/lib/app/.bundle/config"
  if target == 'linux-x86_64'
    sh "cp -p packaging/linux-x86_64_samtools/external/* packaging/cheripic-#{VERSION}-linux-x86_64/lib/app/ruby/2.1.0/gems/bio-samtools-2.4.0/lib/bio/db/sam/external/"
  end
  unless ENV['DIR_ONLY']
    Dir.chdir('packaging') do
      sh "gtar -czf #{package_dest}.tar.gz #{package_dest}"
    end
  end
end
