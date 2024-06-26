#!/bin/sh
#

PERL_VERSION="${1:-}"

[ -n "$PERL_VERSION" ] || PERL_VERSION=5.10.0

die(){ echo "$@" >&2; exit 1; }

mkdir -p manifests

generated_sources='build'
perl_sources="temp/perl-$PERL_VERSION" 
manifest_file="MANIFEST_perl-$PERL_VERSION"
manifest_path="manifests/$manifest_file"

if ! [ -d "$generated_sources" ] ; then
    [ -d "$perl_sources" ] || sh ./get-sources.sh "$PERL_VERSION"
    [ -d "$perl_sources" ] || die "Err: could not download" 

	if ! [ -f "$manifest_path"  ] ; then
        sh ./gen-manifest.sh "$perl_sources"
        if [ -f "$manifest_file"  ]; then 
            echo "manifest file written int '$manifest_file'"
        else
            echo "Err: could write manifest file into '$manifest_file'" >&2
            exit 1
        fi
	    rm -f "$manifest_path"
	    mv "$manifest_file"  manifests/
    fi
    [ -f "$manifest_path"  ] || die "Err: could not gen manifest into '$manifest_path'"
   
	echo sh ./gen-sources.sh "$perl_sources"
	sh ./gen-sources.sh "$perl_sources" "$generated_sources" 
fi

[ -d "$generated_sources" ] || die "Err: could not buld sources" 

cd "$generated_sources" 
sh ./build.sh
