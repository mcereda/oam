# Pulumi

1. [TL;DR](#tldr)
1. [Further readings](#further-readings)
   1. [Sources](#sources)

## TL;DR

<details>
  <summary>Installation</summary>

```sh
# Install.
brew install 'pulumi/tap/pulumi'
choco install 'pulumi'

# Create completions for the shell.
source <(pulumi gen-completion 'zsh')
pulumi completion 'fish' > "$HOME/.config/fish/completions/pulumi.fish"
```

</details>

<details>
  <summary>Usage</summary>

```sh
# Operate entirely from the local machine (local-only mode).
# Stores the state under the '.pulumi' folder in the given directory.
pulumi login --local
pulumi login "file://~"
pulumi login "file://."
pulumi login "file://path/to/folder"
yq '. += {"backend": {"url": "file://."}}' 'path/to/program/Pulumi.yaml' \
  | sponge 'path/to/program/Pulumi.yaml'

# Store the state in object storage backends.
pulumi login 'azblob://state-bucket'
pulumi login 'gs://state-bucket'
pulumi login 's3://state-bucket'

# Display the current logged in user.
# The '-v' option shows the current backend too.
pulumi whoami
pulumi whoami -v

# Log out of the current backend.
pulumi logout


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


# Get the full program configuration.
# Secrets are obscured.
pulumi config get


# Set up secrets.
pulumi config set --secret 'dbPassword' 'S3cr37'
pulumi config set --secret 'ecr:dockerHub' \
  '{"username":"marcus","accessToken":"dckr_pat_polus"}'

# Read secrets.
pulumi config get 'dbPassword'


# Get a summary of what would be deployed.
pulumi preview
pulumi preview --diff -p '10' -m 'message' -s 'stack'
pulumi pre --expect-no-changes --parallel '10' --show-reads

# Deploy resources.
pulumi up
pulumi up -ry --show-config --replace 'resourceUrn'
pulumi up --target 'resourceUrn'
pulumi update --refresh --yes -f --secrets-provider 'hashivault'

# Access outputs.
pulumi stack output 'vpcId'
pulumi stack output 'subnetName' --show-secrets -s 'stack'

# Import existing resources.
pulumi import 'aws:ecr/pullThroughCacheRule:PullThroughCacheRule' 'resourceName' 'prefix'
pulumi import 'aws:secretsmanager/secret:Secret' 'resourceName' 'secretArn'
pulumi import 'aws:secretsmanager/secretVersion:SecretVersion resourceName' 'secretArn|versionId'

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

# Create graphs of the dependency relations.
pulumi stack graph 'path/to/graph.dot'
pulumi stack graph -s 'dev' 'dev.dot' --short-node-name

# Delete stacks.
pulumi stack rm
pulumi stack rm -fy
pulumi stack rm --preserve-config --yes --stack 'stack'


# Rename resources in states.
pulumi rename 'resourceUrn' 'newName'

# Unprotect resources that are protected in states.
pulumi state unprotect 'resourceUrn'
```

</details>

Commands comparison:

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

Learning resources:

- [Blog]
- [Code examples]
- [Resources reference]

## Further readings

- [Website]
- [Terraform]
- [Code examples]
- [Resources reference]

### Sources

- [Documentation]
- [State]

<!--
  References
  -->

<!-- In-article sections -->
<!-- Knowledge base -->
[terraform]: terraform.md

<!-- Files -->
<!-- Upstream -->
[blog]: https://www.pulumi.com/blog
[code examples]: https://github.com/pulumi/examples
[documentation]: https://www.pulumi.com/docs/
[resources reference]: https://www.pulumi.com/resources
[state]: https://www.pulumi.com/docs/concepts/state/
[website]: https://www.pulumi.com/

<!-- Others -->
