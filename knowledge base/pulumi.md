# Pulumi

1. [TL;DR](#tldr)
1. [Migrate to different backends](#migrate-to-different-backends)
1. [Ignore changes](#ignore-changes)
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
pulumi login 's3://state-bucket/prefix'

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


# Set secrets.
pulumi config set --secret 'dbPassword' 'S3cr37'
pulumi config set --secret 'ecr:dockerHub' \
  '{"username":"marcus","accessToken":"dckr_pat_polus"}'

# Read secrets.
pulumi config get 'dbPassword'


# Get a summary of what would be deployed.
pulumi pre
pulumi pre --diff -p '10' -m 'message' -s 'stack'
pulumi pre --expect-no-changes --parallel '10' --show-reads
pulumi preview -t 'targetResourceUrn'

# Save any resource creation seen during the preview into an import file to use
# with the `import` subcommand.
pulumi preview --import-file 'resources.to.import.json'

# Deploy resources.
pulumi up
pulumi up -ry --show-config --replace 'resourceUrn'
pulumi up --target 'targetResourceUrn'
pulumi update --refresh --yes -f --secrets-provider 'hashivault'

# Access outputs.
pulumi stack output 'vpcId'
pulumi stack output 'subnetName' --show-secrets -s 'stack'

# Import existing resources.
pulumi import 'aws:ecr/pullThroughCacheRule:PullThroughCacheRule' 'resourceName' 'prefix'
pulumi import 'aws:secretsmanager/secret:Secret' 'resourceName' 'secretArn' --protect false
pulumi import \
  'aws:secretsmanager/secretVersion:SecretVersion' 'resourceName' 'secretArn|versionId' \
  --skip-preview -o 'imported.resources.ts'
pulumi import -f 'resources.to.import.json'

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

# Export stacks.
pulumi stack export
pulumi stack export -s 'dev' --show-secrets --file 'dev.stack.json'

# Create graphs of the dependency relations.
pulumi stack graph 'path/to/graph.dot'
pulumi stack graph -s 'dev' 'dev.dot' --short-node-name

# Delete stacks.
pulumi stack rm
pulumi stack rm -fy
pulumi stack rm --preserve-config --yes --stack 'stack'


# Rename resources in states.
pulumi state rename 'resourceUrn' 'newName'
pulumi state rename \
  'urn:pulumi:dev::whatevah::aws:rds/parameterGroup:ParameterGroup::mariadb-slow' \
  'mariadb-slower'


# Unprotect resources that are protected in states.
pulumi state unprotect 'resourceUrn'
```

</details>

<details>
  <summary>Real world use cases</summary>

```sh
# Import resources.
pulumi import \
  'aws:s3/bucket:Bucket'
  'myBucket' 'my-bucket'
pulumi import \
  'aws:ecr/pullThroughCacheRule:PullThroughCacheRule' \
  'pullThroughCacheRule_dockerHub' 'cache/docker-hub'
pulumi import \
  'aws:secretsmanager/secret:Secret' \
  'ecr-pullthroughcache/docker-hub' \
  'arn:aws:secretsmanager:eu-west-1:000011112222:secret:ecr-pullthroughcache/docker-hub'
pulumi import \
  'aws:secretsmanager/secretVersion:SecretVersion' \
  'ecr-pullthroughcache/docker-hub' \
  'arn:aws:secretsmanager:eu-west-1:000011112222:secret:ecr-pullthroughcache/docker-hub-|fb4caa30-55ca-4351-2bc9-5c866ddde3f4'

# Check resources up.
pulumi stack export | yq -y '.deployment.resources[]' -
pulumi stack export | jq -r '.deployment.resources[]|select(.id=="myBucket").urn' -

# Rename protected resources.
pulumi state unprotect 'urn:pulumi:all::s3_lifecycle_bucketv2::aws:s3/bucketV2:BucketV2::org-infra'
pulumi state rename 'urn:pulumi:all::s3_lifecycle_bucketv2::aws:s3/bucketV2:BucketV2::org-infra' 'org-infra_lifecycle'

# Act on resources by their name.
pulumi stack export \
| yq -r '.deployment.resources[]|select(.id=="myBucket").urn' - \
| xargs -n 1 pulumi refresh --preview-only -t

# Change backend.
# From Pulumi Cloud to S3.
pulumi login \
&& pulumi stack select 'myOrg/dev' \
&& pulumi stack export --show-secrets --file 'dev.stack.json' \
&& pulumi logout \
&& pulumi login 's3://myBucket/myOrg/dev' \
&& pulumi stack init 'dev' \
&& pulumi stack import --file 'dev.stack.json'
```

</details>
<br/>

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
| `pulumi state export`           | `terraform state list`                          |
| `pulumi state delete …`         | `terraform state rm …`                          |

<br/>
Learning resources:

- [Blog]
- [Code examples]
- [Resources reference]

## Migrate to different backends

1. Get to the current backend:

   ```sh
   pulumi login
   pulumi whoami -v
   ```

1. Select the stack to export:

   ```sh
   pulumi stack select 'superbros-galaxy2/mario'
   ```

1. Export the stack's state to file:

   ```sh
   pulumi stack export --show-secrets --file 'mario.stack.json'
   ```

1. Logout from the current backend, and login to the new one:

   ```sh
   pulumi logout
   pulumi login 's3://super-bros/galaxy2'
   pulumi whoami -v
   ```

1. Create a new stack with the same name on the new backend:

   ```sh
   pulumi stack init 'mario'
   ```

1. Import the existing state into the new backend:

   ```sh
   pulumi stack import --file 'mario.stack.json'
   ```

1. Check the secrets provider and the key are fine:

   ```sh
   cat 'Pulumi.mario.yaml'
   ```

## Ignore changes

Add the [`ignoreChanges` option][ignorechanges] to the resource.

```ts
const resource = new.aws.s3.Bucket("bucket", {
  …
}, {
  ignoreChanges: [
    "tags['last-deploy-at']"
  ]
});
```

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
[ignorechanges]: https://www.pulumi.com/docs/concepts/options/ignorechanges/
[resources reference]: https://www.pulumi.com/resources
[state]: https://www.pulumi.com/docs/concepts/state/
[website]: https://www.pulumi.com/

<!-- Others -->
