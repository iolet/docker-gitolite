#! /usr/bin/awk -f

BEGIN {
    FS = "[ :]"
}

/^FROM\s*/ {
    print $2
}
