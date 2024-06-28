#!/bin/sh
#
#
# input: version number, file to download , or entire url
#
# output: stuff is downloaded and unpacked into $PWD/downloads
#

USAGE='<url> [filename]'


set -u

INPUT_URL="${1:-}"
INPUT_FILENAME="${2:-}"

DOWNLOAD_DIR="$PWD/downloads"


die() {
	echo "$@" >&2
	exit 1
}

[ -n "$INPUT_URL" ] || die "usage: $USAGE"

case "$INPUT_URL" in
    http* | ftp*) : ;;
    *) die "Err: input does not look like url" ;;
esac


check_extension(){

    local match=
    for arg in $@ ; do
        case "$arg" in
            *.tar.gz|*.zip)
                [ -z "$match" ] || die "Err: either url or filename should match" 
                match=1
                ;;
            *)
        esac
    done
    [ -z "$match" ] && die "Err: input contains not a compressed file"
}

filename=
fileurl=
if [ -n "$INPUT_FILENAME" ] ; then
    check_extension "$INPUT_URL" "$INPUT_FILENAME"
    filename="$INPUT_FILENAME"
    fileurl="$INPUT_URL/$INPUT_FILENAME"
else
    check_extension "$INPUT_URL"
    filename="$(basename "$INPUT_URL")"
    fileurl="$INPUT_URL"
fi

[ -n "$filename" ] || die "Err: could not set filename"


command -v wget >/dev/null || die "Err: wget not installed"

mkdir -p "$DOWNLOAD_DIR"

compressed_file_path="$DOWNLOAD_DIR/$filename"
if [ -f "$compressed_file_path" ]; then
	echo "perl tarfile already downloaded under '$compressed_file_path'"
else
	wget -q "$fileurl" -O /dev/null || die "Err: invalid url '$fileurl'"
	wget --directory-prefix=downloads "$fileurl"
	echo "perl tarfile downloaded under '$compressed_file_path'"
fi

if ! [ -f "$compressed_file_path" ]; then
	die "Err: could not download file '$fileurl'"
fi

filetitle=
case "$filename" in
    *.zip) filetitle="${filename%.*}" ;;
    *.tar.gz)
        tarname="${filename%.*}"
        filetitle="${tarname%.*}" 
        ;;
    *) die "Err: not suppoted filename '$filename'";;
esac


downloads_output="downloads/$filetitle"

if [ -d "$downloads_output" ] ; then
    echo "There is alreay a directory in '$downloads_output'"
    exit
else
    mkdir -p "$downloads_output"
fi

echo "unpacking '$filename'"

case "$filename" in
    *.zip) 
        echo unzip "$compressed_file_path" -d "$downloads_output"
        unzip "$compressed_file_path" -d "$downloads_output"
        ;;
    *.tar.gz) 
        echo tar -xf "$compressed_file_path" -C "downloads" 
        tar -xf "$compressed_file_path" -C "downloads" ;; 
    *) die "Err: not suppoted filename '$filename'";;
esac
