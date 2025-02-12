#!/bin/sh

set -eu

container=${1?"container is required"}

if [ -z "${container}" ]; then
    echo "unknown container ${container}, aborted"
    exit 1
fi

if [ -z "$(podman container list --noheading --filter 'status=running' --filter \"name=^${container}\$\")" ]; then
    echo "container ${container} does not exists or stopped, aborted"
    exit 2
fi

backupdir=${2?"backupdir is required"}

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

start=$(pwd)
moment=$(date +%Y-%m-%dT%H%M%S%z)
workdir=$(mktemp -d)

prefix=$(podman exec "${container}" su - git -c 'gitolite query-rc GL_REPO_BASE')
repos=$(podman exec "${container}" su - git -c 'gitolite list-repos | grep -v gitolite-admin')

for repo in $repos; do

    echo "-> ${repo}.git..."

    cd "$workdir"

    # checking repo has any commit,
    # see https://stackoverflow.com/questions/5491832/how-can-i-check-whether-a-git-repository-has-any-commits-in-it
    # and https://unix.stackexchange.com/questions/242946/using-awk-to-sum-the-values-of-a-column-based-on-the-values-of-another-column
    # echo "cd ${prefix}/${repo}.git && git count-objects -v | awk '{ acc += \$2 } END { print acc }'"
    echo "> check objects..."
    objects=$(
        podman exec "${container}" su - git -c \
        "cd ${prefix}/${repo}.git && git count-objects -v | awk '{ acc += \$2 } END { print acc }'"
    )

    # skipping empty repo
    if [ $objects -eq 0 ]; then
        continue
    fi

    name=$(basename "$repo")

    echo "> clone to local..."
    git clone --quiet "ssh://git@localhost:8022/${repo}.git" "$name"

    cd "${name}"

    echo "> package as bundle..."
    git bundle create --quiet "${name}_all.bundle" --all

    echo "> verify local bundle..."
    git bundle verify --quiet "${name}_all.bundle"

    echo "> output bundle..."
    cp "${name}_all.bundle" "${backupdir}/${name}_all_${moment}.bundle"

done;

cd "$start" && rm -rf "$workdir"
unset backupdir container start moment workdir prefix repos
