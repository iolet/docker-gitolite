#!/bin/sh

set -eu

bundroot=${1:?'target is required'}

if [[ "${bundroot}" =~ \S*/$ ]]; then
        bundroot="${bundroot%/}"
fi

if [ ! -n "${bundroot}" ]; then
        echo "unknown target, aborted"
        exit 1
fi

if [ ! -d "${bundroot}" ]; then
        echo "target ${bundroot} does not exists, aborted"
        exit 2
fi

start=$(pwd)
moment=$(date +%Y-%m-%dT%H:%M:%S%z)
workdir=$(mktemp -d)
reporoot=$(gitolite query-rc GL_REPO_BASE)

echo "persisting repos to ${bundroot} at ${moment}"

repos=$(gitolite list-repos)
for repo in $repos; do

        echo -n "-> ${repo}.git..."

	cd "$workdir"

        # checking repo has any commit,
        # see https://stackoverflow.com/questions/5491832/how-can-i-check-whether-a-git-repository-has-any-commits-in-it
        # and https://unix.stackexchange.com/questions/242946/using-awk-to-sum-the-values-of-a-column-based-on-the-values-of-another-column
        objects=$(cd "${reporoot}/${repo}.git" && git count-objects -v | awk '{ acc += $2 } END { print acc }')

        # skipping empty repo
        if [ $objects -eq 0 ]; then
            echo "skipped"
            continue
        fi

	git clone --quiet --bare "${reporoot}/${repo}.git" > /dev/null 2>&1

        name=$(basename "$repo")

	cd "${name}.git"

	git bundle create --quiet "${name}_all.bundle" --all > /dev/null 2>&1
	git bundle verify --quiet "${name}_all.bundle" > /dev/null 2>&1

	cp "${name}_all.bundle" "${bundroot}/${name}_all_${moment//:/-}.bundle"

        echo "done"
done;

cd "$start" && rm -rf "$workdir"
unset bundroot start moment workdir reporoot repos
