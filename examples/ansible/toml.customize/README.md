# Customize a given TOML file

The example takes the configuration of a Gitlab runner as example just because it is a TOML file with known values.

## Requirements

- Matt Martz (_sivel_)'s [`toiletwater`][toiletwater] Ansible collection.</br>
  Needed to have access to filters like `to_toml`.

  ```sh
  ansible-galaxy collection install 'sivel.toiletwater'
  ```

- Python's 'toml' library</br>
  Needed to read from and write to TOML files.

  ```sh
  pip install --user 'toml'
  brew install 'python-toml'
  ```

## Output

See the [desired result][desired.toml] and the effective [output][output.toml].

Not perfect, but still good enough.

## Further readings

- [Runners' configuration values]

### Sources

- [Merging two dictionaries by key in Ansible]

<!--
  References
  -->

<!-- Knowledge base -->
<!-- Files -->
[desired.toml]: desired.toml
[output.toml]: output.toml

<!-- Upstream -->
[runners' configuration values]: https://docs.gitlab.com/runner/configuration/advanced-configuration.html
[toiletwater]: https://galaxy.ansible.com/ui/repo/published/sivel/toiletwater/

<!-- Others -->
[merging two dictionaries by key in ansible]: https://serverfault.com/questions/1084157/merging-two-dictionaries-by-key-in-ansible#1084164
