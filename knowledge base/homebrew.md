# Homebrew

## TL;DR

```sh
# Install/uninstall on OS X.
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/uninstall.sh)"

# Search for formulae.
brew search parallel
brew search --cask gpg

# Install something.
brew install gettext
brew install --cask spotify

# Uninstall something
brew uninstall --zap keybase

# Get formulae's dependencies.
brew deps
brew deps --installed azure-cli
brew deps --tree

# Get information on formulae.
brew info sponge

# Prevent a formula from upgrading.
brew pin gnupg2

# Bring an installation up to speed from a Brewfile.
brew bundle
brew bundle --global
brew bundle --file $HOME/Brewfile --no-lock

# Dump all installed casks/formulae/images/taps into a Brewfile in the current
# directory.
brew bundle dump
```

## Configuration

```sh
# Require SHA check for casks.
# Change cask installation dir to the Application folder in the user's HOME.
export HOMEBREW_CASK_OPTS="--require-sha --appdir $HOME/Applications"

# Print install times for each formula at the end of the run.
export HOMEBREW_DISPLAY_INSTALL_TIMES=1

# Do not automatically update before running some commands.
export HOMEBREW_NO_AUTO_UPDATE=1

# Do not print HOMEBREW_INSTALL_BADGE on a successful build.
export HOMEBREW_NO_EMOJI=1

# Do not use the GitHub API.
# Avoid searches or fetching relevant issues after a failed install.
export HOMEBREW_NO_GITHUB_API=1

# Forbid redirects from secure HTTPS to insecure HTTP.
export HOMEBREW_NO_INSECURE_REDIRECT=1

# Only list updates to installed software.
export HOMEBREW_UPDATE_REPORT_ONLY_INSTALLED=1

# Pass the -A option when calling sudo.
export SUDO_ASKPASS=1
```

## Downgrade an application to a non-managed version

### The easy way

```sh
brew unlink kubernetes-helm
brew install https://raw.githubusercontent.com/Homebrew/homebrew-core/ed9dcb2cb455a816f744c3ad4ab5c18a0d335763/Formula/kubernetes-helm.rb
brew switch kubernetes-helm 2.13.0
```

### The hard way

[source](https://stackoverflow.com/questions/3987683/homebrew-install-specific-version-of-formula)
[alternative source](https://www.fernandomc.com/posts/brew-install-legacy-hugo-site-generator/)

```sh
formula_name='kubernetes-helm'
formula_version='2.13.1'

cd $(brew --repository)/Library/Tapshomebrew/homebrew-core
git log master -S${formula_version} -- Formula/${formula_name}.rb
commit_id='<something>'  # insert commit id

git checkout -b ${formula_name}-${formula_version} ${commit_id}
HOMEBREW_NO_AUTO_UPDATE=1 brew install ${formula_name}
# pin application if needed

git checkout master
git branch -d ${formula_name}-${formula_version}
```

## Gotchas

- `moreutils` installs its own old version of `parallel`, which conflicts with the `parallel` formulae; install the standalone `gettext`, `parallel` and `sponge` to have their recent version

## Further readings

- [manpage]
- Homebrew [bundle]

[bundle]: https://github.com/Homebrew/homebrew-bundle
[manpage]: https://docs.brew.sh/Manpage

## Sources

- [How to stop homebrew from upgrading itself on every run]
- [macOS migrations with Brewfile]

[how to stop homebrew from upgrading itself on every run]: https://superuser.com/questions/1209053/how-do-i-tell-homebrew-to-stop-running-brew-update-every-time-i-want-to-install/1209068#1209068
[macos migrations with brewfile]: https://openfolder.sh/macos-migrations-with-brewfile
