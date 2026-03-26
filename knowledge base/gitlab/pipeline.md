# CI/CD pipeline

Refer to [CI/CD pipelines] and [CI/CD pipeline templates].<br/>
Also check [Use CI/CD configuration from other files] and [Use extends to reuse configuration sections].

1. [Specify when to run jobs](#specify-when-to-run-jobs)
1. [Specify when to run entire pipelines](#specify-when-to-run-entire-pipelines)
1. [External secrets](#external-secrets)
   1. [AWS Secrets Manager](#aws-secrets-manager)
1. [API](#api)
1. [Git options](#git-options)
1. [Troubleshooting](#troubleshooting)
   1. [Pipeline fails with error `You are not allowed to download code from this project`](#pipeline-fails-with-error-you-are-not-allowed-to-download-code-from-this-project)
1. [Further readings](#further-readings)
   1. [Sources](#sources)

## Specify when to run jobs

Refer to [Specify when jobs run with `rules`][specify when jobs run with rules] and the
[`rules` syntax reference](https://docs.gitlab.com/ee/ci/yaml/#rules).

Use the `rules` key and specify the conditions the job needs.

> The `only`/`except` keywords have been deprecated by the `rules` keyword, and cannot be used together.<br/>
> This means one might be forced to use `only`/`except` if one is including a pipeline that is already using them.

Rules are evaluated when the pipeline is created, **in order**, until the first applies. The rest are ignored.

The `rules`key accepts an array of rules.<br/>
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
  When this condition is used, `allow_failure`for the job defaults to `false`.
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
- Glob patterns in `changes` and `exists` are interpreted with Ruby's `File.fnmatch` function using the
  `File::FNM_PATHNAME | File::FNM_DOTMATCH | File::FNM_EXTGLOB` flag.
- The [`push` pipeline source](https://docs.gitlab.com/ee/user/project/integrations/webhook_events.html#push-events)
  should™ limit jobs to code changes or deliberate pushes.<br/>
  Scheduled pipelines should™ avoid triggering jobs with this condition as they present a `schedule` source instead.

  Using the `merge_request_event` source in place of `push` prevents the job to run should somebody push to the default
  branch, even though
  [the documentation clearly states it includes merges](https://docs.gitlab.com/ee/user/project/integrations/webhook_events.html#merge-request-events).

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
          - infra/packages.json
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
```

</details>

## Specify when to run entire pipelines

Refer the [`workflow.rules` syntax reference](https://docs.gitlab.com/ee/ci/yaml/#workflowrules).

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
        - packages.json
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
    SOME_SECRET_VAR:
      aws_secrets_manager:
        secret_id: "some-secret-name"   # the secret name or ARN in Secrets Manager
        field: "some_field"             # optional: extract a specific key from a JSON secret
      file: false                       # false = env var, true = file (default: true)
  script:
    - echo "Secret is available as $SOME_SECRET_VAR"
```

</details>

Runners using the Docker autoscaler executor can authenticate by assuming an IAM role, or via OIDC tokens or static
credentials.<br/>
Runners using the Kubernetes executor can authenticate via EKS Pod Identity an IAM role, OIDC tokens, or static
credentials.

If using IAM roles, the runners' role must have `secretsmanager:GetSecretValue` on the secrets' ARNs.

By default, GitLab writes secrets to a file, and sets the variable to that file's path. If `file: false`, it injects the
secret's value directly as an environment variable.
JSON-formatted secrets allow using fields to extract specific keys. Omit `field` to get the entire secret value.

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

- [Gitlab]
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

<!-- Knowledge base -->
[gitlab]: README.md

<!-- Files -->
<!-- Upstream -->
[ci/cd pipeline templates]: https://gitlab.com/gitlab-org/gitlab/-/tree/master/lib/gitlab/ci/templates
[ci/cd pipelines]: https://docs.gitlab.com/ci/pipelines/
[customize pipeline configuration]: https://docs.gitlab.com/ci/pipelines/settings.html
[debugging ci/cd pipelines]: https://docs.gitlab.com/ci/debugging.html
[pipeline schedules api]: https://docs.gitlab.com/api/pipeline_schedules.html
[Predefined CI/CD variables reference]: https://docs.gitlab.com/ci/variables/predefined_variables/
[push options]: https://docs.gitlab.com/user/project/push_options.html
[specify when jobs run with rules]: https://docs.gitlab.com/ci/jobs/job_rules.html
[Use AWS Secrets Manager secrets in GitLab CI/CD]: https://docs.gitlab.com/ci/secrets/aws_secrets_manager/
[use ci/cd configuration from other files]: https://docs.gitlab.com/ci/yaml/includes.html
[use extends to reuse configuration sections]: https://docs.gitlab.com/ci/yaml/yaml_optimization.html#use-extends-to-reuse-configuration-sections
[using external secrets in ci]: https://docs.gitlab.com/ci/secrets/index.html
[validate gitlab ci/cd configuration]: https://docs.gitlab.com/ci/lint.html

<!-- Others -->
[using gitlab scheduled pipelines simplified 101]: https://hevodata.com/learn/gitlab-scheduled-pipeline/
