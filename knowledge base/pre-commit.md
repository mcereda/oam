# Pre-commit

## TL;DR

```shell
# generate a very basic configuration
pre-commit sample-config > .pre-commit-config.yaml

# manually run checks
pre-commit run --all-files   # all checks
pre-commit run ansible-lint  # ansible-lint only

# automatically run checks at every commit
pre-commit install

# update all hooks to the latest version
pre-commit autoupdate

# skip check on commit
SKIP=flake8 git commit -m "foo"
```

## Further readings

- List of [supported hooks]

[supported hooks]: https://pre-commit.com/hooks.html

## Sources

- [Website]

[website]: https://pre-commit.com
