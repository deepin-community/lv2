#!/bin/bash

PROG="$(basename $0)"
PYTHON="$(which python)"
CWD="$(pwd)"
WAFFILE=waf
WAFLIB=waflib


f_echo_stdout() {
    echo "$@"
}

f_echo_stderr() {
    echo "$@" >&2
}

f_quit()
{
    local \
        rc="$1" \
        stderr_msg="$2"

    [ -n "${stderr_msg}" ] && f_echo_stderr "${stderr_msg}"

    exit "${rc}"
}

f_usage() {
    f_echo_stderr "Usage: ${PROG} DIRECTORY"
    f_echo_stderr "Get rid of waf in DIRECTORY and in subdirs."
}

f_do_enter_dir() {
    [ -n "${g_old_cwd}" ] || g_old_cwd="$(pwd)"
    local l_dir="${1}"

    f_echo_stderr "Entering ${l_dir}"
    cd "${l_dir}"
}

f_do_quit_dir() {
    if [ -n "${g_old_cwd}" ]; then
        cd "${g_old_cwd}"
        rc="$?"
    else
        rc=1
    fi

    f_echo_stderr "Switching back to ${g_old_cwd}"
    return "${rc}"
}

f_waf_generate_waflib() {
    local \
        l_curdir="$(pwd)" \
        l_waflib \
        l_rc

    if [ ! -f "${WAFFILE}" ]; then
        f_echo_stderr "Couldn't find ${WAFFILE} in ${l_curdir}."
        return 1
    fi

    if [ -d "${WAFLIB}" ]; then
        f_echo_stderr "${WAFLIB} already exists."
        return 1
    fi

    "${PYTHON}" "${WAFFILE}" --help >/dev/null

    l_waflib="$(find -name ${WAFLIB} -type d)"

    mv "${l_waflib}" .
    rmdir "$(dirname ${l_waflib})"
}

f_waf_strip_blob() {
    local l_waffile="${1}"

    [ -d "${WAFLIB}" ] && sed -i '/^#==>$/,$d' "${l_waffile}"
}

f_cleanup_pyc_files() {
    find "${g_rootdir}" -name '*.pyc' -delete
}

[ "${#}" -eq 1 ] || f_quit 1 "Wrong arguments -- ${*}. See ${PROG} -h."
arg_rootdir="${1}"

g_rootdir="$(realpath ${arg_rootdir})" || f_quit 2
[ -d "${g_rootdir}" ] || f_quit 2 "${g_rootdir} is not a directory."
cd "${g_rootdir}" || f_quit 2

for waffile in $(find "${g_rootdir}" -name "${WAFFILE}") ; do
    cur_waffile_dir="$(dirname ${waffile})"
    f_do_enter_dir "${cur_waffile_dir}"
    f_waf_generate_waflib && f_waf_strip_blob "${waffile}"
    f_do_quit_dir
done

f_cleanup_pyc_files
