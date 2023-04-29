# Knowledge base

This is the collection of all notes, reminders and whatnot I gathered during the years.

## Conventions

- Prefer keeping an 80 characters width limit in code blocks.<br/>
  This improves readability on most locations.

- Always use an highlighting annotation when writing code blocks (default to `txt`).

- Use `sh` as highlighting annotation instead of `shell` when writing shell snippets in code blocks.<br/>
  The local renderer just displays them better like this.

  ```diff
  - ```shell
  + ```sh
    #!/usr/bin/env zsh
  ```

- Group related options in commands where possible.<br/>
  It gives enhanced clarity and a sense of continuation.

  ```diff
    az deployment group validate \
  -   -f 'template.bicep' -g 'resource_group_name' -p 'parameter1=value' parameter2="value" -n 'deployment_group_name'
  +   -n 'deployment_group_name' -g 'resource_group_name' \
  +   -f 'template.bicep' -p 'parameter1=value' parameter2="value"
  ```

- Split piped or concatenated commands into multiple lines.<br/>
  It emphasizes they are indeed multiple commands.

  ```diff
  - find . -type 'f' -o -type 'l' | awk 'BEGIN {FS="/"; OFS="|"} {print $NF,$0}' | sort --field-separator '|' --numeric-sort | cut -d '|' -f2
  + find . -type 'f' -o -type 'l' \
  + | awk 'BEGIN {FS="/"; OFS="|"} {print $NF,$0}' \
  + | sort --field-separator '|' --numeric-sort \
  + | cut -d '|' -f2
  ```

- Indent the arguments of a command when splitting it into multiple lines.<br/>
  It makes sooo much easier to have clear what are arguments and what are different commands altogether.

  ```diff
    dnf -y install --setopt='install_weak_deps=False' \
  - 'Downloads/tito-0.6.2-1.fc22.noarch.rpm'
  +   'Downloads/tito-0.6.2-1.fc22.noarch.rpm'
  ```

- Do **not** indent pipes or concatenations when splitting commands into multiple lines.<br/>
  It makes clear those are different commands.

  ```diff
    jq --sort-keys '.' datapipeline.json > /tmp/sorted.json \
  -   && jq '.objects = [(.objects[] as $in | {type,name,id} + $in | with_entries(select(.value != null)))]' \
  -        /tmp/sorted.json > /tmp/reordered.json \
  -     && mv /tmp/reordered.json datapipeline.json
  + && jq '.objects = [(
  +   .objects[] as $in
  +   | {type,name,id} + $in 
  +   | with_entries(select(.value != null))
  + )]' /tmp/sorted.json > /tmp/reordered.json \
  + && mv /tmp/reordered.json datapipeline.json
  ```
