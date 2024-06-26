#!/bin/sh
#
# prints a file list for building microperl
#
# <source dir> : directory with perl sources
#
# [manifest input] : explicitely define manifest input, otherwise
#                   its deferd from the source dir
#

set -u

USAGE='<source dir> [manifest input]'

source_dir="${1:-}"
manifest_in="${2:-}"

die() {
	echo "$@" >&2
	exit 1
}
# stamp="$(date +'%Y%m%d%H%M')"

[ -n "$source_dir" ] || die "usage: $USAGE"
[ -d "$source_dir" ] || die "Err: input dir not exists in '$source_dir'"

perl_name="$(basename "$source_dir")"

manifest_in=
manifest_out=
if [ -z "$manifest_in" ]; then
	manifest_in="artifacts/MANIFEST_$perl_name.in"
	[ -f "$manifest_in" ] || manifest_in="artifacts/MANIFEST__default.in"
	manifest_out="MANIFEST_$perl_name"
fi
[ -f "$manifest_in" ] || die "Err: no valid manifest input under '$manifest_in'"

rm -f "$manifest_out"

makefile_micro="$source_dir/Makefile.micro"
[ -f "$makefile_micro" ] || die "Err: makefile_micro not exists in '$makefile_micro'"

print_file() {
	local fileitem="${1:-}"
	if [ -z "$fileitem" ]; then
		echo "Err: no fileitem"
		exit 1
	fi
	local filename=
	local file=
	case "$fileitem" in
	*/*)
		file="$fileitem"
		filename="${fileitem##*/}"
		;;
	*)
		file="$source_dir/$fileitem"
		filename="${fileitem}"
		;;
	esac

	if [ -f "$file" ]; then
		echo "$filename"
	else
		echo "Warn: cannot find '$file'" >&2
	fi

	case "$filename" in
	*.c)
		local filebase="${filename%.*}"
		local hfile="$filebase.h"
		[ -f "$source_dir/$hfile" ] && echo "$hfile"
		;;
	*.h)
		local filebase="${filename%.*}"
		local cfile="$filebase.c"
		[ -f "$source_dir/$cfile" ] && echo "$cfile"
		;;
	*) ;;
	esac
}

while read -r filename; do
	print_file "$filename"
done <"$manifest_in" >"$manifest_out"

for regex in 'while ($_ =~ /([a-zA-Z0-9_]+\.h)/g) {print "$1\n"}' 'if(/\:\s*\$\(H[A-Z]*\)(.*)/){ $v=$1; $v=~ s/\s/\n/g ;  print "$v\n"; }' 'if(/\$\(_O\)\:\s+([a-zA-Z0-9_]+.c)/){ print "$1\n" }'; do
	perl -ne "$regex" "$makefile_micro" | while read filename; do
		[ -n "$filename" ] || continue
		file="$source_dir/$filename"
		if [ -f "$file" ]; then
			echo "$file"
		else
			echo "Warn could not find file '$file' for filename '$filename'" >&2
		fi
	done
done | xargs perl -lne '/\#include "([a-zA-Z0-9_-]+\.[c|h])"/ && print $1; print $ARGV' | while read fileitem; do
	print_file "$fileitem"
done | sort | uniq >>"$manifest_out"

echo '------'
echo "written to '$manifest_out'"
echo "with input from '$manifest_in'"
