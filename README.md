# Cheripic

[![Gem Version](https://badge.fury.io/rb/cheripic.svg)](https://badge.fury.io/rb/cheripic)
[![Build Status](https://travis-ci.org/shyamrallapalli/cheripic.svg?branch=master)](https://travis-ci.org/shyamrallapalli/cheripic)
[![Coverage Status](https://coveralls.io/repos/github/shyamrallapalli/cheripic/badge.svg?branch=master)](https://coveralls.io/github/shyamrallapalli/cheripic?branch=master)
[![Code Climate](https://codeclimate.com/github/shyamrallapalli/cheripic/badges/gpa.svg)](https://codeclimate.com/github/shyamrallapalli/cheripic)



Computing Homozygosity Enriched Regions In genomes to Prioritize Identification of Candidate variants (CHERIPIC), 
is a ruby tools to pick causative mutation from bulks segregant sequencing.     
        
Currently this gem is still in development and nearing complete working package.
        
        
## Installation

Cheripic is available both as a command line tool and as a gem.     
Binaries are available for Linux 64bit and OSX.      
Best way to use Cheripic is to download appropriate binary arhcive      
unpack (`tar -xzf`) and add the unpacked directory to your `PATH`       

Latest binaries are available to [download here](https://github.com/shyamrallapalli/cheripic/releases/tag/v1.1.0)       


To install gem and use the gem in your development     
Add this line to your application's Gemfile:

```ruby
gem 'cheripic'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install cheripic

## Usage

Running `cheripic` without any input at command line interface shows following help options

```

Cheripic v1.1.0
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
  -f, --assembly=<s>                                 Assembly file in FASTA format
  -F, --input-format=<s>                             bulk and parent alignment file format types - set either pileup or bam (default: pileup)
  -a, --mut-bulk=<s>                                 Pileup or sorted BAM file alignments from mutant/trait of interest bulk 1
  -b, --bg-bulk=<s>                                  Pileup or sorted BAM file alignments from background/wildtype bulk 2
  --output=<s>                                       Directory to store results, will be created if not existing (default: cheripic_results)
  --loglevel=<s>                                     Choose any one of "info / warn / debug" level for logs generated (default: debug)
  --hmes-adjust=<f>                                  factor added to snp count of each contig to adjust for hme score calculations (default: 0.5)
  --htlow=<f>                                        lower level for categorizing heterozygosity (default: 0.2)
  --hthigh=<f>                                       high level for categorizing heterozygosity (default: 0.9)
  --mindepth=<i>                                     minimum read depth to conisder a position for variant calls (default: 6)
  --min-non-ref-count=<i>                            minimum read depth supporting non reference base at each position (default: 3)
  --min-indel-count-support=<i>                      minimum read depth supporting an indel at each position (default: 3)
  --ignore-reference-n, --no-ignore-reference-n      ignore variant calls at N (completely ambigous) bases in the reference (default: true)
  -q, --mapping-quality=<i>                          minimum mapping quality of read covering the position (default: 20)
  -Q, --base-quality=<i>                             minimum base quality of bases covering the position (default: 15)
  --noise=<f>                                        praportion of reads for a variant to conisder as noise (default: 0.1)
  --cross-type=<s>                                   type of cross used to generated mapping population - back or out (default: back)
  --only-frag-with-vars, --no-only-frag-with-vars    select only contigs containing variants for analysis (default: true)
  --filter-out-low-hmes, --no-filter-out-low-hmes    ignore variants from contigs with low hmescore or bfr to list in the final output (default: true)
  --polyploidy                                       Set if the data input is from polyploids
  -p, --mut-parent=<s>                               Pileup or sorted BAM file alignments from mutant/trait of interest parent (default: )
  -r, --bg-parent=<s>                                Pileup or sorted BAM file alignments from background/wildtype parent (default: )
  --bfr-adjust=<f>                                   factor added to hemi snp frequency of each parent to adjust for bfr calculations (default: 0.05)
  --examples                                         shows some example commands with explanation

```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/shyamrallapalli/cheripic. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](contributor-covenant.org) code of conduct.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

