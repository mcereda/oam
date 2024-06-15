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
