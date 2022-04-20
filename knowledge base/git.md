# Git-related useful commands

## TL;DR

```shell
# create a new empty repository or reinitialize an existing one
git init
git init --bare path/to/repo.git
git init --initial-branch main

# get the current status of changes
git status
git status --verbose

# check differences
git diff
git diff --staged

# add the current changes
git add .
git add path/to/file

# interactive review of chunks of changes
git add --patch

# clone with submodules in a specific folder
git clone --recurse-submodules git@github.com:user/repo.git repos/repo

# checkout a remote branch
git checkout -b local_branch origin/remote_branch

# go back to the previous branch
git checkout -

# create a commit with no changes nor message
git commit --allow-empty --allow-empty-message

# add a new remote and push to it
git remote add gitlab git@gitlab.com:user/my-awesome-repo.git
git push gitlab

# create a patch
git add . && git commit -m 'commit message' && git format-patch HEAD~1 && git reset HEAD~1
git diff > file.patch

# apply a patch
git apply file.patch

# change last commit's author
git config user.name "user name"
git config user.email user.email@mail.com
git commit --amend --reset-author

# sign all commits from now on
git config --global user.signingkey 'KEY_ID_IN_SHORT_FORMAT'
git config --local commit.gpgsign true

# working with windows fellas
git config core.autocrlf "input"  # unix
git config core.autocrlf "true"   # windows

# show the current configuration
git config --list
git config --list --show-origin

# get the top-level directory of the current repository
git rev-parse --show-toplevel

# get the current branch
git branch --show-current         # git > v2.22
git rev-parse --abbrev-ref HEAD

# list tags
git tag

# create annotated tags
# stored as full objects in git's database
git tag --annotate v0.1.0
git tag -as v1.2.0-r0 -m "signed annotated tag for v1.2.0 release 0"
git tag -a 1.1.9 9fceb02  # specific to a commit

# create lightweight tags
# stored as a pointer to a specific commit
git tag v0.1.1-rc0

# push tags
git push origin v1.5
git push --follow-tags  # all annotated tags only
git push --tags         # all tags

# delete tags
git tag -d v1.4-lw                # local only
git push origin --delete v1.4-lw  # remote only

# create an alias
git config --local alias.co checkout
git config --global alias.unstage 'reset HEAD --'

# remove merged branches
git fetch -p && awk '/origin/&&/gone/{print $1}' <(git branch -vv) | xargs git branch -d

# get a more specific diff
git diff --word-diff
git diff --word-diff=color
git diff --word-diff=porcelain
```

## Debug

When everything else fails, use this:

```shell
export GIT_TRACE=1
```

## Common configuration

```shell
# required
git config --local user.email 'me@me.info'
git config --local user.name 'Me'

# working with windows fellas
# 'input' on unix, 'true' on windows, 'false' only if you know what you are doing
git config --local core.autocrlf 'input'

# sign commits
git config --local user.signingkey 'KEY_ID_IN_SHORT_FORMAT'  # gpg --list-keys --keyid-format short
git config --local commit.gpgsign true                       # sign all commits
git commit --message "whatever" --gpg-sign                   # or -S

# pull submodules by default
git config --global submodule.recurse true
```

## Checkout a remote branch

AKA create a local branch tracking a remote branch

```shell
git checkout -b "${LOCAL_BRANCH}" "${REMOTE}/${REMOTE_BRANCH}"
```

```shell
$ git checkout -b local_branch origin/remote_branch
Branch 'local_branch' set up to track remote branch 'remote_branch' from 'origin'.
Switched to a new branch 'local_branch'
```

## Delete all branches already merged on master

Already present in `oh-my-zsh` as the `gbda` alias

Command source [here][prune local branches that do not exist on remote anymore]

```shell
git fetch -p && awk '/origin/&&/gone/{print $1}' <(git branch -vv) | xargs git branch -d
git branch --no-color --merged | command grep -vE "^(\*|\s*(master|develop|dev)\s*$)" | command xargs -n 1 git branch -d
```

```shell
for repo in $(find . -type d -name .git | awk -F '/.git' '{print $1}'); do cd ${repo}; echo "--- ${PWD##*/} ---"; gbda; cd - > /dev/null; done
```

## Sync up all repos in the current directory

```shell
for repo in $(find . -type d -name .git | awk -F '/.git' '{print $1}'); do cd ${repo}; echo "--- ${PWD##*/} ---"; git pull; cd - > /dev/null; done
```

## Merge master into a feature branch

```shell
git stash pull
git checkout master
git pull
git checkout feature
git pull
git merge --no-ff master
git stash pop
```

```shell
git checkout feature
git pull origin master
```

## Rebase a branch on top of another

`rebase` takes the commits of a branch and appends them to the commits of a different branch.
The commits to rebase are previously saved into a temporary area and then reapplied to the new branch, one by one, in order.

```shell
git rebase origin/${upstream} ${branch}
```

Rebase the current branch onto **upstream** branch `master`

```shell
git pull --rebase=interactive origin master
```

## LFS

1. install the LFS extension for git

   ```shell
   # Ubuntu
   apt install git-lfs
   ```

1. enable the extension in the repository

   ```shell
   $ cd "${REPOSITORY}"
   [repository-root]$ git install lfs
   ```

1. configure file tracking

   ```shell
   [repository-root]$ git lfs track "*.exe"
   [repository-root]$ git lfs track "enormous_file.*"
   ```

- add the `.gitattributes` file to the traced files

  ```shell
  [repository-root]$ git add .gitattributes
  [repository-root]$ git commit -m "lfs configured"
  ```

## Submodules

See [Git Submodules: Adding, Using, Removing, Updating].

- add a submodule to an existing repository:

  ```shell
  git submodule add https://github.com/ohmyzsh/ohmyzsh lib/ohmyzsh
  ```

- clone a repository with submodules:

  ```shell
  git clone --recursive keybase://public/bananas/dotfiles
  git clone --recurse-submodules ohmyzsh keybase://public/bananas/dotfiles
  ```

- update an existing repository with submodules:

  ```shell
  git pull --recurse-submodules
  ```

To delete a submodule the procedure is more complicated:

1. de-init the submodule:

   ```shell
   git submodule deinit lib/ohmyzsh
   ```

   this wil also remove the entry from `$REPO_ROOT/.git/config`

1. remove the submodule from the index:

   ```shell
   git rm -rf lib/ohmyzsh
   ```

   this wil also remove the entry from `$REPO_ROOT/.gitmodules`

1. commit the changes

## Crypt

FIXME

## Visualize the repo's history

```shell
git log --graph --full-history --all --color --decorate --oneline
```

## Remove a file from a commit

See [remove files from git commit].

## Remove a file from the repository

1. **unstage the file** using `git reset` specify the HEAD as source

   ```shell
   git reset HEAD superSecretFile
   ```

1. **remove it from the index** using `git rm` with the `--cached` option

   ```shell
   git rm --cached superSecretFile
   ```

1. check the file is no longer in the index

   ```shell
   $ git ls-files | grep superSecretFile
   $
   ```

1. add it to `.gitignore` or remove it from the disk
1. amend the most recent commit from your repository

   ```shell
   git commit --amend
   ```

## Remotes management

```shell
# add a remote
git remote add gitlab git@gitlab.com:user/my-awesome-repo.git

# add other push urls to an existing remote
git remote set-url --push --add origin https://exampleuser@example.com/path/to/repo1

# change a remote
git remote set-url origin git@github.com:user/new-repo-name.git
```

### Push to multiple git remotes with the one command

To always push to `repo1`, `repo2`, and `repo3`, but always pull only from `repo1`, set up the remote 'origin' as follows:

```shell
git remote add origin https://exampleuser@example.com/path/to/repo1
git remote set-url --push --add origin https://exampleuser@example.com/path/to/repo1
git remote set-url --push --add origin https://exampleuser@example.com/path/to/repo2
git remote set-url --push --add origin https://exampleuser@example.com/path/to/repo3
```

```plaintext
[remote "origin"]
    url = https://exampleuser@example.com/path/to/repo1
    pushurl = https://exampleuser@example.com/path/to/repo1
    pushurl = https://exampleuser@example.com/path/to/repo2
    pushurl = https://exampleuser@example.com/path/to/repo3
    fetch = +refs/heads/*:refs/remotes/origin/*
```

To only pull from `repo1` but push to `repo1` and `repo2` for a specific branch `specialBranch`:

```plaintext
[remote "origin"]
    url = ssh://git@aaa.xxx.com:7999/yyy/repo1.git
    fetch = +refs/heads/*:refs/remotes/origin/*
    ...
[remote "specialRemote"]
    url = ssh://git@aaa.xxx.com:7999/yyy/repo1.git
    pushurl = ssh://git@aaa.xxx.com:7999/yyy/repo1.git
    pushurl = ssh://git@aaa.xxx.com:7999/yyy/repo2.git
    fetch = +refs/heads/*:refs/remotes/origin/*
    ...
[branch "specialBranch"]
    remote = origin
    pushRemote = specialRemote
    ...
```

See <https://git-scm.com/docs/git-config#git-config-branchltnamegtremote>.

## Delete a branch

```shell
# locally
git branch --delete feat-branch
git branch -D feat-branch

# remote
git push origin :feat-branch
git push origin --delete feat-branch

# both
git branch --delete --remotes feat-branch
```

## Sync the branch list

```shell
git fetch --prune
```

## Sync the tags list

```shell
git fetch --prune-tags
```

## Troubleshooting

### GPG cannot sign a commit

> ```shell
> error: gpg failed to sign the data
> fatal: failed to write commit object
> ```

If gnupg2 and gpg-agent 2.x are used, be sure to set the environment variable GPG_TTY, specially zsh users with Powerlevel10k with Instant Prompt enabled.

```shell
export GPG_TTY=$(tty)
```

## Further readings

- [Get the repository's root directory]
- [How do I check out a remote Git branch] on [StackOverflow]
- [How to manage your secrets with git-crypt]
- Question about [how to rebase a local branch with remote master]
- Question about how to [merge master into a feature branch]
- Question about how to [prune local branches that do not exist on remote anymore]
- Question about how to [rebase remote branches]
- Quick guide about [git rebase][rebase quick guide]
- Quick guide about how to [remove files from git commit]
- The official [LFS website]
- [How to get the current branch name in Git?]
- [Git Submodules: Adding, Using, Removing, Updating]
- [How to add and update git submodules]
- [Is there a way to make git pull automatically update submodules?]
- [How to change a git remote]
- Git [docs]
- [Why can't I delete a branch in a remote GitLab repository?]
- [How to Delete a Git Branch Both Locally and Remotely]
- [gpg failed to sign the data fatal: failed to write commit object]
- [Able to push to all git remotes with the one command?]
- [Create a git patch from the uncommitted changes in the current working directory]
- [Is there a way to gpg sign all previous commits?]
- [Tagging]
- [10 Git tips we can't live without]
- [Coloring white space in git-diff's output]
- [Multiple git configuration]
- [How to improve git's diff highlighting?]

[docs]: https://git-scm.com/docs/git
[gitignore]: https://git-scm.com/docs/gitignore
[tagging]: https://git-scm.com/book/en/v2/Git-Basics-Tagging

[stackoverflow]: https://stackoverflow.com

[10 git tips we can't live without]: https://opensource.com/article/22/4/git-tips
[able to push to all git remotes with the one command?]: https://stackoverflow.com/questions/5785549/able-to-push-to-all-git-remotes-with-the-one-command
[coloring white space in git-diff's output]: https://stackoverflow.com/questions/5257553/coloring-white-space-in-git-diffs-output#5259137
[create a git patch from the uncommitted changes in the current working directory]: https://stackoverflow.com/questions/5159185/create-a-git-patch-from-the-uncommitted-changes-in-the-current-working-directory
[get the repository's root directory]: https://stackoverflow.com/questions/957928/is-there-a-way-to-get-the-git-root-directory-in-one-command/#957978
[git submodules: adding, using, removing, updating]: https://chrisjean.com/git-submodules-adding-using-removing-and-updating/
[gpg failed to sign the data fatal: failed to write commit object]: https://stackoverflow.com/questions/39494631/gpg-failed-to-sign-the-data-fatal-failed-to-write-commit-object-git-2-10-0
[how do i check out a remote git branch]: https://stackoverflow.com/questions/1783405/how-do-i-check-out-a-remote-git-branch/#1787014
[how to add and update git submodules]: https://devconnected.com/how-to-add-and-update-git-submodules/
[how to change a git remote]: https://careerkarma.com/blog/git-change-remote/
[how to delete a git branch both locally and remotely]: https://www.freecodecamp.org/news/how-to-delete-a-git-branch-both-locally-and-remotely/
[how to get the current branch name in git?]: https://stackoverflow.com/questions/6245570/how-to-get-the-current-branch-name-in-git#6245587
[how to improve git's diff highlighting?]: https://stackoverflow.com/questions/49278577/how-to-improve-gits-diff-highlighting#49281425
[how to manage your secrets with git-crypt]: https://dev.to/heroku/how-to-manage-your-secrets-with-git-crypt-56ih
[how to rebase a local branch with remote master]: https://stackoverflow.com/questions/7929369/how-to-rebase-local-branch-with-remote-master/#18442755
[is there a way to gpg sign all previous commits?]: https://stackoverflow.com/questions/41882919/is-there-a-way-to-gpg-sign-all-previous-commits
[is there a way to make git pull automatically update submodules?]: https://stackoverflow.com/questions/4611512/is-there-a-way-to-make-git-pull-automatically-update-submodules#49427199
[lfs website]: https://git-lfs.github.com/
[merge master into a feature branch]: https://stackoverflow.com/questions/16955980/git-merge-master-into-feature-branch
[multiple git configuration]: https://riptutorial.com/git/example/1423/multiple-git-configurations
[prune local tracking branches that do not exist on remote anymore]: https://stackoverflow.com/questions/13064613/how-to-prune-local-tracking-branches-that-do-not-exist-on-remote-anymore#17029936
[rebase quick guide]: https://medium.com/@gabriellamedas/git-rebase-and-git-rebase-onto-a6a3f83f9cce
[rebase remote branches]: https://stackoverflow.com/questions/6199889/rebasing-remote-branches-in-git/#6204804
[remove files from git commit]: https://devconnected.com/how-to-remove-files-from-git-commit/
[why can't i delete a branch in a remote gitlab repository?]: https://stackoverflow.com/questions/44657989/why-cant-i-delete-a-branch-in-a-remote-gitlab-repository#44658277
