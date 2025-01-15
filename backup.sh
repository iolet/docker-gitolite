#!/usr/bin/sh

set eu

bundroot=/srv/backups
reporoot=/var/lib/git/repositories

workdir=$(mktemp -d)
repos=$(gitolite list-repos)
moment=$(date +%Y%m%d-%s)

echo "[${moment}] packing repos in ${reporoot}"

for repo in $repos; do

        echo -n "-> ${repo}.git..."

	cd $workdir

        # checking repo has any commit,
        # see https://stackoverflow.com/questions/5491832/how-can-i-check-whether-a-git-repository-has-any-commits-in-it
        objects=$(ls "${reporoot}/${repo}.git/objects" | wc -w)

        # skipping empty repo
        if [ $objects -le 2 ]; then
            echo "skipped"
            continue
        fi

	git clone --quiet --bare "${reporoot}/${repo}.git" > /dev/null 2>&1

        name=$(basename "$repo")

	cd "${name}.git"

	git bundle create --quiet "${name}_all.bundle" --all > /dev/null 2>&1
	git bundle verify --quiet "${name}_all.bundle" > /dev/null 2>&1

	cp "${name}_all.bundle" "${bundroot}/${name}_all_${moment}.bundle"

        echo "done"
done;

rm -rf $workdir
unset bundroot reporoot workdir repos moment
