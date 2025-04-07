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

moment=$(date +%Y-%m-%dT%H%M%S%z)
startin=$(pwd)

reponame=$(
    printf '%s' "$repouri" | \
    sed -E 's!^\S+:([0-9]*/?|//[a-z0-9.-]*/)!!g' | \
    sed -E 's!\.git$!!g'
)
echo "-> export ${reponame}.git..."

echo "+ create and enter working directory..."
workdir=$(mktemp -d)
echo "${workdir}"
cd "$workdir"

echo "+ clone work tree..."
fullname=$(printf '%s' "$reponame" | sed 's!/!.!g')
git clone --bare "$repouri" "$fullname"
cd "${fullname}"

echo "+ package as bundle..."
git bundle create "${fullname}_all.bundle" --all

echo "+ verify bundle..."
git bundle verify "${fullname}_all.bundle"

echo "+ output bundle..."
cp "${fullname}_all.bundle" "${savedir}/${fullname}_all_${moment}.bundle"

echo "+ leave and clean working directory..."
cd "$startin"
rm -rf "$workdir"

unset repouri savedir moment startin reponame workdir fullname
