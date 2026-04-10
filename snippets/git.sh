#!/usr/bin/env sh

# Refer to 'knowledge base/git.md' for details.

# Configure.
git config --local 'user.email' 'jane.doe@example.com'
git config --local 'user.name' 'Jane Doe'
git config --local 'user.signingkey' 'ABCDEF01'
git config --local 'commit.gpgsign' true
git config --local 'core.autocrlf' 'input'   # 'true' on windows
git config --local 'pull.rebase' false
git config --list --show-scope
git config --get 'init.defaultBranch'
git config --get --default 'not-set' 'filter.lfs.cleaned'
git config -C '../other-repo' --get 'init.defaultBranch'

# Initialize repositories.
git init --initial-branch 'main'

# Clone existing repositories.
git clone --recurse-submodules 'git@github.com:example/webapp.git'
git clone --depth '1' 'https://github.com/go-gitea/gitea' --branch 'release/v1.22'
git clone 'https://gitlab-ci-token:glpat-0123…wxyz@gitlab.example.org/team/api.git'

# Manage remotes.
git remote add 'github' 'git@github.com:user/webapp.git'
git remote add 'gitlab' 'git@gitlab.com:user/webapp.git'
git remote set-url --push --add 'origin' 'git@github.com:user/webapp.git'
git remote | xargs -n 1 git push

# Pull changes.
git pull
git pull 'gitlab' 'main'

# Show changes.
git status
git diff
git diff --staged

# Manage branches.
git branch -a
git branch --list --remote 'origin/*' | cut -d'/' -f'2'
git branch --move 'feat/login' 'feat/oauth-login'
git checkout -b 'feat/api-v2' 'origin/feat/api-v2'
git fetch --prune
git branch --merged | grep -vE '(^\*|master|main|dev)' | xargs git branch -d
git switch 'main'
git checkout -
git branch --delete 'feat/login'
git push 'origin' --delete 'feat/login'

# Stage changes.
git add '.'
git add --patch '.gitignore'

# Commit changes.
git commit --message 'feat: initial commit'
git commit --allow-empty -m "test: verify CI trigger"
git commit --amend --reset-author
git commit --no-verify -m 'fix: emergency patch'

# Push committed changes.
git push --set-upstream 'origin' 'feat/add-soap'

# Check the history.
git log --oneline
git log --graph --full-history --all --color --decorate --oneline
git log --show-signature -1
git log --show-signature --format="  %h %s%n  Author: %an <%ae>"
git log @{u}..
git reflog

# Create tags.
git tag --annotate 'v0.1.0'
git tag -as 'v1.2.0-r0' -m 'signed annotated tag for v1.2.0 release 0'
git push --follow-tags
git fetch --prune-tags

# Create patches.
git format-patch -n HEAD^
git format-patch HEAD^ -o './patchDir'
git format-patch HEAD~1 --stdout
git format-patch -5 '3918a1d'
git format-patch 'HEAD~3' -o './patches'
git format-patch 'HEAD~2' --stdout > 'patches/combined.patch'
git format-patch -1 '3918a1d036e74d47a5c830e4bbabba6f507162b1'

# Apply patches.
git apply --check 'path/to/patchFile.patch'
git apply 'patchDir/patchFile.patch'
git am 'patchDir/patchFile.patch'

# Replay commits in the current branch.
git rebase -i '@~7'  # the last seven
git rebase --root    # from the beginning
git rebase --exec "git commit --amend --no-edit -S"  # do something after every commit

# Rebase the currently checked out branch on top of 'master'.
git rebase 'master'

# Rebase the 'server' branch on top of 'master' (no need to switch).
git rebase 'master' 'server'

# Replay on top of 'master' the changes in 'client' since it diverged from
# 'server' (no need to switch).
git rebase --onto 'master' 'server' 'client'

# Manage the stash.
git stash
git stash list
git stash pop
git stash apply stash@{6}
git stash drop
git stash push -m 'work in progress'

# Remove files not under version control.
git clean -f -d
git clean -f -d -x

# Get the top-level directory of the current repository.
git rev-parse --show-toplevel

# Revert a commit, keeping it in the history.
git revert 'commit_hash'

# Apply changes from a specific commit.
git cherry-pick 'commit_hash'

# Show who committed which line.
git blame 'path/to/file'

# Discard all local changes.
git reset --hard
git reset --hard 'origin/main'

# List remotes with URLs.
git remote --verbose

# Manage large files.
git lfs pull

# Manage submodules.
git submodule update --init --recursive

# Change author for multiple commits.
git rebase --interactive --rebase-merges --exec 'git commit --amend --reset-author --no-edit' '3918a1d0'


##
# Remove files from the latest commit.
# --------------------------------------
# Using `git gui`:
#   'Commit' => 'Amend Last Commit' => uncheck the files => 'Commit'
##

git reset --soft HEAD~1                     # or `git reset --soft HEAD^`
git restore --staged '.lefthook-local.yml'  # or `git reset HEAD '.lefthook-local.yml'`
git commit -c ORIG_HEAD


##
# Change the default branch from 'master' to 'main'.
# --------------------------------------
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

git remote add 'upstream' 'https://github.com/original/repo.git'
git fetch 'upstream'
git checkout 'master'
git reset --hard 'upstream/master'
git push 'origin' 'master' --force


###
# Pull and accept forced updates without merging or rebasing
# ---------------------------------------------
# 1. download updates from the remote without trying to merge or rebase
# 2. [if needed] backup the current branch
# 3. reset the branch to the updates fetched just now
###

git fetch --all
git branch 'backup-main'
git reset --hard 'origin/main'


###
# Re-sign all commits after a GPG key rotation
# ------------------
# rebase from the first commit and force re-signing
# pick up the current user.name/user.email from git config (--reset-author)
#
# only works cleanly if there's no remote to diverge from
###

git commit --allow-empty -m "test: verify new signing key"
git log --oneline --show-signature -1
git rebase --root --exec "git commit --amend --no-edit --reset-author -S"
git log --show-signature --format="  %h %s%n  Author: %an <%ae>"
