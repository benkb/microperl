# Microperl


This is an attempt to maintain a minimal version of Perl.

## Goals

Beeing able to carve out a subset of files of an existing Perl version without
keeping a separate source tree.

Trying to keep the build system as simple as possible.

## Quick start

On the command line:

```
git clone https://github.com/benkb/microperl
cd microperl
make 
```

If everything runs fine you then have a new directory called 'microsrc'. 
So you then can edit and run the build.sh file inside 'microsrc'

```
cd microsrc
sh ./build.sh
```

build.sh is wrapper script for the Makefile in microsrc


## Manifests

Files like ' MANIFEST_perl-5.10.0' are the driver for the creation of the
'microsrc' directory because they contain all the files needed from the Perl
source tree

The files can be created with the script `gen-manifest.sh` 

```
sh ./gen-manifest.sh perlsrc/perl-5.10.0
mv MANIFEST_perl-5.10.0 manifests
```

## microsrc

The 'microsrc' is the thing with want. It contains:

- all the source files needed for microperl, comming from (big) Perl
- a Makefile
- a wrapper 'build.sh' file


## Directories

- patches

- manifests: contain all the generated manifests

- includes:  files that are used during gen-manifest.sh and create-gensrc.sh

- perlsrc: temporary cache for downloaded perl sourcess

- microsrc: temporarely created directory with sources for microperl



## Files

- Makefile:           contains basic tasks for those scripts

- downloader.sh:    utility to download and unpack packages

                    MANIFEST file

- gen-manifest.sh:    generate a manifest file from an existing Perl sourcetree, 
                    where it basically takes the Makefile.micro file apart

- populate-microsrc.sh: create the microsrc directory with the help of a 


- microsrc-genesis.sh:  create the microsrc directory from scratch


- LICENSE: GPL, because this is mentioned here https://dev.perl.org/licenses/


## Links

- https://www.cpan.org/src/5.0/
- https://www.cpan.org/src/
