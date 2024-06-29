#!/bin/sh
#
# prepare the necessary file for a specific build
#
# <compiler>: systems like gcc, clang, cosmocc
#
# [compiler spec]: specifications like path or specific binary name
#
#

set -u

USAGE='<microperl> <compiler> [compiler spec]'

MICROPERL="${1:-}"

COMPILER="${2:-}"

MAKECONF_DIR='makeconf'

die (){ echo "$@" >&2; exit 1; }

[ -n "$MICROPERL" ] || die "usage: $USAGE"
[ -n "$COMPILER" ] || die "usage: $USAGE"

[ -d "$MICROPERL" ] || die "Err: microperl sourcedir not exists in '$MICROPERL'"

compiler_name=; compiler_name="$(basename "$COMPILER")"
[ -n "$compiler_name" ] || die "Err: no compiler name"

compiler_path="$(command -v  "$COMPILER")"
[ -n "$compiler_path" ] || die "Err: no compiler path"

compiler_type=
compiler_version=;  
case "$compiler_name" in
    gcc|clang|gcc-*|clang-*)
        compiler_type='gcc'
        compiler_version="$($compiler_path -dumpversion)"
        ;;
    *) compiler_type="$compiler_name" ;;
esac


hostos=; hostos="$(uname | tr '[:upper:]' '[:lower:]')"
[ -n "$hostos" ] || die "Err: could not set hostos"

arch=; arch="$(uname -p)"
[ -n "$arch" ] || die "Err: could not set arch"

conf_tuple_backup="${hostos}-${arch}"
conf_tuple="${hostos}-${arch}"

compiler_conf_triple=
while true ; do
    if [ -n "$conf_tuple" ] ; then
        for compiler_string in "${compiler_name}${compiler_version}" "$compiler_name" "$compiler_type" ; do
            if [ -f "$MAKECONF_DIR/${compiler_string}-${conf_tuple}.cc-conf" ] ; then
                compiler_conf_triple="${compiler_string}-${conf_tuple}"
                break
            fi
        done
        [ -n "$compiler_conf_triple" ] && break
        case "$conf_tuple" in
            *-*) conf_tuple="${conf_tuple%-*}" ;;
            *)  conf_tuple='' ;;
        esac
    else
        for compiler_string in "${compiler_name}${compiler_version}" "$compiler_name" "$compiler_type" ; do
            if [ -f "$MAKECONF_DIR/${compiler_string}.cc-conf" ] ; then
                compiler_conf_triple="${compiler_string}-${conf_tuple}"
                break
            fi
        done
        break
    fi
done

conf_file=
if [ -n "$compiler_conf_triple" ] ; then
    conf_file="$MAKECONF_DIR/${compiler_conf_triple}.cc-conf" 
    [ -f "$conf_file" ] || die "Err: could not find conf_file under '$conf_file'"
else
    die "Err: could define compiler conf triple"
fi

compiler_max_version=
compiler_max_version="$(perl -snle 'BEGIN{ @r=(); };
if(/^(\d+\.[\d\.]+)\:/){ push @r, $1 unless ($1 > $vers);};
END{ ($v) = sort {$b <=> $a} @r; print $v; }' -- -vers="$compiler_version" "$conf_file")"


cc_conf=; 
if [ -n "$compiler_max_version" ] ; then
    cc_conf="$(perl -ne "print \$1 if /^$compiler_max_version:\s*(.+)\s*$/" "$conf_file")"
else
    cc_conf="$(perl -ne 'print $1 if /^\s*0\s*:\s*(.+)\s*$/' "$conf_file")"
    echo "Warn: could not set max version, set 'default'"
    compiler_max_version='default'
fi

[ -n "$cc_conf" ] || die "Err: could not find cc_conf"

makefile_micro="$MICROPERL/Makefile.micro"

makefile_micro_include_name="makefile_micro.mk"
makefile_micro_include="$MICROPERL/$makefile_micro_include_name"

[ -f "$makefile_micro" ] || die "Err: makefile_micro not exists in '$makefile_micro'"
perl -ne 'BEGIN{$p}; $p=1 if /^all:[\s\t]*microperl\s$/; print if $p' "$makefile_micro" > "$makefile_micro_include"

rm -f "$makefile_micro"

echo "Ok: changed Makefile.micro to include file '$makefile_micro_include_name'"


triple_makefile_name="Makefile_${compiler_conf_triple}"
triple_makefile="$MICROPERL/$triple_makefile_name"

makefile_microperl="$MAKECONF_DIR/Makefile_$MICROPERL"

{
    echo "CC = $compiler_path" 
    echo "CC_CONF = $cc_conf"
    cat "$makefile_microperl"
    echo ''
    echo "include $makefile_micro_include_name"
} > "$triple_makefile"
echo "Ok: triple Makefile file written '$triple_makefile'"


rm -f "$MICROPERL/Makefile"
ln -s "$triple_makefile_name" "$MICROPERL/Makefile"

echo "Ok: link '$triple_makefile' to Makefile"


conf_tuple="$conf_tuple_backup"
patch_dir=
while true ; do
    if [ -n "$conf_tuple" ] ; then
        for compiler_string in  "${compiler_name}${compiler_version}" "$compiler_name" "$compiler_type"; do
            if [ -d "patches/${compiler_string}-${conf_tuple}/$MICROPERL" ] ; then
                patch_dir="patches/${compiler_string}-${conf_tuple}/$MICROPERL" 
                break
            fi
        done
        [ -n "$patch_dir" ] && break
        case "$conf_tuple" in
            *-*) conf_tuple="${conf_tuple%-*}" ;;
            *)  conf_tuple='' ;;
        esac
    else
        for compiler_string in "${compiler_name}${compiler_version}" "$compiler_name" "$compiler_type"; do
            if [ -d "patches/${compiler_string}/$MICROPERL" ] ; then
                patch_dir="patches/${compiler_string}/$MICROPERL" 
                break
            fi
        done
        break
    fi
done

[ -n "$patch_dir" ] || die "Err: could not set patch_dir"
[ -d "$patch_dir" ] || die "Err: could find set patch_dir in '$patch_dir'"


for patch_file in "$patch_dir"/*.patch ; do
    [ -f "$patch_file" ] || continue
    patch_base="${patch_file##*/}"
    perl_file="$MICROPERL/${patch_base%.*}"
    if [ -f "$perl_file" ] ; then
        echo patch "$perl_file" "$patch_file"
        patch "$perl_file" "$patch_file"
    else
        echo "Cannot patch file '$perl_file' (not found)"
    fi
done
