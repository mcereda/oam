# CI/CD pipeline

Refer to [CI/CD pipelines].<br/>
Also check [Use CI/CD configuration from other files] and [Use extends to reuse configuration sections].

1. [TL;DR](#tldr)
1. [Specify when to run jobs](#specify-when-to-run-jobs)
1. [Specify when to run entire pipelines](#specify-when-to-run-entire-pipelines)
1. [External secrets](#external-secrets)
   1. [AWS Secrets Manager](#aws-secrets-manager)
1. [Reusability](#reusability)
   1. [Pipeline templates](#pipeline-templates)
   1. [Pipeline components](#pipeline-components)
   1. [Templates vs Components](#templates-vs-components)
1. [Cross-project pipelines](#cross-project-pipelines)
1. [Serializing jobs](#serializing-jobs)
   1. [Resource groups](#resource-groups)
   1. [Merge trains](#merge-trains)
1. [API](#api)
1. [Git options](#git-options)
1. [Troubleshooting](#troubleshooting)
    1. [Pipeline fails with error `You are not allowed to download code from this project`](#pipeline-fails-with-error-you-are-not-allowed-to-download-code-from-this-project)
1. [Further readings](#further-readings)
    1. [Sources](#sources)

## TL;DR

TODO: define pipelines

TODO: define jobs

Jobs are **_hidden_** when their name is prefixed with a dot (e.g., `.build-docker-image:`).<br/>
Hidden jobs need to be _extended_ (`extends:`) or otherwise referenced (e.g., via [YAML anchors and aliases]) by others
to be used.

## Specify when to run jobs

Refer to [Specify when jobs run with `rules`][specify when jobs run with rules] and the
[`rules` syntax reference](https://docs.gitlab.com/ee/ci/yaml/#rules).

Use the `rules` key and specify the conditions the job needs.

> The `only`/`except` keywords have been deprecated by the `rules` keyword, and cannot be used together.<br/>
> This means one might be forced to use `only`/`except` if one is including a pipeline that is already using them.

Rules are evaluated when the pipeline is created, **in order**, until the first applies. The rest are ignored.

The `rules` key accepts an array of rules.<br/>
Each rule:

- Must have **at least one** of:

  - `if`, to run a job when specific conditions are met.
  - `changes`, to run a job when specific files changed.
  - `exists`, to run a job when certain files exist in the repository.
  - `when`, to run a job when exact conditions are met.

- Can have **zero or more** of:

  - `allow_failure`, to allow a job to fail without stopping the pipeline.<br/>
    Defaults to `false`.
  - `needs`, to specify conditions for the job to run.
  - `variables`, to define specific variables for the job.
  - `interruptible`, to cancel the current job should another pipeline start.

Multiple keys from the above lists can be combined to create complex rules.

`when` accepts the following:

- `on_success` (default): run the job only when no jobs in earlier stages fail, or the failing ones are allowed to fail
  with `allow_failure: true`.<br/>
  This is the default behavior when one combines `when` with `if`, `changes`, or `exists`.
- `on_failure`: run the job only when at least one job in an earlier stage fails.
- `never`: don't run the job regardless of the status of jobs in earlier stages.
- `always`: run the job regardless of the status of jobs in earlier stages.
- `manual`: add the job to the pipeline as a manual job.
  When this condition is used, `allow_failure` for the job defaults to `false`.
- `delayed`: add the job to the pipeline as a delayed job.

Jobs are **added** to the pipeline if:

- An `if`, `changes`, or `exists` rule matches **and** the rule is configured with `when: on_success` (default if not
  defined), `when: delayed`, or `when: always`.
- A rule is reached that only consists of `when: on_success`, `when: delayed`, or `when: always`.

Jobs are **not** added to the pipeline if:

- No rule matches.
- A rule matches **and** the rule is configured with `when: never`.

Gotchas:

- Tag pipelines, scheduled pipelines, and manual pipelines do **not** have a Git push event associated with them.
- `changes` always evaluates to true for new branch pipelines or when there is no Git push event.<br/>
  This means it will try to run on tag, scheduled and manual pipelines. Use `changes.compare_to` to specify the branch
  to compare against.
- `changes` and `exists` allow a maximum of 50 patterns or file paths.
- Multiple entries in the `changes` condition are validated in an `OR` fashion.
- Glob patterns in `changes` and `exists` follow `FNM_PATHNAME | FNM_DOTMATCH | FNM_EXTGLOB` semantics.

  A single `*` does **not** cross directories. A pattern like `*.ts` matches only root-level files, and changes to files
  in subdirectories do **not** trigger the job (no error, no preview, no deploy on merge).<br/>
  Use `**/*.ts` for recursive matching, or list explicit per-directory globs.

- The [`push` pipeline source events] should™ limit jobs to code changes or deliberate pushes.<br/>
  Scheduled pipelines should™ avoid triggering jobs with this condition as they present a `schedule` source instead.

  Using the `merge_request_event` source in place of `push` prevents the job from running when changes land on the
  default branch, since merging an MR produces a `push` event on the target branch, not a `merge_request_event`.

  [Linting](https://docs.gitlab.com/ee/ci/lint.html#check-cicd-syntax) and
  [simulations](https://docs.gitlab.com/ee/ci/lint.html#simulate-a-pipeline) seem to accept using other ways, but then
  the pipeline resulted to be **invalid** after committing those _"validated"_ changes:

  > 🛑 Unable to create pipeline
  >
  > Failed to parse rule for test-job: rules:changes:compare_to is not a valid ref

Examples:

<details>
  <summary>Run when some specific files change</summary>

```yaml
docker-build:
  rules:
    - changes:
        - cmd/*
        - go.*
        - Dockerfile

pulumi-update:
  rules:
    # This job should only be created for changes to the main branch, and only if any program-related file changed.
    - if: >-
        $CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH
        && $CI_PIPELINE_SOURCE == "push"
      changes:
        paths:
          - infra/*.ts
          - infra/package.json
    - when: never
```

The condition above will make the job run only when a change occurs:

- to any file in the `cmd` directory
- to any file in the repository's root directory which name starts with `go` (like `go.mod` or `go.sum`)
- to the `Dockerfile` in the repository's root directory

</details>
<details>
  <summary>Run on schedules</summary>

```yaml
docker-build:
  rules:
    - if: $CI_PIPELINE_SOURCE == "schedule"

docker-run:
  only:
    - schedule
```

Refer to [Using GitLab scheduled pipelines simplified 101] to configure and activate schedules.<br/>
Manually trigger scheduled pipelines from the UI or using the API:

```plaintext
POST /projects/:id/pipeline_schedules/:pipeline_schedule_id/play
```

```sh
curl -X POST -H "PRIVATE-TOKEN: glpat-m-…" "https://gitlab.example.com/api/v4/projects/42/pipeline_schedules/1/play"
```

The triggered pipeline runs immediately.<br/>
The next scheduled run of the pipeline is **not** affected.

</details>
<details>
  <summary>Only run on specific events</summary>

```yaml
docker-build:
  rules:
    - if: $CI_PIPELINE_SOURCE == 'merge_request_event'
    - if: $CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH
    - # Disable for all other conditions
      when: never
```

</details>
<details>
  <summary>Run on all conditions except specific ones</summary>

```yaml
docker-build:
  rules:
    - if: $CI_PIPELINE_SOURCE == 'merge_request_event'
      when: never
    - when: on_success
```

</details>

## Specify when to run entire pipelines

Refer to the [`workflow.rules` syntax reference](https://docs.gitlab.com/ee/ci/yaml/#workflowrules).

The `workflow.rules` keyword is similar to the `rules` keyword defined in jobs, but controls whether or not a whole
pipeline is created.<br/>
When no rules evaluate to `true`, the pipeline as a whole will not run.

```yaml
workflow:
  rules:
    - # Override the globally-defined DEPLOY_VARIABLE on commits on the default branch.
      if: $CI_COMMIT_REF_NAME == $CI_DEFAULT_BRANCH
      variables:
        DEPLOY_VARIABLE: "deploy-production"
    - # Add a new variable on commits containing 'feature'.
      if: $CI_COMMIT_REF_NAME =~ /feature/
      variables:
        IS_A_FEATURE: "true"
    - # Skip on commits ending with '-draft'.
      if: $CI_COMMIT_TITLE =~ /-draft$/
      when: never
    - # Run for merge requests where key files changed.
      if: $CI_PIPELINE_SOURCE == "merge_request_event"
      changes:
        - package.json
    - when: always                            # Run the pipeline in other cases.
```

## External secrets

Refer to [Using external secrets in CI].

### AWS Secrets Manager

Refer to [Use AWS Secrets Manager secrets in GitLab CI/CD].

Jobs support the `secrets.aws_secrets_manager` keyword to inject secrets from AWS Secrets Manager into CI/CD jobs as
environment variables or as files.

<details style='padding: 0 0 1rem 1rem'>

```yml
some_job:
  variables:
    AWS_REGION:
      # REQUIRED: jobs will error out with "Secrets provider can not be found" if missing
      # can be here or at the pipeline level
      # setting AWS_DEFAULT_REGION does *not* work, the integration requires AWS_REGION
      eu-west-1
  secrets:
    SOME_SECRET_VAR:                    # environment variable that will contain the value
      aws_secrets_manager:
        secret_id: "some-secret-name"   # the secret name or ARN in Secrets Manager
        field: some_field               # optional: extract a specific key from a JSON secret
      file:
        # false to store the value in the environment variable directly
        # true to store the value as file (default); the environment variable stores the path to the file
        false
    SOME_OTHER_SECRET_VAR:
      aws_secrets_manager:
        secret_id: "arn:aws:secretsmanager:us-east-1:012345678901:secret:shared-api-keys-AbCdEf"
        version_id: '01234567-89ab-cdef-0123-456789abcdef'  # specific secret's version by ID
    SOME_OTHER_OTHER_SECRET_VAR:
      aws_secrets_manager:
        secret_id: "some/other/other/secret/name"                      # the secret name or ARN in Secrets Manager
        version_stage: 'AWSCURRENT'                                    # specific secret's version by AWS label
        region: eu-west-1
        role_arn: 'arn:aws:iam::123456789012:role/eu-deployment-role'  # role to assume
        role_session_name: gitlab-eu-deployment                        # name for the assume role session
      file: true                                                       # explicitly save the value as file
  script:
    - echo "Some secret is '$SOME_SECRET_VAR'"
    - echo "Some other secret is '$SOME_OTHER_SECRET_VAR'"
    - echo "Some other other secret is '$SOME_OTHER_OTHER_SECRET_VAR'"
```

</details>

Runners using the Docker autoscaler executor can authenticate by assuming an IAM role, or via OIDC tokens or static
credentials.<br/>
Runners using the Kubernetes executor can authenticate via EKS Pod Identity, an IAM role, OIDC tokens, or static
credentials.

If using IAM roles, the runners' role must have `secretsmanager:GetSecretValue` on the secrets' ARNs.

By default, GitLab writes secrets to a file, and sets the variable to that file's path. If `file: false`, it injects the
secret's value directly as an environment variable.
JSON-formatted secrets allow using fields to extract specific keys. Omit `field` to get the entire secret value.

> [!note]
> On self-managed GitLab, the `ci_aws_secrets_manager` feature flag _may_ need to be **explicitly** enabled even if GA:
>
> ```sh
> curl -fsX 'PUT' 'https://gitlab.example.org/api/v4/features/ci_aws_secrets_manager' \
>   -H 'PRIVATE-TOKEN: glpat-…' -d 'value=true'
> ```
>
> This is an instance-wide admin operation.

## Reusability

### Pipeline templates

Also see [CI/CD pipeline templates].

_Templates_ are regular YAML files that usually define hidden jobs.<br/>
Consumers `include:` the template file and optionally `extends:` the jobs they provide, usually overriding their
attributes to customize their behavior.

Templates are meant to be flexible and composable.

<details>
  <summary>Example</summary>

Template file in some git repository (e.g., `example-org/ci-cd/pipelines/templates/build-docker-image.yml`):

```yml
.build-docker-image:
  stage: build
  image: docker.io/library/docker:26.0.1
  variables:
    BUILD_PATH: $CI_PROJECT_DIR
    IMAGE_NAME: $CI_PROJECT_NAME
    PLATFORM: linux/amd64
    PUSH: false
  script:
    - aws ecr get-login-password | docker login --username AWS --password-stdin "$CI_REGISTRY"
    - docker buildx build --platform=$PLATFORM --tag=$IMAGE_NAME $BUILD_PATH
```

Pipeline file in another git repository:

```yml
include:
  - project: 'example-org/ci-cd'
    ref: main
    file: '/pipelines/templates/build-docker-image.yml'

my-image - build and push:
  extends: .build-docker-image
  variables:
    BUILD_PATH: ${CI_PROJECT_DIR}/docker
    IMAGE_NAME: my-service
    PLATFORM: linux/arm64,linux/amd64
    PUSH: 'true'
```

</details>

Templates work on any GitLab version.

Templates' inputs have no type and are undocumented at the YAML level (the author can write a comment block, but
consumers need to access the template's code to read it).<br/>
This also means there is **no** validation whatsoever, where a typo in a variable name will make it default _silently_.

Version pinning is done via `ref:`, which accepts a branch, tag, or SHA. Branch refs (`ref: main`) are mutable, so a
breaking change hits all consumers immediately. Tag or SHA refs are stable pins.

### Pipeline components

Components are YAML files that live under the `templates/` folder at the root of a repository.<br/>
GitLab's component resolution **hardcodes** the `templates/<component-name>/template.yml` and
`templates/<component-name>.yml` paths. One cannot nest them under other folders like `pipelines/templates/` nor rename
that directory.

They come with a `spec:` header that declares typed and validated inputs.<br/>
Consumers can include a component using the `component:` syntax and pass inputs to it explicitly. GitLab rejects the
pipeline if a required input is missing or the wrong type.

<details>
  <summary>Example</summary>

Component file in some git repository (e.g., `example-org/ci-cd/templates/docker-build/template.yml`):

```yml
spec:
  inputs:
    build-path:
      default: $CI_PROJECT_DIR
      description: 'Path to the build context'
    image-name:
      default: $CI_PROJECT_NAME
      description: 'Name of the Docker image'
    platform:
      default: 'linux/amd64'
      description: 'Target platform(s), comma-separated'
    push:
      type: boolean
      default: false
      description: 'Whether to push the built image'
    ecr-repository:
      description: 'ECR repository prefix (e.g. example-org)'
    extra-opts:
      default: ''
      description: 'Additional docker buildx build flags'

---

docker-build:
  stage: build
  image: 012345678901.dkr.ecr.eu-west-2.amazonaws.com/cache/library/docker:26.0.1
  variables:
    CI_REGISTRY: 012345678901.dkr.ecr.eu-west-2.amazonaws.com
    BUILDER_NAME: tmp-$CI_JOB_ID
  before_script:
    - docker buildx create --driver docker-container --name "$BUILDER_NAME" --use
  script:
    - aws ecr get-login-password | docker login --username AWS --password-stdin "$CI_REGISTRY"
    - |
        ECR_URI=$(echo "$CI_REGISTRY/$[[ inputs.ecr-repository ]]/$[[ inputs.image-name ]]" | sed -E 's|/+|/|g; s|^/||; s|/$||')

        BUILD_OPTS="--file=$[[ inputs.build-path ]]/Dockerfile"
        BUILD_OPTS="$BUILD_OPTS --platform=$[[ inputs.platform ]]"
        BUILD_OPTS="$BUILD_OPTS --tag=$ECR_URI:$CI_COMMIT_SHORT_SHA"

        if [ "$[[ inputs.push ]]" = "true" ]; then
          aws ecr describe-repositories --repository-names "$ECR_URI" 2>/dev/null \
            || aws ecr create-repository --repository-name "$ECR_URI"
          BUILD_OPTS="$BUILD_OPTS --push"
        fi

        BUILD_OPTS="$BUILD_OPTS $[[ inputs.extra-opts ]]"
        docker buildx build $BUILD_OPTS $[[ inputs.build-path ]]
  after_script:
    - docker buildx rm "$BUILDER_NAME"
```

Pipeline file in another git repository:

```yml
include:
  - component: gitlab.example.org/example-org/ci-cd/docker-build@1.0.0
    inputs:
      build-path: ${CI_PROJECT_DIR}
      image-name: my-service
      ecr-repository: example-org
      platform: 'linux/arm64,linux/amd64'
      push: true
      extra-opts: '--build-arg "REVISION=$CI_COMMIT_SHORT_SHA"'
```

</details>

Key differences from [pipeline templates] in the definition:

- `spec.inputs:` defines the inputs, which replaces the need for documentation in comments.
- Each input specifies a **type** (`string` by default, but also `number`, `boolean`, or `array`), if it has a default
  (omit the `default:` key to make the job require that input), and a description.
- The `$[[ inputs.name ]]` interpolation format replaces `$VARIABLE` overrides.
- The `---` separator divides the specification from the jobs' definition.

The `@<git-ref>` part in the `component:` key pins the component to a specific git tag, SHA or branch.

Components require GitLab version 17.0.

GitLab **does** validate inputs for component when a pipeline is created, **before** parsing its YAML.<br/>
A wrong type, a missing required input, or an unknown input name all fail loudly. Versioning is explicit.<br/>
Components show up in the CI/CD Catalog, which allows teams to discover what's available.

### Templates vs Components

[Pipeline components] are stricter and safer than [pipeline templates]. Their idea is that they define a job that can be
_tweaked_ with specific knobs.<br/>
Templates are better when needing to define the _skeleton_ of a job and allow one to _override_ it to fill in whatever
they need.

Prefer templates when:

- Their consumer needs to override the templates' **structure**, and not just the values they expose.

  Templates allow consumers to override any of their key (e.g., `script:`, `before_script:`, `rules:`, `stage:`,
  etc).<br/>
  Components produce a **complete** job that only allows tweaking. The consumer can't surgically replace a section with
  a complete override.

- The job is an external CI configuration piece that a **different** repository wants to use.
- One needs to allow composition via `!reference` to inject fragments into another job.<br/>
  Since components produce whole jobs, they do **not** provide fragments one can splice into other jobs.

Prefer components when:

- The reusable unit is a **complete** job that defines a clear input **contract**.<br/>
  The consumer shouldn't need to know the job's internals.
- One wants **validation** of the job's inputs at pipeline creation time.<br/>
  Missing a required variable in a template makes that variable default silently. Missing a required input for a
  component fails the pipeline before any job runs.
- Multiple teams consume it.<br/>
  Catalog discoverability and version pinning allow teams to adopt components without needing to read its source or
  asking the author.
- One needs safe and independent versioning.<br/>
  @1.0.0 means the consumer is insulated from changes until they choose to bump. `ref: main` means one is on the latest
  version in a branch or tag whether they wanted it or not.

## Cross-project pipelines

Refer to [Downstream pipelines].

A pipeline in one project (Project A) can _trigger_ a pipeline in another project (Project B) using the `trigger:`
keyword in a job:

```yaml
deploy_to_shared_infra:
  stage: deploy
  variables:  # override variables using the same name in the target job
    IMAGE_TAG: $CI_COMMIT_SHA
  trigger:
    project: shared-infra/deploy
    branch: main
    strategy: depend  # reflect the outcome of the targeted job
```

CI/CD variables defined in the GUI for Project A are **not** passed automatically to the targeted job. One needs to
re-declare them in `variables:` if needed.<br/>
One can also pass artifacts via dotenv reports (`needs:project`), usually a good way to pass structured variables
cross-project.

Cross-project triggers do **not** support `script:`, and hence cannot _modify_ targeted jobs.

> [!important]
> The user (or token) starting the job must have `pipeline-start` permissions on the downstream project.

## Serializing jobs

Both [resource groups] and [merge trains] serialize job runs, but at different layers:

- Merge trains serialize at the _merge_ layer by allowing only one **MR** to merge to the main branch at a time.
- Resource groups serialize at the _job_ layer by allowing only one **job** in the group to run at a time.

> [!tip]
> IaC pipelines are one of the best use cases for which consider enabling merge trains on the repository **and** using
> resource groups on deploy jobs.

### Resource groups

Refer to [Resource group].

`resource_group` prevents two jobs with the same group name from running simultaneously, no matter how many pipelines
are in flight.<br/>
This is the most direct way to serialize deploys against shared targets (e.g., Pulumi stacks, databases, environments).

```yaml
deploy_prd:
  resource_group: pulumi/myapp/prd
  script: pulumi --cwd 'infra' up --stack 'prd'
```

If a second pipeline tries to run a job with the same `resource_group` while the first is running, it waits in the queue
instead of failing or trampling the first.

Useful patterns:

- **Per-stack/per-environment** (`resource_group: pulumi/<project>/<stack>`): prevents two `pulumi up` runs from
  racing.
- **Per-shared-database** (`resource_group: db-migrations/<env>`): prevents two migration jobs from competing.

> [!tip]
> Combine this with `interruptible: false` on jobs that, if interrupted, would leave a corrupted state behind.

### Merge trains

Refer to [Merge trains documentation].

When multiple MRs land on `main` near-simultaneously, each one's pipeline runs against a different main commit, which
can cause race conditions.<br/>
Use merge trains to serialize them and make each MR rebase onto the latest main _before_ its pipeline runs.

## API

Refer to [Pipeline schedules API].

## Git options

Refer to [Push options].

```sh
# Skip *branch* pipelines for the latest push.
# Does *not* skip merge request pipelines or pipelines for integrations.
git push -o 'ci.skip'

# Skip pipelines *for integrations* for the latest push.
# Does *not* skip branch or merge request pipelines.
git push -o 'integrations.skip_ci'

# Provide variables to pipelines created due to the push.
# Passes variables only to *branch* pipelines, and *not* to merge request pipelines.
git push -o ci.variable="MAX_RETRIES=10" -o ci.variable="MAX_TIME=600"
```

## Troubleshooting

### Pipeline fails with error `You are not allowed to download code from this project`

Error message example:

```txt
Getting source from Git repository 00:00
Fetching changes with git depth set to 20...
Reinitialized existing Git repository in /builds/myProj/myRepo/.git/
remote: You are not allowed to download code from this project.
fatal: unable to access 'https://gitlab.com/myProj/myRepo.git/': The requested URL returned error: 403
```

Root cause: the user starting the pipeline does not have enough privileges to the repository.

Solution: give that user _developer_ access or have somebody else with enough privileges run it.

## Further readings

- [GitLab]
- [CI/CD pipelines]
- [Customize pipeline configuration]
- [Predefined CI/CD variables reference]
- [Pipeline schedules API]
- [Using external secrets in CI]

### Sources

- [Specify when jobs run with `rules`][specify when jobs run with rules]
- [Using GitLab scheduled pipelines simplified 101]
- [Debugging CI/CD pipelines]
- [Push options]
- [Validate GitLab CI/CD configuration]

<!--
  Reference
  ═╬═Time══
  -->

<!-- In-article sections -->
[Merge trains]: #merge-trains
[Pipeline components]: #pipeline-components
[Pipeline templates]: #pipeline-templates
[Resource groups]: #resource-groups

<!-- Knowledge base -->
[GitLab]: ../gitlab.md
[YAML anchors and aliases]: ../yaml.md#anchors-and-aliases

<!-- Files -->
<!-- Upstream -->
[`push` pipeline source events]: https://docs.gitlab.com/ee/user/project/integrations/webhook_events.html#push-events
[ci/cd pipeline templates]: https://gitlab.com/gitlab-org/gitlab/-/tree/master/lib/gitlab/ci/templates
[ci/cd pipelines]: https://docs.gitlab.com/ci/pipelines/
[customize pipeline configuration]: https://docs.gitlab.com/ci/pipelines/settings.html
[debugging ci/cd pipelines]: https://docs.gitlab.com/ci/debugging.html
[Downstream pipelines]: https://docs.gitlab.com/ci/pipelines/downstream_pipelines/
[Merge trains documentation]: https://docs.gitlab.com/ee/ci/pipelines/merge_trains.html
[pipeline schedules api]: https://docs.gitlab.com/api/pipeline_schedules.html
[Predefined CI/CD variables reference]: https://docs.gitlab.com/ci/variables/predefined_variables/
[push options]: https://docs.gitlab.com/user/project/push_options.html
[Resource group]: https://docs.gitlab.com/ee/ci/yaml/#resource_group
[specify when jobs run with rules]: https://docs.gitlab.com/ci/jobs/job_rules.html
[Use AWS Secrets Manager secrets in GitLab CI/CD]: https://docs.gitlab.com/ci/secrets/aws_secrets_manager/
[use ci/cd configuration from other files]: https://docs.gitlab.com/ci/yaml/includes.html
[use extends to reuse configuration sections]: https://docs.gitlab.com/ci/yaml/yaml_optimization.html#use-extends-to-reuse-configuration-sections
[using external secrets in ci]: https://docs.gitlab.com/ci/secrets/index.html
[validate gitlab ci/cd configuration]: https://docs.gitlab.com/ci/lint.html

<!-- Others -->
[using gitlab scheduled pipelines simplified 101]: https://hevodata.com/learn/gitlab-scheduled-pipeline/
