#!/usr/bin/env sh

##
# Remove files from the latest commit.
# The easiest way is to use `git gui`: 'Commit' => 'Amend Last Commit' => uncheck the files => 'Commit'.
##

git reset --soft HEAD~1                     # or `git reset --soft HEAD^`
git restore --staged '.lefthook-local.yml'  # or `git reset HEAD '.lefthook-local.yml'`
git commit -c ORIG_HEAD


##
# Change the default branch from 'master' to 'main'.
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
