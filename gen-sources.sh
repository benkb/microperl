#!/bin/sh
#
# generate sources, mandatory requirements are
#   - input_dir with perl source
#   - a manifest file, which contains the selections
#
USAGE='<input_dir>'

set -u

input_dir="${1:-}"

output_dir="${2:-}"

die() {
	echo "$@" >&2
	exit 1
}

perltitle=
if [ -d "$input_dir" ]; then
	perltitle="$(basename "$input_dir")"
else
	echo "Err: please input dir"
	echo "usage: <manifest> [input dir}"
	exit 1
fi

[ -n "$output_dir" ] || output_dir='generated'

manifest_path="manifests/MANIFEST_${perltitle}"
[ -f "$manifest_path" ] || die "Err: no manifest file under '$manifest_path'"

build_path=
if [ -f "artifacts/build_${perltitle}.sh" ]; then
	build_path="artifacts/build_${perltitle}.sh"
else
	build_path="artifacts/build__default.sh"
fi

rm -rf "$output_dir"
mkdir -p "$output_dir"

if [ -f "$build_path" ]; then
	cp "$build_path" "$output_dir"/build.sh
else
	die "Err: build_path not exists in '$build_path'"
fi

makefile="$input_dir/Makefile.micro"
if [ -f "$makefile" ]; then
	perl -ple 's/^CC\s+\=.+//g' "$makefile" >"$output_dir/Makefile"
else
	echo "Err: could not file makefile '$makefile'"
	exit 1
fi

while read -r filename; do

	file="$input_dir/$filename"

	if [ -f "$file" ]; then
		[ -f "$output_dir/$filename" ] || cp "$file" "$output_dir"/
	else
		echo "Warn: could not find file '$file'"
	fi

done <"$manifest_path"

echo "OK: files written to '$output_dir'"
