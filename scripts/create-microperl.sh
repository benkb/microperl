#!/bin/sh
#
# generate sources, mandatory requirements are
#   - INPUT_DIR with perl source
#   - a manifest file, which contains the selections

USAGE='[-m|--manifest manifest] <INPUT_DIR> [output_dir]'

set -u

die() {
	echo "$@" >&2
	exit 1
}

INPUT_DIR=
manifest_path=
while [ $# -gt 0 ] ; do
    case "$1" in
        -m|--manifest)
            manifest_path="${2:-}"
            [ -n "$manifest_path" ] || die "Err: no manifest_path"
            shift
            ;;
        -*) die "usage: $USAGE" ;;
        *) 
            INPUT_DIR="${1}"
            shift
            break 
            ;;
    esac
    shift
done

[ -d "$INPUT_DIR" ] || die "Err: no inputdir , usage: $USAGE"

output_dir="${1:-}"

perltitle=; perltitle="$(basename "$INPUT_DIR")"

[ -z "$manifest_path" ] && manifest_path="manifests/MANIFEST_${perltitle}"
[ -f "$manifest_path" ] || die "Err: no manifest file under '$manifest_path'"

manifest_filename=; manifest_filename="$(basename "$manifest_path")"

manifest_perltitle=
case "$manifest_filename" in
    MANIFEST_*) manifest_perltitle="${manifest_filename#*_}";;
    *) die "Err: manifest filename looks invalid '$manifest_filename'" ;;
esac

if [ "$perltitle" != "$manifest_perltitle" ] ; then
    die "title from and manifest and input dir are different: '$perltitle'/'$manifest_perltitle'"
fi

case "$perltitle" in
    perl-*[0-9]*) : ;;
    *) die "Err: perltitle looks invalid '$perltitle'" ;;
esac

output_dir="$PWD/micro$perltitle"

rm -rf "$output_dir"
mkdir -p "$output_dir"


while read -r filename; do

	file="$INPUT_DIR/$filename"

	if [ -f "$file" ]; then
		[ -f "$output_dir/$filename" ] || cp "$file" "$output_dir"/
	else
		echo "Warn: could not find file '$file'"
	fi

done <"$manifest_path"


cd "$output_dir"
## fix file permissions
find "$output_dir"  -type d -print0 | xargs -0 -I{}  chmod 0755 {}

find "$output_dir" -type f -print0 | xargs -0 -I{} chmod 0644 {}


echo "OK: files written to '$output_dir'"
