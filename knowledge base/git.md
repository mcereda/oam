# Git-related useful commands

## TL;DR

```shell
# Set your identity.
git config user.name 'User Name'
git config --global user.email user@email.com

# Avoid issues when collaborating from different platforms.
git config --local core.autocrlf 'input'
git config --local core.autocrlf 'true'

# Create aliases.
git config --local alias.co checkout
git config --global alias.unstage 'reset HEAD --'

# Show git's configuration.
git config --list
git config --list --show-scope
git config --list --show-origin

# Render all current settings' values.
git config --list \
  | awk -F '=' '{print $1}' | sort -u \
  | xargs -I {} sh -c 'printf "{}=" && git config --get {}'

# Get a default value if the setting has none.
# Does not work on sections alone.
git config --get --default not-set filter.lfs.cleaned

# Create or reinitialize a repository.
git init
git init --initial-branch main path/to/repo
git init --bare path/to/repo.git

# Clone a repository.
git clone https://github.com:user/repo.git
git clone git@github.com:user/repo.git path/to/clone
git clone --recurse-submodules ssh@git.server:user/repo.git
git clone --depth 1 ssh@git.server:user/repo.git

# Unshallow a clone.
git pull --unshallow

# Get objects and refs but do not incorporate them.
git fetch

# Get changes and merge them.
git pull --all
git pull remote branch

# Show what files changed.
git status
git status --verbose

# Show changes in a repository.
git diff
git diff --staged commit
git diff commit1..commit2
git diff branch1 branch2
git diff --word-diff=color
git log -p feature --not master

# Just show changes between two files.
git diff --no-index path/to/file/a path/to/file/b

# Stage changes for commit.
git add .
git add --all
git add path/to/file

# Interactively review chunks of changes.
git add --patch path/to/file

# Commit changes.
git commit --message 'message'
git commit --message 'whatever' --gpg-sign
git commit --allow-empty --allow-empty-message
git commit --date='Jun 13 18:30:25 IST 2015'
git commit --date="$(date --date='2 days ago')"

# Edit the last commit's message.
git commit --amend
git commit --amend --message 'message'

# Change the last commit's author.
git config user.name "user name"
git config user.email user.email@mail.com
git commit --amend --reset-author

# Show commits which would be pushed.
git log @{u}..

# Revert a commit but keep the history of the event as a separate commit.
git revert commit

# Interactively rebase the last 7 commits.
git rebase -i @~7

# List remotes.
git remote --verbose

# Add a new remote.
git remote add gitlab git@gitlab.com:user/repo.git

# Push committed changes.
git push
git push remote branch1 branch2
git push git@github.com:user/repo.git
git push --all --force

# Show the repository's history.
git reflog
git log -p

# Visualize the repository's history.
git log --graph --full-history --all --color --decorate --oneline

# Remove staged and working directory changes.
git reset --hard
git reset --hard origin/main

# Go back 4 commits.
git reset --hard HEAD~4

# Remove untracked files.
git clean -f -d

# Remove ignored files.
git clean -f -d -x

# Show who committed which line.
git blame path/to/file

# List changed files in a given commit.
git diff-tree --no-commit-id --name-only -r commit

# Create patches.
git diff > file.patch
git diff --output file.patch --cached
git format-patch -5 commit
git format-patch HEAD~3 -o dir
git format-patch HEAD~2 --stdout > single.patch

# Create a full patch of the unstaged changes.
git add . && git commit -m 'uncommitted' \
  && git format-patch HEAD~1 && git reset HEAD~1

# Apply a patch to the current index.
git apply file.patch

# Apply commits from a patch.
git am file.patch

# Stash changes locally.
git stash
git stash push 'message'

# List all the stashed changes.
git stash list

# Apply the most recent change and remove them from the stash stack.
git stash pop

# Apply a stash, but don't remove it from the stack.
git stash apply stash@{6}

# Remove a single stash entry from the stash stack.
# Defaults to the current one.
git stash drop
git stash drop stash@{2}

# Remove all the stash entries.
# Those will then be pruned and may be impossible to recover.
git stash clear

# Apply only the changes made within a given commit.
git cherry-pick commit

# Create a branch.
git branch new-branch
git switch -c new-branch
git checkout -b new-local-branch remote/existing-branch

# Create a bare branch without any commits.
git checkout --orphan branch_name

# List branches.
git branch -a

# Rename a branch.
git branch --move old-name new-name

# Switch branches.
git switch branch
git checkout branch
git checkout -

# Set an existing branch to track a remote branch.
git branch -u remote/upstream-branch

# Get the current branch.
git branch --show-current         # git > v2.22
git rev-parse --abbrev-ref HEAD

# Delete local branches.
git branch --delete local-branch
git branch -D local-branch

# Delete remote branches.
git push remote :remote-branch
git push remote --delete remote-branch

# Delete both local and remote branches.
git branch --delete --remotes branch

# Sync the local branch list.
git fetch --prune

# Remove all stale branches.
git remote prune origin

# Delete branches which have been merged or are otherwise absent from a remote.
git branch --merged | grep -vE '(^\*|master|main|dev)' | xargs git branch -d
git fetch -p \
  && awk '/origin/&&/gone/{print $1}' <(git branch -vv) | xargs git branch -d

# List all tags.
git tag

# Create annotated tags.
git tag --annotate v0.1.0
git tag -as v1.2.0-r0 -m 'signed annotated tag for v1.2.0 release 0'
git tag -a 1.1.9 9fceb02

# Create lightweight tags.
git tag v0.1.1-rc0
git tag 1.12.1 HEAD

# Push specific tags.
git push origin v1.5

# Push annotated tags only.
git push --follow-tags

# Push all tags.
git push --tags

# Delete local tags.
git tag -d v1.4-lw

# Delete remote tags.
git push origin --delete v1.4-lw

# Sync the local tags list.
git fetch --prune-tags

# Rebase a branch on top of another.
git rebase main
git rebase remote/upstream-branch local-branch
git pull --rebase=interactive remote branch

# Change the date of an existing commit.
git filter-branch --env-filter \
  'if [ $GIT_COMMIT = 119f9ecf58069b265ab22f1f97d2b648faf932e0 ]
   then
     export GIT_AUTHOR_DATE="Fri Jan 2 21:38:53 2009 -0800"
     export GIT_COMMITTER_DATE="Sat May 19 01:01:01 2007 -0700"
   fi'

# Sign all commits from now on.
git config --global user.signingkey 'KEY_ID_IN_SHORT_FORMAT'
git config --local commit.gpgsign true

# Import commits from another repo.
git --git-dir=../other-repo/.git format-patch -k -1 --stdout commit | git am -3 -k

# Get the top-level directory of the current repository.
git rev-parse --show-toplevel

# Update all submodules.
git submodule update --init --recursive

# Show the first commit that has the string "cool" in its message body.
git show :/cool
```

## Configuration

```shell
# Required to be able to commit changes.
git config --local user.email 'me@me.info'
git config --local user.name 'Me'

# Avoid issues when collaborating from different platforms.
# 'input' on unix, 'true' on windows, 'false' only if you know what you are doing.
git config --local core.autocrlf 'input'

# Sign commits by default.
# Get the GPG key short ID with `gpg --list-keys --keyid-format short`.
git config --local user.signingkey 'KEY_ID_IN_SHORT_FORMAT'
git config --local commit.gpgsign true

# Pull submodules by default.
git config --global submodule.recurse true
```

To show the current configuration use the `--list` option:

```shell
git config --list
git config --list --show-scope
git config --list --global --show-origin
```

The configuration is shown in full for the requested scope (or all if not specified), but it might include the same setting multiple times if it shows up in multiple scopes.  
Render the current value of a setting using the `--get` option:

```shell
# Get the current user.name value.
git config --get user.name

# Render all current settings' values.
# Gets the settings names, then requests the current value for each.
git config --list \
  | awk -F '=' '{print $1}' | sort -u \
  | xargs -I {} sh -c 'printf "{}=" && git config --get {}'
```

## Manage changes

```shell
# Show changes relative to the current index (not yet staged).
git diff

# Show changes in the staged files only.
git diff --staged

# Show changes relative to 'commit' (defaults to HEAD if not given).
# Alias of `--staged`.
git diff --cached commit

# Show changes relative to 'branch'.
git diff branch

# Show changes between commits.
# Separating the commits with `..` is optional.
git diff commit1 commit2

# Show changes between branches.
# Separating the branches with `..` is optional.
git diff branch1 branch2

# Show a word diff using 'mode' to delimit changed words for emphasis.
# 'mode' defaults to 'plain'.
# 'mode' must be one of 'color', 'none', 'plain' or 'porcelain'.
git diff --word-diff=porcelain

# Just show changes between two files.
# DO NOT consider them part of of the repository.
# This can be used to diff any two files.
git diff --no-index path/to/file/A path/to/file/B
```

### Create a patch

Just save the output from `git diff` to get a patch file:

```shell
# Just the current changes.
# No staged nor committed files.
git diff > file.patch

# Staged files only.
git diff --output file.patch --cached
```

The output from `git diff` just shows changes to **text** files by default, no metadata or other information about commits or branches.  
To get a whole commit with all its metadata and binary changes, use `git format-patch`:

```shell
# Include 5 commits starting with 'commit' and going backwards.
git format-patch -5 commit

# Include 3 commits starting from HEAD and save the patches in 'dir'.
git format-patch HEAD~3 -o dir

# Include 2 commits from HEAD and save them as a single file.
git format-patch HEAD~2 --stdout > single.patch

# Create a full patch of the unstaged changes.
git add . && git commit -m 'uncommitted' \
  && git format-patch HEAD~1 && git reset HEAD~1
```

### Apply a patch

Use `git apply` to apply a patch file to the current index:

```shell
git apply file.patch
```

The changes from the patch are unstaged and no commits are created.  
To apply all commits from a patch, use `git am` on a patch created with `git format-patch`:

```shell
git am file.patch
```

The commits are applied one after the other and registered in the repository's logs.

## The stash stack

The _stash_ is a changelist separated from the one in the current working directory.  
`git stash` will save the current changes there and cleans the working directory. You can (re-)apply changes from the stash at any time:

```shell
# Stash changes locally.
git stash

# Stash changes with a message.
git stash save 'message'

# List all the stashed changes.
git stash list

# Apply the most recent change and remove them from the stash stack.
git stash pop

# Apply a stash, but don't remove it from the stack.
git stash apply stash@{6}
```

## Branches

### Checkout an existing remote branch

This creates a local branch tracking an existing remote branch.

```shell
$ git checkout -b local-branch remote/existing-branch
Branch 'local-branch' set up to track remote branch 'existing-branch' from 'remote'.
Switched to a new branch 'local-branch'
```

### Delete a branch

```shell
# Delete local branches.
git branch --delete local-branch
git branch -D local-branch

# Delete remote branches.
git push origin :feat-branch
git push origin --delete feat-branch

# Delete both local and remote branches.
git branch --delete --remotes feat-branch
```

## Delete branches which have been merged or are otherwise absent from a remote.

Command source [here][prune local branches that do not exist on remote anymore].

```shell
# Branches merged on the remote are tagged as 'gone' in `git branch -vv`'s output.
git fetch -p \
  && awk '/origin/&&/gone/{print $1}' <(git branch -vv) | xargs git branch -d

# Retain the current, 'master', 'main' and 'dev*' branches in all cases.
git branch --merged | grep -vE '(^\*|master|main|dev)' | xargs git branch -d
```

### Merge the master branch into a feature branch

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

### Rebase a branch on top of another

`git rebase` takes the commits in a branch and appends them on top of the commits in a different branch.
The commits to rebase are previously saved into a temporary area and then reapplied to the new branch, one by one, in order.

```shell
# Rebase main on top of the current branch.
git rebase main

# Rebase an upstream branch on top of a local branch.
git rebase remote/upstream-branch local-branch

# Rebase the current branch onto the *upstream* 'master' branch.
git pull --rebase=interactive origin master
```

## Tags

_Annotated_ tags are stored as full objects in git's database:

```shell
# Create annotated tags.
git tag --annotate v0.1.0

# Create and sign annotated tags.
git tag -as v1.2.0-r0 -m "signed annotated tag for v1.2.0 release 0"

# Tag specific commits.
git tag -a 1.1.9 9fceb02

# Push all annotated tags only.
git push --follow-tags
```

while _lightweight_ tags are stored as a pointer to a specific commit:

```shell
# Create lightweight tags.
git tag v0.1.1-rc0
git tag 1.12.1 HEAD
```

Type-generic tag operations:

```shell
# Push specific tags.
git push origin v1.5

# Push all tags
git push --tags

# Delete specific local tags only.
git tag -d v1.4-lw

# Delete specific remote tags only.
git push origin --delete v1.4-lw
```

## LFS extension

1. Install the extension:

   ```shell
   apt install git-lfs
   brew install git-lfs
   dnf install git-lfs
   pacman -S git-lfs
   ```

1. If the package manager did not enable it system-wide, enable the extension for your user account:

   ```shell
   git lfs install
   ```

   Without any options, this will only setup the "lfs" smudge and clean filters if they are not already set.

1. Configure file tracking from inside the repository:

   ```shell
   git lfs track "*.exe"
   git lfs track "enormous_file.*"
   ```

1. Add the `.gitattributes` file to the traced files:

   ```shell
   git add .gitattributes
   git commit -m "lfs configured"
   ```

## Submodules

See [Git Submodules: Adding, Using, Removing, Updating] for more information.

```shell
# Add a submodule to an existing repository.
git submodule add https://github.com/ohmyzsh/ohmyzsh lib/ohmyzsh

# Clone a repository which has submodules.
git clone --recursive keybase://public/bananas/dotfiles
git clone --recurse-submodules ohmyzsh keybase://public/bananas/dotfiles

# Update an existing repository which has submodules.
git pull --recurse-submodules
```

To delete a submodule the procedure is more complicated:

1. De-init the submodule:

   ```shell
   git submodule deinit lib/ohmyzsh
   ```

   This wil also remove its entry from `$REPO_ROOT/.git/config`.

1. Remove the submodule from the repository's index:

   ```shell
   git rm -rf lib/ohmyzsh
   ```

   This wil also remove its entry from `$REPO_ROOT/.gitmodules`.

1. Commit the changes.

## Remove a file from a commit

See [remove files from git commit].

## Remove a file from the repository

1. **Unstage** the file using `git reset`; specify HEAD as the source:

   ```shell
   git reset HEAD secret-file
   ```

1. **Remove** the file from the repository's index:

   ```shell
   git rm --cached secret-file
   ```

1. Check the file is no longer in the index:

   ```shell
   $ git ls-files | grep secret-file
   $
   ```

1. Add the file to `.gitignore` or remove it from the working directory.
1. Amend the most recent commit from your repository:

   ```shell
   git commit --amend
   ```

## Remotes

```shell
# Add a remote.
git remote add gitlab git@gitlab.com:user/my-awesome-repo.git

# Add other push urls to an existing remote.
git remote set-url --push --add origin https://exampleuser@example.com/path/to/repo1

# Change a remote.
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

## Troubleshooting

### Debug

When everything else fails, enable tracing:

```shell
export GIT_TRACE=1
```

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

[cheat.sh]: https://cheat.sh/git

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
