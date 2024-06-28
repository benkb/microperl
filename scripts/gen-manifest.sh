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

SOURCE_DIR="${1:-}"
MANIFEST_IN="${2:-}"

die() {
	echo "$@" >&2
	exit 1
}
# stamp="$(date +'%Y%m%d%H%M')"

[ -n "$SOURCE_DIR" ] || die "usage: $USAGE"
[ -d "$SOURCE_DIR" ] || die "Err: input dir not exists in '$SOURCE_DIR'"

perl_name="$(basename "$SOURCE_DIR")"

MANIFEST_IN=
manifest_out=
if [ -z "$MANIFEST_IN" ]; then
	MANIFEST_IN="manifests/MANIFEST_$perl_name.inc"
	[ -f "$MANIFEST_IN" ] || MANIFEST_IN="manifests/MANIFEST__default.inc"
	manifest_out="MANIFEST_$perl_name"
fi
[ -f "$MANIFEST_IN" ] || die "Err: no valid manifest input under '$MANIFEST_IN'"

rm -f "$manifest_out"

makefile_micro="$SOURCE_DIR/Makefile.micro"
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
		file="$SOURCE_DIR/$fileitem"
		filename="${fileitem}"
		;;
	esac

	if [ -f "$file" ]; then
		echo "$filename"
	else
		echo "Info: cannot find '$fileitem' that was detected by parsing include statements" >&2
	fi

	case "$filename" in
	*.c)
		local filebase="${filename%.*}"
		local hfile="$filebase.h"
		[ -f "$SOURCE_DIR/$hfile" ] && echo "$hfile"
		;;
	*.h)
		local filebase="${filename%.*}"
		local cfile="$filebase.c"
		[ -f "$SOURCE_DIR/$cfile" ] && echo "$cfile"
		;;
	*) ;;
	esac
}

while read -r filename; do
	print_file "$filename"
done <"$MANIFEST_IN" >"$manifest_out"

for regex in 'while ($_ =~ /([a-zA-Z0-9_]+\.h)/g) {print "$1\n"}' 'if(/\:\s*\$\(H[A-Z]*\)(.*)/){ $v=$1; $v=~ s/\s/\n/g ;  print "$v\n"; }' 'if(/\$\(_O\)\:\s+([a-zA-Z0-9_]+.c)/){ print "$1\n" }'; do
	perl -ne "$regex" "$makefile_micro" | while read filename; do
		[ -n "$filename" ] || continue
		file="$SOURCE_DIR/$filename"
		if [ -f "$file" ]; then
			echo "$file"
		else
			echo "Info: cannot find file '$filename' detected in '$makefile_micro'" >&2
		fi
	done
done | xargs perl -lne '/\#include "([a-zA-Z0-9_-]+\.[c|h])"/ && print $1; print $ARGV' | while read fileitem; do
	print_file "$fileitem"
done | sort | uniq >>"$manifest_out"

echo '------'
echo "written to '$manifest_out'"
echo "with input from '$SOURCE_DIR' and '$MANIFEST_IN'"
