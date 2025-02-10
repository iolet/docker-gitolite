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

awk_program=$(cat <<"EOF"
#!/usr/bin/awk -f

function date2epoch(date_string) {

    year = substr(date_string, 1, 4)
    month = substr(date_string, 6, 2)
    day = substr(date_string, 9, 2)
    hour = substr(date_string, 12, 2)
    minute = substr(date_string, 14, 2)
    second = substr(date_string, 16, 2)
    timezone_sign = substr(date_string, 18, 1)
    timezone_hour = substr(date_string, 19, 2)
    timezone_minute = substr(date_string, 21, 2)

    epoch_time = mktime(year " " month " " day " " hour " " minute " " second)
    timezone_offset = (timezone_hour * 3600) + (timezone_minute * 60)

    if (timezone_sign == "-") {
        epoch_time += timezone_offset
    }

    if (timezone_sign == "+") {
        epoch_time -= timezone_offset
    }

    return epoch_time
}

BEGIN {
    # Redefine null character as line delimiter to handing special characters
    # filename (such as spaces or newlines)
    RS = "\0";

    # Define the pattern for extracting the date part from the filename
    date_pattern = "([0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{6}[+-][0-9]{4})";
}

{
    if (! match($0, date_pattern, match_array) || match_array[1] == "") {
        next
    }

    file_epoch_time = date2epoch(match_array[1])

    if (file_epoch_time >= older_epoch_time) {
        next
    }

    printf "%s\0", $0
}
EOF
)

# Calculate the date 30 days ago in epoch time
older_epoch_time=$(date -d "-30 days" +%s)

# List all backup files and process them with awk
find "$backupdir" -type f -name '*.bundle' -print0 | \
awk -v older_epoch_time="$older_epoch_time" "${awk_program}" | \
xargs -0 -t rm -f
