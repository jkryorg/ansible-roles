#!/bin/sh

umask 077

YEAR="`date +%Y`"
DATE="`date +%Y-%m-%d`"

myerror()
{
    echo "Error: $*" 1>&2
    exit 1
}

archive_log()
{
    FILE="${1}"
    DEST="${2}"

    if [ -f "${DEST}" -o -f "${DEST}.gz" ]; then
        echo "Skipping ${FILE}: Archive already exists" 1>&2
    else
        echo "Archiving file ${FILE} to ${DEST}"
        mv "${FILE}" "${DEST}"
        touch "${FILE}"
        LOGS="${LOGS} ${DEST}"
    fi
}

restart_syslog()
{
    for pid in /var/run/syslogd.pid /var/run/rsyslogd.pid; do
        if [ -s "${pid}" ]; then
            kill -HUP `cat ${pid}`
            sleep 2
            return
        fi
    done
    myerror "Cannot find syslog pid file"
}

[ $# -ge 2 ] || myerror "Usage: `basename $0` <basedir> <file|dir> ..."

LOGDIR="${1}"
shift

while [ "$*" ]; do
    if [ -f "${LOGDIR}/${1}" ]; then
        dstdir=${LOGDIR}/archive/${YEAR}
        dstfile=${dstdir}/`basename ${1}`.${DATE}
        [ -d "${dstdir}" ] || mkdir -p ${dstdir}
        archive_log ${LOGDIR}/${1} ${dstfile}
    elif [ -d "${LOGDIR}/${1}" ]; then
        for f in ${LOGDIR}/${1}/*.log; do
            if [ -f "${f}" ]; then
                dstdir=${LOGDIR}/archive/${1}/${YEAR}
                dstfile=${dstdir}/`basename ${f}`.${DATE}
                [ -d "${dstdir}" ] || mkdir -p ${dstdir}
                archive_log ${f} ${dstfile}
            else
                echo "Skipping ${f}: not a file" 1>&2
            fi
        done
    else
        echo "Skipping ${1}: not a file or directory" 1>&2
    fi
    shift
done

restart_syslog

for log in ${LOGS}; do
    nice gzip -f ${log} || myerror "Error while gzipping ${log}"
    loggz="`basename ${log}`.gz"
    ( cd `dirname ${log}` && openssl sha1 -out ${loggz}.sha1 ${loggz} )
done
