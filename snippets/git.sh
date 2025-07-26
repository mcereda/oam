#!/usr/bin/env sh

git init --initial-branch 'main'

git config --get 'init.defaultBranch'
git config -C 'repos/test' --get 'init.defaultBranch'

git config --local 'user.email' 'example.user@gmail.com'
git config --local 'user.name' 'Example User'
git config --local 'user.signingkey' 'ABCDEF01'
git config --local 'commit.gpgsign' true
git config --local 'pull.rebase' false

git clone --recurse-submodules 'git@github.com:example/ansible-role-keychron-capable.git'
git clone 'https://gitlab-ci-token:glpat-01234567ABCDEFGHijkl@gitlab.example.org/testProj/myRepo.git'
git clone 'https://github.com/go-gitea/gitea' -b 'release/v1.22'

git branch --list --remote 'origin/*' | cut -d/ -f2

git pull
git pull 'gitlab' 'main'

git add '.'
git add -p '.gitignore'

git commit --message 'feat: initial commit'

git push --set-upstream 'origin' 'feat/add-soap'

git remote add 'github' 'git@github.com:example/ansible-role-keychron-capable.git'
git remote add 'gitlab' 'git@gitlab.com:sample/ansible-role-keychron-capable.git'

git remote set-url --push --add 'origin' 'git@github.com:example/ansible-role-keychron-capable.git'

git remote | xargs -n 1 git push

git lfs pull

# Recursively remove files not under version control.
git clean -df

# Get the top-level directory of the current repository.
git rev-parse --show-toplevel

# create patches from the last commit
git format-patch -n HEAD^
git format-patch HEAD^ -o './patchDir'
git format-patch HEAD~1 --stdout

# create patches from specific commits
git format-patch -1 '3918a1d036e74d47a5c830e4bbabba6f507162b1'

# apply patches
git apply 'patchDir/patchFile.patch'

# Change author information for multiple commits.
git rebase --interactive --rebase-merges --exec 'git commit --amend --reset-author --no-edit' '3918a1d0'


##
# Remove files from the latest commit.
# --------------------------------------
# The easiest way is to use `git gui`: 'Commit' => 'Amend Last Commit' => uncheck the files => 'Commit'.
##

git reset --soft HEAD~1                     # or `git reset --soft HEAD^`
git restore --staged '.lefthook-local.yml'  # or `git reset HEAD '.lefthook-local.yml'`
git commit -c ORIG_HEAD


##
# Change the default branch from 'master' to 'main'.
# --------------------------------------
# Source: https://stevenmortimer.com/5-steps-to-change-github-default-branch-from-master-to-main/
##

# create main branch locally, taking the history from master
git branch --move 'master' 'main'

# push the new local main branch to the remote repo (GitHub)
git push --set-upstream 'origin' 'main'

# switch the current HEAD to the main branch
git symbolic-ref 'refs/remotes/origin/HEAD' 'refs/remotes/origin/main'

# change the default branch on GitHub to main
# https://docs.github.com/en/github/administering-a-repository/setting-the-default-branch

# delete the master branch on the remote
git push origin --delete 'master'

###
# Take actions on multiple repositories
# --------------------------------------
###

git-all () {
	[[ -n $DEBUG ]] && set -o xtrace

	local COMMAND
	local FOLDERS=()
	for (( I = $# ; I >= 0 ; I-- )); do
		if [[ -d ${@[$I]} ]]; then
			FOLDERS+=${@[$I]}
		else
			COMMAND="${@[1,-$((${#FOLDERS}+1))]}"
			break
		fi
	done
	if [[ -z "$COMMAND" ]]; then
		echo "error: no command given" >&2
		return
	fi
	local REPOSITORIES=( $(find ${FOLDERS[@]:-'.'} -type d -name .git -exec dirname '{}' \;) )

	parallel --color-failed --tagstring "{/}" "git -C {} $COMMAND" ::: ${REPOSITORIES[@]}
	# echo -n ${REPOSITORIES[@]} | xargs -d ' ' -tP 0 -I git -C "{}" $(echo ${COMMAND[@]})  # xargs, linux
	# echo -n ${REPOSITORIES[@]} | xargs -n 1 -P 0 -I {} git -C "{}" $(echo ${COMMAND[@]})  # xargs, osx
	# for REPOSITORY in ${REPOSITORIES[@]}; do echo -e "\n\n---\n${REPOSITORY}"; git -C "$REPOSITORY" "$COMMAND"; done

	[[ -n $DEBUG ]] && set +o xtrace
}


###
# Reset forks to their upstream's state
# --------------------------------------
###

git remote add 'upstream' '/url/to/original/repo'
git fetch 'upstream'
git checkout 'master'
git reset --hard 'upstream/master'
git push 'origin' 'master' --force
