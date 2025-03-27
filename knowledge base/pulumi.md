# Pulumi

1. [TL;DR](#tldr)
1. [Project](#project)
1. [Program](#program)
   1. [Ignore changes](#ignore-changes)
   1. [Delete before replacing](#delete-before-replacing)
   1. [Assign tags to resources by default](#assign-tags-to-resources-by-default)
   1. [Outputs](#outputs)
   1. [Policy enforcement](#policy-enforcement)
1. [Stack](#stack)
   1. [Monolith vs micro-stack](#monolith-vs-micro-stack)
   1. [State](#state)
   1. [Configuration](#configuration)
1. [Backend](#backend)
   1. [Enforce specific backends for projects](#enforce-specific-backends-for-projects)
   1. [Migrate to different backends](#migrate-to-different-backends)
1. [Compose resources](#compose-resources)
1. [Import resources](#import-resources)
   1. [Import components and their children](#import-components-and-their-children)
1. [Troubleshooting](#troubleshooting)
   1. [A project with the same name already exists](#a-project-with-the-same-name-already-exists)
   1. [Stack init fails because the stack supposedly already exists](#stack-init-fails-because-the-stack-supposedly-already-exists)
   1. [Stack init fails due to missing scheme](#stack-init-fails-due-to-missing-scheme)
   1. [Stack init fails due to invalid key identifier](#stack-init-fails-due-to-invalid-key-identifier)
   1. [Change your program back to the original providers](#change-your-program-back-to-the-original-providers)
   1. [`Attempting to deploy or update resources with X pending operations from previous deployment`](#attempting-to-deploy-or-update-resources-with-x-pending-operations-from-previous-deployment)
1. [Further readings](#further-readings)
   1. [Sources](#sources)

## TL;DR

| Concept         | ELI5 summary                                               | Notes                                                                                |
| --------------- | ---------------------------------------------------------- | ------------------------------------------------------------------------------------ |
| [Project]       | Any folder that contains a `Pulumi.yaml` file              | Collection of code                                                                   |
| [Program]       | The code in a project                                      | Defines resources                                                                    |
| [Stack]         | An isolated, independent instance of a _program_           | Has its own _configuration_ and _state_<br/>Usually defines an environment or branch |
| [Configuration] | The specific data used in a _stack_                        | Each _stack_ has its own _configuration_                                             |
| [State]         | Metadata about resources in a _stack_                      | Each _stack_ has its own _state_                                                     |
| [Backend]       | Storage place for one or more _projects_' sets of _states_ |                                                                                      |

When a stack is not explicitly requested in a command (`-s`, `--stack`), Pulumi defaults to the currently selected
one.<br/>
Projects (and hence stacks) [can be nested][monolith vs micro-stack].

Target single resources with `-t`, `--target`. Target also those that depend on them with `--target-dependents`.

<details>
  <summary>Setup</summary>

```sh
# Install.
brew install 'pulumi/tap/pulumi'
choco install 'pulumi'
docker pull 'pulumi/pulumi'  # pulumi/pulumi-[nodejs|python|java|…]:3.148.0

# Create completions for the shell.
source <(pulumi gen-completion 'zsh')
pulumi gen-completion 'fish' > "$HOME/.config/fish/completions/pulumi.fish"
```

</details>

<details>
  <summary>Usage</summary>

```sh
# Run in Docker
docker container run --rm --name 'pulumi' \
  --volume 'pulumi-home:/root/.pulumi:rw' \
  --volume "${PWD}:/pulumi/projects:rw" \
  --env 'PULUMI_SKIP_UPDATE_CHECK=true' \
  --volume "${HOME}/.aws:/root/.aws:ro" \
  --env 'AWS_REGION' --env 'AWS_ACCESS_KEY_ID' --env 'AWS_SECRET_ACCESS_KEY' \
  --volume "${HOME}/.config/gcloud:/root/.config/gcloud:ro" \
  'pulumi/pulumi-nodejs:3.153.1' \
  pulumi …

# List available templates.
pulumi new -l
pulumi new --list-templates

# Create new projects in the current directory.
# Creates basic scaffolding files based on the specified cloud and language.
pulumi new
pulumi new 'aws-go' -d 'description' -n 'name'
pulumi new 'azure-python' --dir '.' -s 'stack' --name 'name'
pulumi new 'gcp-typescript' --description 'description' --stack 'stack'
pulumi new 'kubernetes-yaml' --generate-only
pulumi new 'oci-java' --secrets-provider 'hashivault://myKey'


# Operate entirely from the local machine (local-only mode).
# Stores the state under the '.pulumi' folder in the given directory.
pulumi login --local
pulumi login "file://~"
pulumi login "file://."
pulumi login "file://path/to/folder"
yq -iy '. += {"backend": {"url": "file://."}}' 'Pulumi.yaml'

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


# Print information about the project and stack.
pulumi about
pulumi about -s 'dev'


# Set configuration values.
pulumi config set 'varName' 'value'
pulumi config set 'namespace:varName' 'value'
pulumi config set --secret 'secretName' 'secretValue'
pulumi config set --secret 'namespace:secretName' 'secretValue'

# Read configuration values.
# Secrets get unencrypted.
pulumi config get 'dbPassword'

# Copy the configuration over to other stacks.
pulumi config cp -d 'local'
pulumi config cp -s 'prod' -d 'dev'


# Get a summary of what would be deployed.
pulumi pre
pulumi pre --diff -p '10' -m 'message' -s 'stack'
pulumi pre --expect-no-changes --parallel '10' --show-reads
pulumi preview -t 'targetResourceUrn' --target-dependents -v '2'

# Save any resource creation seen during the preview into an import file to use
# with the `import` subcommand.
pulumi preview --import-file 'resources.to.import.json'

# Deploy resources.
pulumi up
pulumi up -ry --show-config --replace 'targetResourceUrn'
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
pulumi import -f 'resources.to.import.json' --generate-code=false -y

# Destroy resources.
pulumi destroy
pulumi down -t 'targetResourceUrn'
pulumi dn -s 'stack' --exclude-protected


# View the selected stack
pulumi stack --show-name

# View stacks' state.
pulumi stack
pulumi stack -ius 'stack-name'
pulumi stack --show-ids --show-urns --show-name --show-secrets

# List stacks.
pulumi stack ls
pulumi stack ls -o 'organization' -p 'project' -t 'tag'
pulumi stack ls -a

# Create stacks.
pulumi stack init 'prod'
pulumi stack init 'local' --copy-config-from 'dev' --no-select

# Export stacks' state.
pulumi stack export
pulumi stack export -s 'dev' --show-secrets --file 'dev.stack.json'

# Import stacks' state.
pulumi stack import --file 'dev.stack.json'
pulumi stack import -s 'local' --file 'dev.stack.json'

# Change the current stack.
pulumi select 'prod'

# Delete stacks.
pulumi stack rm
pulumi stack rm -fy
pulumi stack rm --preserve-config --yes --stack 'stack'

# Create graphs of the dependency relations.
pulumi stack graph 'path/to/graph.dot'
pulumi stack graph -s 'dev' 'dev.dot' --short-node-name

# Rename stacks.
pulumi stack rename 'new-name'
pulumi stack rename 'new-dev' -s 'dev'
pulumi stack rename -s 'dev' 'organization/internal-services/dev'

# Change secrets providers.
pulumi stack change-secrets-provider 'awskms://1234abcd-12ab-34cd-56ef-1234567890ab?region=us-east-1'
pulumi stack change-secrets-provider 'awskms:///arn:aws:kms:eu-east-2:012345678901:key/01234567-890a-bcde-f012-34567890abcd'
pulumi stack change-secrets-provider "azurekeyvault://mykeyvaultname.vault.azure.net/keys/mykeyname"
pulumi stack change-secrets-provider 'hashivault://deezKeyz'


# Rename resources in states.
pulumi state rename 'resourceUrn' 'newName'
pulumi state rename \
  'urn:pulumi:dev::whatevah::aws:rds/parameterGroup:ParameterGroup::mariadb-slow' \
  'mariadb-slower'

# Delete resources from states.
pulumi state delete 'resourceUrn'
pulumi state delete --force --target-dependents \
  'urn:pulumi:dev::whatevah::aws:rds/parameterGroup:ParameterGroup::mariadb-slow'

# Unprotect resources that are protected in states.
pulumi state unprotect 'resourceUrn'


# Rename projects.
# Requires the use of fully-qualified stack names.
# To update the stack again, one also needs to update the 'name' field of the projects' 'Pulumi.yaml' file to match the
# new name.
pulumi stack rename 'org/new-project/dev'
pulumi stack rename 'org/new-project/dev' -s 'dev'
pulumi stack rename -s 'pulumicomuser/testproj/dev' 'organization/internal-services/dev'


# List installed plugins.
pulumi plugin ls
pulumi plugin ls --project --json

# Install plugins.
pulumi plugin install
pulumi plugin install 'resource' 'aws'
pulumi plugin install 'resource' 'aws' '6.37.1' --reinstall

# Remove installed plugins.
pulumi plugin rm 'resource'
pulumi plugin rm 'resource' 'aws' --yes
pulumi plugin rm 'resource' 'aws' '6.37.0'
pulumi plugin rm --all


# Use terraform providers.
# Follow the instructions that come after the provider installation.
pulumi package add terraform-provider 'planetscale/planetscale'


# Run in Docker.
docker run … -it \
  -v "$(pwd):/pulumi/projects" \
  -e 'AWS_ACCESS_KEY_ID' -e 'AWS_SECRET_ACCESS_KEY' -e 'AWS_REGION' \
  'pulumi/pulumi-nodejs:3.111.1-debian' \
  bash -c "npm ci && pulumi login 's3://bucket/prefix' && pulumi pre --parallel $(nproc) -s 'dev'"


# Use Plans.
# *Experimental* feature at the time of writing.
# Has issues with apply operations?
pulumi pre … --save-plan 'plan.json'
pulumi up --yes --non-interactive --stack 'stackname' \
  --skip-preview --plan 'plan.json' \
  --logtostderr --logflow --verbose '9' 1> pulumi-up.txt 2> pulumi-error.txt || exit_code=$?
```

</details>

<details>
  <summary>Data resources</summary>

```ts
const cluster_role = aws.iam.getRoleOutput({ name: "AWSServiceRoleForAmazonEKS" });
const cluster = new aws.eks.Cluster("cluster", {
  roleArn: cluster_role.arn,
  …
});

// If used in JSON documents, the function needs to cover the whole document.
const encryptionKey = aws.kms.getKeyOutput({
  keyId: "00001111-2222-3333-4444-555566667777",
});
new aws.iam.Role(
  "clusterServiceRole",
  {
    inlinePolicies: [{
      policy: encryptionKey.arn.apply(
        keyArn => JSON.stringify({
          Version: "2012-10-17",
          Statement: [{
            Effect: "Allow",
            Action: [
              "kms:CreateGrant",
              "kms:DescribeKey",
            ],
            Resource: keyArn,
          }],
        }),
      ),
    }],
  },
);
```

</details>

<details>
  <summary>Real world use cases</summary>

```sh
# Programmatic initialization with local state.
pulumi new -gy 'typescript' -n 'name' --dir 'dirname' \
&& cd 'dirname' \
&& npm install \
&& yq -iy '. += {"backend": {"url": "file://."}}' 'Pulumi.yaml' \
&& PULUMI_CONFIG_PASSPHRASE='test123' pulumi stack init 'stack-name' \
&& cd -

# Set configuration values.
pulumi config set --secret 'ecr:dockerHub' '{"username":"marcus","accessToken":"dckr_pat_polus"}'
pulumi config set-all --path \
  --plaintext 'aws:defaultTags.tags.Owner=SomeOne' \
  --plaintext 'aws:defaultTags.tags.Team=SomeTeam'

# Using the same number of threads of the machine seems to give the best
# performance ratio.
pulumi pre --parallel "$(nproc)" --diff
pulumi up --parallel "$(nproc)"

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

# Act on resources by their id.
pulumi stack export \
| yq -r '.deployment.resources[]|select(.id=="myBucket").urn' - \
| xargs -n 1 pulumi refresh --preview-only -t --target-dependents

# Migrate backend.
# From Pulumi Cloud to S3.
pulumi login \
&& pulumi stack select 'myOrg/dev' \
&& pulumi stack export --show-secrets --file 'dev.stack.json' \
&& pulumi logout \
&& pulumi login 's3://myBucket/prefix' \
&& pulumi stack init 'dev' \
&& pulumi stack import --file 'dev.stack.json'


# Use a local state for testing.
# Remote state on S3.
mkdir -pv '.pulumi/stacks/myWonderfulInfra' \
&& aws s3 cp \
    's3://myBucket/prefix/.pulumi/stacks/myWonderfulInfra/prod.json' \
    '.pulumi/stacks/myWonderfulInfra/' \
&& yq -iy '. += {"backend": {"url": "file://."}}' 'Pulumi.yaml'

# Revert to the remote state.
yq -iy '. += {"backend": {"url": "s3://myBucket/prefix"}}' 'Pulumi.yaml'

# Diff the two states
# TODO
```

```ts
// Merge objects.
tags_base = {
  ManagedBy: "Pulumi",
  Prod: false,
};
new aws.eks.FargateProfile("fargateProfile", {
  tags: {
    ...tags_base,
    ...{
      Description: "Fargate profile for EKS cluster EksTest",
      EksComponent: "Fargate profile",
      Name: "eksTest-fargateProfile",
    },
  },
  …
});

// Default tags with explicit provider.
const provider = new aws.Provider("provider", {
  defaultTags: {
    tags: {
      ManagedBy: "Pulumi",
      Owner: "user@company.com",
      Team: "Infra",
    },
  },
});
new aws.eks.FargateProfile("fargateProfile", {
  …
}, {
  provider: provider,
  …
});

// Use outputs from other stacks.
const currentStack = pulumi.getStack();
const infraStack = new pulumi.StackReference(`organization/infra/${currentStack}`);
const subnets_private = infraStack.getOutput("subnets_private");  // list of aws.ec2.Subnets
new aws.eks.Cluster("cluster", {
  vpcConfig: {
    subnetIds: subnets_private.apply((subnets: aws.ec2.Subnet[]) => subnets.map(subnet => subnet.id)),
    …
  },
  …
});

// Debug the .apply() result of Outputs.
subnets_private.apply(
  (subnets: aws.ec2.Subnet[]) => subnets.map(subnet => console.log(subnet.id)),
);  // subnet-00001111222233334 …
subnets_private.apply(
  (subnets: aws.ec2.Subnet[]) => console.log(subnets.map(subnet => subnet.id)),
);  // [ 'subnet-00001111222233334', … ]

// Use multiple Outputs.
pulumi.all([
  aws.getRegionOutput().apply(region => region.id),
  aws.getCallerIdentityOutput().apply(callerIdentity => callerIdentity.accountId),
  cluster.name,
]).apply(
  ([regionId, accountId, clusterName]) => `arn:aws:eks:${regionId}:${accountId}:fargateprofile/${clusterName}/*`
);
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

## Project

Refer to [projects] for more and updated information.

Projects are collections of code.<br/>
Namely, they are the folders containing a `Pulumi.yaml` project file.<br/>
At runtime, the first parent folder starting from the current directory and containing a `Pulumi.yaml` file determines
the current project.

Projects are created with the `pulumi new` command:

```sh
# List available templates.
pulumi new -l
pulumi new --list-templates

# Create new projects in the current directory.
# Creates basic scaffolding files based on the specified cloud and language.
pulumi new
pulumi new 'aws-go' -d 'description' -n 'name'
pulumi new 'azure-python' --dir '.' -s 'stack' --name 'name'
pulumi new 'gcp-typescript' --description 'description' --stack 'stack'
pulumi new 'kubernetes-yaml' --generate-only
pulumi new 'oci-java'
```

## Program

Programs are the the files containing the resources' definitions.<br/>
They are deployed into [stacks][stack].

### Ignore changes

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

### Delete before replacing

Add the [`deleteBeforeReplace` option][deletebeforereplace] to the resource.

```ts
const cluster = new aws.eks.Cluster("cluster", {
  …
}, {
  deleteBeforeReplace: true
});
```

If a resource is assigned a static name, the `deleteBeforeReplace` option _should_ be enabled implicitly.

### Assign tags to resources by default

Read [Assigning tags by default on AWS with Pulumi] first to get an idea of pros and cons of the options, then pick one
(or both):

- Assign the wanted tags to the default provider in the stack's configuration file (`Pulumi.{stackName}.yaml`):

  ```yaml
  config:
    aws:defaultTags:
      tags:
        ManagedBy: "Pulumi",
        Owner: "user@example.org",
        Team: "Infra",
  ```

- Create a new provider with the wanted tags defined in it, then explicitly use that provider with all the resources
  involved:

  ```ts
  const customProvider = new aws.Provider(
    "customProvider",
    {
      defaultTags: {
        tags: {
          ManagedBy: "Pulumi",
          Owner: "user@example.org",
          Team: "Infra",
        },
      },
    },
  );
  const fargateProfile = new aws.eks.FargateProfile(
    "fargateProfile",
    { … },
    {
      provider: customProvider,
      …
    },
  );
  ```

### Outputs

TODO

### Policy enforcement

TODO

See [Automatically Enforcing AWS Resource Tagging Policies], [Get started with Pulumi policy as code].

## Stack

Refer to [stacks] for more and updated information.

Single isolated, independent instance of a [program].<br/>
Each stack has its own separate set of configuration and secrets, role-based access controls (RBAC), policies and
resources.

The stack name can be specified in one of these formats:

- `stackName`: identifies the stack named `stackName` in the current user account or default organization.<br/>
  Its [project] is specified by the nearest `Pulumi.yaml` project file.
- `orgName/stackName`: identifies the stack named `stackName` in the organization named `orgName`<br/>
  Its [project] is specified by the nearest `Pulumi.yaml` project file.
- `orgName/projectName/stackName`: identifies the stack named `stackName` for the project named `projectName` in the
  organization named `orgName`.<br/>
  `projectName` must match the project specified by the nearest `Pulumi.yaml` project file.

For self-managed [backends][backend], the `orgName` portion of the stack name must always be the constant string value
`organization`.

### Monolith vs micro-stack

Refer to [organizing pulumi projects & stacks] for more and updated information.

Monoliths are single, big projects defining all the resources (infrastructure, application, others) for an entire set of
services.<br/>
A monolith typically maps to a distinct environment (production, staging, …) or instance of the set of service it
defines:

```txt
monolith/
├── Pulumi.yaml
├── Pulumi.dev.yaml
├── Pulumi.prod.yaml
└── index.ts
```

Micro-stacks are obtained when one or more monoliths are broken into smaller, separately managed projects, where each
smaller project has its own subsets of resources, environments etc:

```txt
microProj/
├── sharedInfrastructure/
│   ├── Pulumi.yaml
│   ├── Pulumi.dev.yaml
│   ├── Pulumi.prod.yaml
│   ├── index.ts
│   └── networking/
│       ├── Pulumi.yaml
│       ├── Pulumi.all.yaml
│       └── index.java
├── payments/
│   ├── Pulumi.yml
│   ├── Pulumi.main.yml
│   ├── Pulumi.develop.yml
│   └── index.py
└── app/
    ├── Pulumi.yaml
    ├── Pulumi.trunk.yml
    ├── Pulumi.prod.yml
    └── index.go
```

Micro-stacks usually rely upon [stack references] to link resources together:

```ts
const nested = new pulumi.StackReference("organization/nested/dev");
const eks = nested.getOutput("eks");
```

All involved stacks must be stored in the same backend for them to be able to find the correct [stack references]:

```txt
$ # Only showing files of interest
$ tree
root/
├── infra/
│   ├── Pulumi.yaml  ───>  backend.url: "file://.."
│   └── index.ts     ───>  export const eks = eks_cluster;
├── app/
│   ├── Pulumi.yaml  ───>  backend.url: "file://.."
│   └── index.ts     ┬──>  const infraStack = new pulumi.StackReference(`organization/infra/${env}`);
│                    └──>  const eks = infraStack.getOutput("eks");
└── .pulumi/
    └── stacks/
        ├── infra/…
        └── app/…
```

### State

Refer to [state] for more and updated information.

Every [stack] has its own state.

States are stored in transactional snapshots called _checkpoints_ and are saved as JSON files.<br/>
Pulumi records checkpoints early and often, so that it can execute similarly to how database transactions work.<br/>
Checkpoints are stored in the [backend], under the `.pulumi/stacks/{project.name}` folder. See the
[backend] section for details.

### Configuration

TODO

## Backend

Refer to [state] for more and updated information.

> Pulumi is designed to use only a single backend at a time.

The default backend is Pulumi Cloud.<br/>
Change it by:

- Specifying the new backend in the login command:

  ```sh
  pulumi login 's3://myBucket/prefix'
  ```

- Setting up the related environment variable:

  ```sh
  export PULUMI_BACKEND_URL="file://."
  ```

- [Enforcing the new backend in the project's `Pulumi.yaml` file][enforce specific backends for projects].

The Pulumi Cloud backend records every checkpoint to allow to recover from exotic failure scenarios.<br/>
Self-managed backends may have more trouble recovering from these situations, as they typically store a single state
file instead.

Backends store the states of one or more [stacks][stack], divided by [project].
Everything **but** the credentials for the backend (`~/.pulumi/credentials.json`) is stored in the backend's root
directory, under the `.pulumi` folder:

```sh
$ # backend.url: "file://."
$ tree .pulumi/
.pulumi/
├── backups
│   ├── eks-cluster
│   │   └── dev
│   │       ├── dev.1710756390076182000.json
│   │       ├── dev.1710756390076182000.json.attrs
⋮    ⋮       ⋮
│   │       ├── dev.1710976739411969000.json
│   │       └── dev.1710976739411969000.json.attrs
├── history
│   └── eks-cluster
│       └── dev
│           ├── dev-1710756390074683000.checkpoint.json
│           ├── dev-1710756390074683000.checkpoint.json.attrs
│           ├── dev-1710756390074683000.history.json
│           ├── dev-1710756390074683000.history.json.attrs
⋮            ⋮
│           ├── dev-1710976739410090000.checkpoint.json
│           ├── dev-1710976739410090000.checkpoint.json.attrs
│           ├── dev-1710976739410090000.history.json
│           └── dev-1710976739410090000.history.json.attrs
├── locks
│   └── organization
│       └── eks-cluster
│           └── dev
├── meta.yaml
├── meta.yaml.attrs
└── stacks
    └── eks-cluster
        ├── dev.json
        ├── dev.json.attrs
        ├── dev.json.bak
        └── dev.json.bak.attrs

$ # backend.url: "s3://organization-backend/prefix"
$ aws s3 ls --recursive s3://organization-backend/prefix/
2024-03-19 13:29:40         96 prefix/.pulumi/backups/eks-cluster/dev/dev.1710851379185590000.json
2024-02-28 17:26:40    2208988 prefix/.pulumi/backups/test/dev/dev.1709137599777801000.json
⋮                              ⋮
2024-03-15 13:52:55    2584430 prefix/.pulumi/backups/test/dev/dev.1710507174803067472.json
2024-03-19 13:29:40         96 prefix/.pulumi/history/eks-cluster/dev/dev-1710851378988809000.checkpoint.json
2024-03-19 13:29:40       1344 prefix/.pulumi/history/eks-cluster/dev/dev-1710851378988809000.history.json
2024-02-28 17:26:38    2208988 prefix/.pulumi/history/test/dev/dev-1709137597403068000.checkpoint.json
2024-02-28 17:26:38       2883 prefix/.pulumi/history/test/dev/dev-1709137597403068000.history.json
⋮                              ⋮
2024-03-15 13:52:55    2584430 prefix/.pulumi/history/start/dev/dev-1710507174611611742.checkpoint.json
2024-03-15 13:52:55       3854 prefix/.pulumi/history/start/dev/dev-1710507174611611742.history.json
2024-02-28 16:45:44         11 prefix/.pulumi/meta.yaml
2024-03-15 11:58:23         96 prefix/.pulumi/stacks/eks-cluster/dev.json
2024-03-15 13:52:55    2584430 prefix/.pulumi/stacks/test/dev.json
2024-03-19 17:21:28    2584430 prefix/.pulumi/stacks/test/dev.json.bak
```

### Enforce specific backends for projects

Set the projects' `backend.url` property in their `Pulumi.yaml` file:

```sh
yq -iy '. += {"backend": {"url": "s3://myBucket"}}' 'Pulumi.yaml'
```

```yaml
name: my-proj
backend:
  url: s3://myBucket
```

### Migrate to different backends

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

## Compose resources

FIXME: should this be under [Program]?

Refer [Component resources].

Logical grouping of resources.<br/>
Usually leveraged to instantiate a set of related resources, aggregate them as children, and create larger abstractions
that encapsulate their implementation details.

Component resources only package a set of other resources.<br/>
To have full control over resources' lifecycles in a Component, including running code upon updates or deletion, use
_dynamic providers_ instead.

Refer [Pulumi Crosswalk for AWS] or [Google Cloud Static Website] as examples.

<details>
  <summary>Procedure</summary>

1. Create a subclass of `ComponentResource`.

   <details style="padding: 0 0 1em 1em">

   ```ts
   class StandardAwsVpc extends pulumi.ComponentResource {};
   ```

   </details>

1. Inside its constructor, chain to the base constructor and pass it the subclass' name, arguments, and options.

   Upon creation of a new instance of the Component, the call to the base constructor registers the instance with the
   Pulumi engine. This records the resource's state and tracks it across deployments, allowing to see differences during
   updates just like any regular resource.

   All resources must have a name, so Components' constructors must accept one and pass it up.<br/>
   Components must also register a unique _type name_ with the base constructor. These names are namespaced alongside
   non-Component resources such as `aws:lambda:Function`.

   <details style="padding: 0 0 1em 1em">

   ```ts
   class StandardAwsVpc extends pulumi.ComponentResource {
       constructor(name: string, args: pulumi.Inputs, opts?: pulumi.ComponentResourceOptions) {
           super("exampleOrg:StandardAwsVpc", name, {}, opts);
       };
   };
   ```

   </details>

1. Inside the subclass' constructor again, create any child resources.<br/>
   Pass them the `parent` resource option to ensure the children are parented correctly.

   <details style="padding: 0 0 1em 1em">

   ```ts
   class StandardAwsVpc extends pulumi.ComponentResource {
       constructor(name: string, args: pulumi.Inputs, opts?: pulumi.ComponentResourceOptions) {
           …

           const vpc = new aws.ec2.Vpc(
             `${name}`,
             { … },
             { parent: this },
           );
           const internetGateway = new aws.ec2.InternetGateway(
             `${name}`,
             {
               vpcId: vpc.id,
               …
             },
             { parent: vpc },
           );
       };
   };
   ```

   </details>

1. Inside the subclass' constructor once more, define the Component's own output properties with the `registerOutputs()`
   function.<br/>
   Pulumi's engine uses it display the logical outputs of the Component resource, and any changes to those outputs will
   be shown during an update.

   <details style="padding: 0 0 1em 1em">

   ```ts
   class StandardAwsVpc extends pulumi.ComponentResource {
       constructor(name: string, args: pulumi.Inputs, opts?: pulumi.ComponentResourceOptions) {
           …

           this.registerOutputs({
               vpcId: vpc.id,
           });
       };
   };
   ```

   </details>

1. Create new instances of the Component resource in the code.

   <details style="padding: 0 0 1em 1em">

   ```ts
   class StandardAwsVpc extends pulumi.ComponentResource { … };
   const currentVpc = new StandardAwsVpc(
       "currentVpc",
       { cidrBlock: "172.31.0.0/16" },
       { protect: true },
   );
   ```

   </details>

</details>

<details>
  <summary>Sample code</summary>

```ts
import * as aws from "@pulumi/aws";

export class StandardAwsVpc extends pulumi.ComponentResource {
    constructor(name: string, args: pulumi.Inputs, opts?: pulumi.ComponentResourceOptions) {
        super("exampleOrg:StandardAwsVpc", name, {}, opts);

        const vpc = new aws.ec2.Vpc(
            `${name}`,
            {
                tags: {
                    Name: name,
                    ...args.tags,
                },

                cidrBlock: args.cidrBlock,
                enableDnsSupport: true,
            },
            { parent: this },
        );
        const internetGateway = new aws.ec2.InternetGateway(
            name,
            {
                tags: {
                    Name: name,
                    ...args.tags,
                },

                vpcId: vpc.id,
            },
            { parent: vpc },
        );
        …

        this.registerOutputs({
            vpcId: vpc.id,
        });
    };
};

const currentVpc = new StandardAwsVpc(
    "currentVpc",
    {
        tags: {
            Name: "CurrentVpc",
        },

        cidrBlock: "172.31.0.0/16",
    },
    { protect: true },
);
```

</details>

## Import resources

FIXME: should this be under [Program] or [Stack]?

Refer [Importing resources] and the [`pulumi import`][pulumi import] command.

```sh
pulumi import --file 'import.json'
pulumi import 'aws:ec2/instance:Instance' 'logstash' 'i-abcdef0123456789a' --suppress-outputs
pulumi import 'aws:cloudwatch/logGroup:LogGroup' 'vulcan' '/ecs/vulcan' --generate-code='false' --protect='false'
pulumi import 'aws:ec2/subnet:Subnet' 'public_subnet' 'subnet-9d4a7b6c' --parent 'current=urn:pulumi:someStack::someProject::aws:ec2/vpc:Vpc::current'
```

### Import components and their children

Create an import file for the resources that would be created, then import them using `pulumi import --file
'import.json'`.

Simplify the process by leveraging the [`preview`][pulumi preview] command.

<details style="padding-left: 1em">

1. Write some code that would create the components:

   ```ts
   import * as awsx from "@pulumi/awsx";

   const vpc = new awsx.ec2.Vpc("current");

   export const vpcId = vpc.vpcId;
   export const privateSubnetIds = vpc.privateSubnetIds;
   export const publicSubnetIds = vpc.publicSubnetIds;
   ```

1. Generate a placeholder import file for the resources that would be created:

   ```sh
   pulumi preview --import-file 'import.json'
   ```

   ```json
   {
    "resources": [
        {
            "type": "awsx:ec2:Vpc",
            "name": "current",
            "component": true
        },
        {
            "type": "aws:ec2/vpc:Vpc",
            "name": "currentVpc",
            "id": "<PLACEHOLDER>",
            "parent": "current",
            "version": "6.66.3",
            "logicalName": "current"
        },
        {
            "type": "aws:ec2/subnet:Subnet",
            "name": "current-public-1",
            "id": "<PLACEHOLDER>",
            "parent": "currentVpc",
            "version": "6.66.3"
        },
        …
   }
   ```

1. Change the IDs in the import file accordingly:

   ```diff
    {
     "resources": [
         {
             "type": "awsx:ec2:Vpc",
             "name": "current",
             "component": true
         },
         {
             "type": "aws:ec2/vpc:Vpc",
             "name": "currentVpc",
   -         "id": "<PLACEHOLDER>",
   +         "id": "vpc-abcdef26",
             "parent": "current",
             "version": "6.66.3",
             "logicalName": "current"
         },
         {
             "type": "aws:ec2/subnet:Subnet",
             "name": "current-public-1",
   -         "id": "<PLACEHOLDER>",
   +         "id": "subnet-0123456789abcdef0",
             "parent": "currentVpc",
             "version": "6.66.3"
         },
         …
    }
   ```

1. Import using the import file:

   ```sh
   pulumi import --file 'import.json'
   ```

</details>

## Troubleshooting

### A project with the same name already exists

Context: during project creation, Pulumi issues a warning saying that a project with the same name already exists.

Error message example:

> A project with the name infra already exists.

Root cause: Pulumi found a project with the same name saved in the backend.

Solution: Continue using the name if you are repurposing the project. Consider using a different name otherwise.

### Stack init fails because the stack supposedly already exists

Context: a stack fails to initialize.

Error message example:

> Sorry, could not create stack 'dev': stack 'organization/infra/dev' already exists

Root cause: Pulumi found a stack with the same name saved in the backend.

Solution: Delete the residual files for the stack from the backend and retry.

### Stack init fails due to missing scheme

Context: a stack fails to initialize.

Error message example:

> Sorry, could not create stack 'dev': open secrets.Keeper: no scheme in URL "awskms"

Root cause: the secrets provider is set to use a KMS key, but one did not provide any key identifier.

Solution: Read [secrets] and fix the configuration by providing a key identifier.

### Stack init fails due to invalid key identifier

Context: a stack fails to initialize.

Error message example:

> Sorry, could not create stack 'dev': unable to parse the secrets provider URL: parse
> "awskms://arn:aws:kms:eu-east-2:123456789012:key/aaaabbbb-cccc-dddd-eeee-ffff00001111": invalid port ":key" after host

Root cause: the secrets provider is set to use a KMS key, but one did not provide a correct key identifier.

Solution: Read [secrets] and fix the configuration by providing a correct key identifier.

### Change your program back to the original providers

Context: Typescript project, `preview` or `update` action.

Error message example:

> error: provider
> urn:pulumi:dev::projectName::pulumi:providers:aws::default_6_29_0::159e5843-63ae-4789-b332-4658578ba34c for resource
> urn:pulumi:dev::projectName::aws:ec2/instance:Instance::instanceName has not been registered yet, this is due to a
> change of providers mixed with --target. Change your program back to the original providers

Root cause: one is using a different provider version than the one the resource has been created with.

Solution:

1. Get the provider version the resource wants from the run output.
1. Fix the provider's version to the one wanted by the resource.
1. Run `pulumi install` to gather the required version.
1. Try the action again now.

### `Attempting to deploy or update resources with X pending operations from previous deployment`

Also see [Enable pulumi refresh to solve pending creates].

Context: one gets this kind of warning during an `update` action.

Warning message example:

> ```plaintext
> Diagnostics:
>   pulumi:pulumi:Stack (iam-internal-dev):
>     warning: Attempting to deploy or update resources with 19 pending operations from previous deployment.
>       * urn:pulumi:dev::iam-internal::aws:iam/userPolicyAttachment:UserPolicyAttachment::AllowUserSetupMfa-to-jonathan, interrupted while creating
>       * …
>       * urn:pulumi:dev::iam-internal::aws:iam/groupPolicyAttachment:GroupPolicyAttachment::amazonReadOnlyAccess-to-engineers, interrupted while creating
>     These resources are in an unknown state because the Pulumi CLI was interrupted while waiting for changes to these resources to complete. You should confirm whether or not the operations listed completed successfully by checking the state of the appropriate provider. For example, if you are using AWS, you can confirm using the AWS Console.
>
>     Once you have confirmed the status of the interrupted operations, you can repair your stack using `pulumi refresh` which will refresh the state from the provider you are using and clear the pending operations if there are any.
>
>     Note that `pulumi refresh` will need to be run interactively to clear pending CREATE operations.
> ```

Solution: follow the suggestion in the warning message:

1. Run `pulumi refresh` interactively.
1. Choose to clear the pending operations if the resource is created, or other options depending on the outcome.

## Further readings

- [Website]
- [Terraform]
- [Code examples]
- [Resources reference]
- [Things I wish I knew earlier about Pulumi]
- [Enable pulumi refresh to solve pending creates]
- [Docker images]

### Sources

- [Documentation]
- [Stacks]
- [State]
- [Assigning tags by default on AWS with Pulumi]
- [Organizing Pulumi projects & stacks]
- [Aligning Projects between Service and Self-Managed Backends]
- [Automatically Enforcing AWS Resource Tagging Policies]
- [Get started with Pulumi policy as code]
- [IaC Recommended Practices: Developer Stacks and Git Branches]
- [Update plans]
- [Pulumi up --plan without error message (exit code 255)]
- [Workshops]
- [Pulumi troubleshooting]
- [`pulumi new`][pulumi new]
- [`pulumi config set-all`][pulumi config set-all]
- [Importing resources]

<!--
  Reference
  ═╬═Time══
  -->

<!-- In-article sections -->
[backend]: #backend
[configuration]: #configuration
[enforce specific backends for projects]: #enforce-specific-backends-for-projects
[monolith vs micro-stack]: #monolith-vs-micro-stack
[program]: #program
[project]: #project
[stack]: #stack

<!-- Knowledge base -->
[terraform]: terraform.md

<!-- Files -->
<!-- Upstream -->
[aligning projects between service and self-managed backends]: https://www.pulumi.com/blog/project-scoped-stacks-in-self-managed-backend/
[automatically enforcing aws resource tagging policies]: https://www.pulumi.com/blog/automatically-enforcing-aws-resource-tagging-policies/
[blog]: https://www.pulumi.com/blog
[code examples]: https://github.com/pulumi/examples
[component resources]: https://www.pulumi.com/docs/iac/concepts/resources/components/
[deletebeforereplace]: https://www.pulumi.com/docs/concepts/options/deletebeforereplace/
[documentation]: https://www.pulumi.com/docs/
[enable pulumi refresh to solve pending creates]: https://github.com/pulumi/pulumi/pull/10394
[get started with pulumi policy as code]: https://www.pulumi.com/docs/using-pulumi/crossguard/get-started/
[google cloud static website]: https://www.pulumi.com/registry/packages/google-cloud-static-website/
[iac recommended practices: developer stacks and git branches]: https://www.pulumi.com/blog/iac-recommended-practices-developer-stacks-git-branches/
[ignorechanges]: https://www.pulumi.com/docs/concepts/options/ignorechanges/
[importing resources]: https://www.pulumi.com/docs/iac/adopting-pulumi/import/
[organizing pulumi projects & stacks]: https://www.pulumi.com/docs/using-pulumi/organizing-projects-stacks/
[projects]: https://www.pulumi.com/docs/concepts/projects/
[pulumi config set-all]: https://www.pulumi.com/docs/cli/commands/pulumi_config_set-all/
[pulumi crosswalk for aws]: https://www.pulumi.com/docs/iac/clouds/aws/guides/
[pulumi import]: https://www.pulumi.com/docs/iac/cli/commands/pulumi_import/
[pulumi new]: https://www.pulumi.com/docs/cli/commands/pulumi_new/
[pulumi preview]: https://www.pulumi.com/docs/iac/cli/commands/pulumi_preview/
[pulumi troubleshooting]: https://www.pulumi.com/docs/support/troubleshooting/
[pulumi up --plan without error message (exit code 255)]: https://github.com/pulumi/pulumi/issues/11303#issuecomment-1311365793
[resources reference]: https://www.pulumi.com/resources
[secrets]: https://www.pulumi.com/docs/concepts/secrets/
[stack references]: https://www.pulumi.com/docs/concepts/stack/#stackreferences
[stacks]: https://www.pulumi.com/docs/concepts/stack/
[state]: https://www.pulumi.com/docs/concepts/state/
[update plans]: https://www.pulumi.com/docs/concepts/update-plans/
[website]: https://www.pulumi.com/
[workshops]: https://github.com/pulumi/workshops

<!-- Others -->
[assigning tags by default on aws with pulumi]: https://blog.scottlowe.org/2023/09/11/assigning-tags-by-default-on-aws-with-pulumi/
[docker images]: https://hub.docker.com/u/pulumi
[things i wish i knew earlier about pulumi]: https://vsupalov.com/pulumi-learnings/
