#!/bin/sh

set -eu

bundle=${1?"bundle is required"}
prefix=${2:-"ssh://git@localhost:8022/"}

bundle=$(readlink -f "$bundle")
if [ ! -f "${bundle}" ]; then
    echo "bundle file ${bundle} does not exists, aborted"
    exit 2
fi

if [ "expr '${prefix}' : '.*/$'" ]; then
    prefix="${prefix%/}"
fi

startin=$(pwd)

echo "-> import ${bundle} ..."
remote=$(
    basename "$bundle" | sed 's!--!/!g' | \
    awk -F '_' "{printf \"${prefix}%s.git\", \$1}" | \
)

echo "+ create working directory..."
workdir=$(mktemp -d)

echo "+ enter working directory ${workdir}..."
cd "$workdir"

echo "+ clone repo as bare..."
reponame=$(basename "$bundle" | awk -F '_' '{print $1}')
git clone --bare "$bundle" "$reponame"

echo "+ entry bare repo..."
cd "${reponame}"
unset reponame

echo "+ push repo to remote..."
git push --mirror "$remote"

echo "+ leave working directory..."
cd "$startin"

echo "+ clean working directory ${workdir}..."
rm -rf "$workdir"

unset bundle prefix startin remote workdir
