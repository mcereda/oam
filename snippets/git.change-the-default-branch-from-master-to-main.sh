#!/bin/sh

# sources:
# - https://stevenmortimer.com/5-steps-to-change-github-default-branch-from-master-to-main/

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
