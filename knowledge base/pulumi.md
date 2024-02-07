# Pulumi

1. [TL;DR](#tldr)
1. [Further readings](#further-readings)
1. [Sources](#sources)

## TL;DR

```sh
# Install.
brew install 'pulumi/tap/pulumi'
choco install 'pulumi'

# Create completions for the shell.
source <(pulumi gen-completion 'zsh')
pulumi completion 'fish' > "$HOME/.config/fish/completions/pulumi.fish"


# Operate entirely from the local machine (local-only mode).
# Stores the state under the '.pulumi' folder in the given directory.
pulumi login --local
pulumi login "file://~"
pulumi login "file://."
pulumi login "file://path/to/folder"

# Store the state in object storage backends.
pulumi login 'azblob://state-bucket'
pulumi login 'gs://state-bucket'
pulumi login 's3://state-bucket'

# List available templates.
pulumi new -l
pulumi new --list-templates

# Create new projects in the current directory.
# Creates basic scaffolding files based on the specified cloud and language.
pulumi new
pulumi new 'aws-go' -d 'description' -n 'name'
pulumi new 'azure-python' --dir '.' -s 'stack' --name 'name'
pulumi new 'gcp-typescript' --description 'description' --stack 'stack'
pulumi new 'kubernetes-yaml'
pulumi new 'oci-java'

# Get a summary of what would be deployed.
pulumi preview
pulumi preview --diff -p '10' -m 'message' -s 'stack'
pulumi pre --expect-no-changes --parallel '10' --show-reads

# Deploy stacks.
pulumi up
pulumi up -ry --show-config --replace 'urn'
pulumi update --refresh --yes -f --secrets-provider 'hashivault'

# Access outputs.
pulumi stack output 'vpcId'
pulumi stack output 'subnetName' --show-secrets -s 'stack'

# Destroy resources.
pulumi destroy
pulumi down -s 'stack' --exclude-protected

# View stacks' state.
pulumi stack
pulumi stack -ius 'stack'
pulumi stack --show-ids --show-urns --show-name --show-secrets

# List stacks.
pulumi stack ls
pulumi stack ls -o 'organization' -p 'project' -t 'tag'
pulumi stack ls -a

# Delete stacks.
pulumi stack rm
pulumi stack rm -fy
pulumi stack rm --preserve-config --yes --stack 'stack'
```

| Pulumi                          | Terraform                                       |
| ------------------------------- | ----------------------------------------------- |
| `pulumi new …`                  | `terraform init`                                |
| `pulumi preview`, `pulumi pre`  | `terraform plan`                                |
| `pulumi up`, `pulumi update`    | `terraform apply`                               |
| `pulumi stack output …`         | `terraform output …`                            |
| `pulumi destroy`, `pulumi down` | `terraform destroy`, `terraform apply -destroy` |
| `pulumi stack`                  | `terraform workspace show`                      |
| `pulumi stack ls`               | `terraform workspace list`                      |
| `pulumi stack rm`               | `terraform workspace delete …`                  |

## Further readings

- [Website]
- [Terraform]

## Sources

All the references in the [further readings] section, plus the following:

- [Documentation]

<!--
  References
  -->

<!-- In-article sections -->
[further readings]: #further-readings

<!-- Knowledge base -->
[terraform]: terraform.md

<!-- Files -->
<!-- Upstream -->
[documentation]: https://www.pulumi.com/docs/
[website]: https://www.pulumi.com/

<!-- Others -->
