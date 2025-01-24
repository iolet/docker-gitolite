#!/bin/sh

set -eu

PERSISTS=${3:-15}

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

container=${2?"container is required"}

if [ -z "${container}" ]; then
    echo "unknown container ${container}, aborted"
    exit 1
fi

if [ -z "$(podman container list --noheading --filter 'status=running' --filter \"name=^${container}\$\")" ]; then
    echo "container ${container} does not exists or stopped, aborted"
    exit 2
fi

start=$(pwd)
moment=$(date +%Y-%m-%dT%H%M%S%z)
workdir=$(mktemp -d)

prefix=$(podman exec "${container}" su - git -c 'gitolite query-rc GL_REPO_BASE')
repos=$(podman exec "${container}" su - git -c 'gitolite list-repos | grep -v gitolite-admin')

for repo in $repos; do

    echo -n "-> ${repo}.git..."

    cd "$workdir"

    # checking repo has any commit,
    # see https://stackoverflow.com/questions/5491832/how-can-i-check-whether-a-git-repository-has-any-commits-in-it
    # and https://unix.stackexchange.com/questions/242946/using-awk-to-sum-the-values-of-a-column-based-on-the-values-of-another-column
    # echo "cd ${prefix}/${repo}.git && git count-objects -v | awk '{ acc += \$2 } END { print acc }'"
    objects=$(
        podman exec "${container}" su - git -c \
        "cd ${prefix}/${repo}.git && git count-objects -v | awk '{ acc += \$2 } END { print acc }'"
    )

    # skipping empty repo
    if [ $objects -eq 0 ]; then
        echo "skipped"
        continue
    fi

    name=$(basename "$repo")

    git clone --quiet "ssh://git@localhost:8022/${repo}.git" "$name" > /dev/null 2>&1

    cd "${name}"

    git bundle create --quiet "${name}_all.bundle" --all > /dev/null 2>&1
    git bundle verify --quiet "${name}_all.bundle" > /dev/null 2>&1

    cp "${name}_all.bundle" "${backupdir}/${name}_all_${moment}.bundle"

    prunes=$(find "${backupdir}" -type f -name "${name}_all_*.bundle" | sort -b -d -f -r | tail --lines +$(expr $PERSISTS + 1))

    if [ -n "${prunes}" ]; then
        echo "${prunes}" | xargs -d "\n" rm -f
    fi

    echo "done"
done;

cd "$start" && rm -rf "$workdir"
unset backupdir container start moment workdir prefix repos
