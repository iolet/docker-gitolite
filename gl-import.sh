#!/bin/sh

set -eu

bundlefile=${1?"bundlefile is required"}

bundlefile=$(readlink -f "$bundlefile")
if [ ! -f "${bundlefile}" ]; then
    echo "bundle file ${bundlefile} does not exists, aborted"
    exit 2
fi

repoprefix=${2?"repoprefix is required"}

startin=$(pwd)

reponame=$(basename "$bundlefile" | awk -F '_' '{print $1}' | sed 's!\.!/!g')
echo "-> import ${reponame}.git..."

echo "+ create and enter working directory..."
workdir=$(mktemp -d)
echo "${workdir}"
cd "$workdir"

echo "+ clone work tree..."
fullname=$(basename "$bundlefile" | awk -F '_' '{print $1}')
git clone "$bundlefile" "$fullname"
cd "${fullname}"

echo "+ mirror to remote..."
git push --mirror "${repoprefix}/${reponame}"

echo "+ leave and clean working directory..."
cd "$startin"
rm -rf "$workdir"

unset bundlefile repoprefix startin reponame workdir fullname
