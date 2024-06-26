#!/bin/sh
#
#
# input: version number, file to download , or entire url
#
USAGE='<ver.sion.nr>|<perlname-version.tar.gz>|<http:*url*.tar.gz>'

input="${1:-}"

version_default=5.10.0
url_default='https://www.cpan.org/src/5.0'

die() {
	echo "$@" >&2
	exit 1
}

[ -n "$input" ] || input="$version_default"

##### downloading stuff
#
perl_tarfile=
perl_url=
case "$input" in
http*.tar.gz | ftp*.tar.gz)
	perl_url="$input"
	perl_tarfile="$(basename "$input")"
	;;
*[a-z]*.tar.gz | *[A-Z]*.tar.gz) perl_tarfile="$input" ;;
[0-9]*.[0-9]*.[0-9]*) perl_tarfile="perl-${input}.tar.gz" ;;
*) die "Err wrong version format, $USAGE" ;;
esac

[ -n "$perl_url" ] || perl_url="$url_default/$perl_tarfile"

command -v wget >/dev/null || die "Err: wget not installed"

mkdir -p temp

perl_tarpath="temp/$perl_tarfile"
if [ -f "$perl_tarpath" ]; then
	echo "perl tarfile already downloaded under '$perl_tarpath'"
else
	wget -q "$perl_url" -O /dev/null || die "Err: invalid url '$perl_url'"
	wget --directory-prefix=temp "$perl_url"
	echo "perl tarfile downloaded under '$perl_tarpath'"
fi

if ! [ -f "$perl_tarpath" ]; then
	die "Err: could not download file '$perl_url'"
fi

perl_tarname="${perl_tarfile%.*}"
perl_name="${perl_tarname%.*}"

perl_sourcedir="temp/$perl_name"

if [ -d "$perl_sourcedir" ]; then
	echo "perl source dir already exists in '$perl_sourcedir'"
else
	echo "unpacking '$perl_tarpath'"
	tar -xf "$perl_tarpath" -C temp
fi
