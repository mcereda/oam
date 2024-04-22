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
1. [Troubleshooting](#troubleshooting)
   1. [A project with the same name already exists](#a-project-with-the-same-name-already-exists)
   1. [Stack init fails because the stack supposedly already exists](#stack-init-fails-because-the-stack-supposedly-already-exists)
   1. [Stack init fails due to missing scheme](#stack-init-fails-due-to-missing-scheme)
   1. [Stack init fails due to invalid key identifier](#stack-init-fails-due-to-invalid-key-identifier)
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


# Get the full program configuration.
# Secrets are obscured.
pulumi config get

# Set configuration values.
pulumi config set

# Copy the configuration over to other stacks.
pulumi config cp -d 'local'
pulumi config cp -s 'prod' -d 'dev'



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


# View stacks' state.
pulumi stack
pulumi stack -ius 'stack'
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


# Run in Docker.
docker run … -it \
  -v "$(pwd):/pulumi/projects" \
  -e 'AWS_ACCESS_KEY_ID' -e 'AWS_SECRET_ACCESS_KEY' -e 'AWS_REGION' \
  'pulumi/pulumi-nodejs:3.111.1-debian' \
  bash -c "npm ci && pulumi login 's3://bucket/prefix' && pulumi pre --parallel $(nproc) -s 'dev'"


# Plans
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
const clusterServiceRole = new aws.iam.Role("clusterServiceRole", {
    inlinePolicies: [{
        policy: encryptionKey.arn.apply(arn => JSON.stringify({
            Version: "2012-10-17",
            Statement: [{
                Effect: "Allow",
                Action: [
                    "kms:CreateGrant",
                    "kms:DescribeKey",
                ],
                Resource: arn,
            }],
        })),
    }]
});
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

If a resource is assigned a static name, the `deleteBeforeReplace` option _should be_ implicitly enabled.

### Assign tags to resources by default

Read [Assigning tags by default on AWS with Pulumi] first to get an idea of pros and cons of the options, then pick one
(or both):

1. Assign the wanted tags to the default provider in the stack's configuration file (`Pulumi.{stackName}.yaml`):

   ```yaml
   config:
     aws:defaultTags:
       tags:
         ManagedBy: "Pulumi",
         Owner: "user@company.com",
         Team: "Infra",
   ```

1. Create a new provider with the wanted tags defined in it, then explicitly use that provider with all the resources
   involved:

   ```ts
   const provider = new aws.Provider("provider", {
       defaultTags: {
           tags: {
               ManagedBy: "Pulumi",
               Owner: "user@company.com",
               Team: "Infra",
           },
       },
   });
   const fargateProfile = new aws.eks.FargateProfile("fargateProfile", {
       …
   }, {
       provider: provider,
       …
   });
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

## Further readings

- [Website]
- [Terraform]
- [Code examples]
- [Resources reference]

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

<!--
  References
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
[deletebeforereplace]: https://www.pulumi.com/docs/concepts/options/deletebeforereplace/
[documentation]: https://www.pulumi.com/docs/
[get started with pulumi policy as code]: https://www.pulumi.com/docs/using-pulumi/crossguard/get-started/
[iac recommended practices: developer stacks and git branches]: https://www.pulumi.com/blog/iac-recommended-practices-developer-stacks-git-branches/
[ignorechanges]: https://www.pulumi.com/docs/concepts/options/ignorechanges/
[organizing pulumi projects & stacks]: https://www.pulumi.com/docs/using-pulumi/organizing-projects-stacks/
[projects]: https://www.pulumi.com/docs/concepts/projects/
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
