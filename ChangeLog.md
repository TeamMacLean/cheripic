### Change Log

All significant changes to this project at each release are documented in this file.


#### Future changes to include
    
    1. option to take multiple background pileup files

#### [1.2.6] - 2016-10-26

    1. option to run only using with vcf files as bulk inputs to increase speed of analysis for larger genomes

#### [1.2.5] - 2016-10-17

    1. Updated methods take bam file (along with a vcf file) or pileup file as inputs of bulks
    2. Replaced output directory with output file name tag, since we only write to one file

#### [1.2.0] - 2016-08-11

    1. fixed calculation of heterzygosity for background bulks
    2. changed command line boolean option to be set using only true or false
    3. included command line option to set length of sequnce to retireve on either side of each variant
     
    
#### [1.1.0] - 2016-07-26

    first release of the binaries for Linux 64 bit and OSX 64bit
