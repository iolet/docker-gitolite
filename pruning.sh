#!/bin/sh

backupdir=${1?"backupdir is required"}

if [ "expr '${backupdir}' : '.*/$'" ]; then
    backupdir="${backupdir%/}"
fi

if [ -z "${backupdir}" ]; then
    echo "unknown backupdir, aborted"
    exit 1
fi

if [ ! -d "${backupdir}" ]; then
    echo "backupdir ${backupdir} does not exists, aborted"
    exit 2
fi

# Calculate the date 30 days ago in epoch time
older_epoch_time=$(date -d "-30 days" +%s)

# List all backup files and process them with awk
find "$backupdir" -type f -name '*.bundle' -print0 | \
awk -v older_epoch_time="$older_epoch_time" -f pruning.awk | \
xargs -0 -t rm -f
