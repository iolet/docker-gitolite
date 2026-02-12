#!/bin/sh

set -eu

repouri=${1?"repouri is required"}
savedir=${2?"savedir is required"}

if [ "expr '${savedir}' : '.*/$'" ]; then
    savedir="${savedir%/}"
fi

if [ -z "${savedir}" ]; then
    echo "unknown savedir, aborted"
    exit 1
fi

if [ ! -d "${savedir}" ]; then
    echo "savedir ${savedir} does not exists, aborted"
    exit 2
fi

moment=$(date +%y%m%d%H%M%S --utc)
startin=$(pwd)

echo "-> export ${repouri} ..."
reponame=$(
    printf '%s' "$repouri" | \
    sed -E 's!^\S+:([0-9]*/?|//[a-z0-9.-]*/)!!g' | \
    sed -E 's!\.git$!!g' | sed 's!/!--!g'
)

workdir=$(mktemp -d)
echo "+ create working directory ${workdir}..."

echo "+ enter working directory..."
cd "$workdir"

echo "+ clone repo as bare..."
git clone --bare "$repouri" "$reponame"

echo "+ entry bare repo..."
cd "${reponame}"

echo "+ package bundle..."
git bundle create "${reponame}_all.bundle" --all

echo "+ verify bundle..."
git bundle verify "${reponame}_all.bundle"

echo "+ output bundle..."
cp "${reponame}_all.bundle" "${savedir}/${reponame}_all_${moment}.bundle"

echo "+ leave working directory..."
cd "$startin"

echo "+ clean working directory ${workdir}..."
rm -rf "$workdir"

unset repouri savedir moment startin reponame workdir
