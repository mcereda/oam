# CI/CD pipeline

Refer to [CI/CD pipelines] and [CI/CD pipeline templates].<br/>
Also check [Use CI/CD configuration from other files] and [Use extends to reuse configuration sections].

1. [Specify when to run jobs](#specify-when-to-run-jobs)
1. [Troubleshooting](#troubleshooting)
   1. [Pipeline fails with error `You are not allowed to download code from this project`](#pipeline-fails-with-error-you-are-not-allowed-to-download-code-from-this-project)
1. [Further readings](#further-readings)
   1. [Sources](#sources)

## Specify when to run jobs

Refer [Specify when jobs run with `rules`][specify when jobs run with rules].

Use the `rules` key and specify the conditions the job needs.

> The `only`/`except` keywords have been deprecated by the `rules` keyword, and cannot be used together.<br/>
> This means one might be forced to use `only`/`except` if one is including a pipeline that is already using them.

Conditions are validated **in order** until one applies. The rest are ignored.<br/>
If no condition applies, the job is skipped.<br/>
The default condition is `on_success`.

Run when some specific files change:

```yaml
docker-build:
  rules:
    - changes:
        - cmd/*
        - go.*
        - Dockerfile

docker-run:
  only:
    changes:
      - cmd/*
      - …
```

Multiple entries in the `changes` condition are validated in an `OR` fashion. In the example above, the condition will make the
job run only when a change occurs:

- to any file in the `cmd` directory
- to any file in the repository's root directory which name starts with `go` (like `go.mod` or `go.sum`)
- to the `Dockerfile` in the repository's root directory

Run on schedules:

```yaml
docker-build:
  rules:
    - if: $CI_PIPELINE_SOURCE == "schedule"

docker-run:
  only:
    - schedule
```

Refer [Using GitLab scheduled pipelines simplified 101] to configure and activate schedules.

Only run on specific events:

```yaml
docker-build:
  rules:
    - if: $CI_PIPELINE_SOURCE == 'merge_request_event'
    - if: $CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH
    - # Disable for all other conditions
      when: never
```

Run on all conditions except specific ones:

```yaml
docker-build:
  rules:
    - if: $CI_PIPELINE_SOURCE == 'merge_request_event'
      when: never
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

### Sources

- [Specify when jobs run with `rules`][specify when jobs run with rules]
- [Using GitLab scheduled pipelines simplified 101]

<!--
  Reference
  ═╬═Time══
  -->

<!-- Knowledge base -->
[gitlab]: README.md

<!-- Files -->
<!-- Upstream -->
[ci/cd pipeline templates]: https://gitlab.com/gitlab-org/gitlab/-/tree/master/lib/gitlab/ci/templates
[ci/cd pipelines]: https://docs.gitlab.com/ee/ci/pipelines/
[customize pipeline configuration]: https://docs.gitlab.com/ee/ci/pipelines/settings.html
[predefined ci/cd variables reference]: https://docs.gitlab.com/ee/ci/variables/predefined_variables.html
[specify when jobs run with rules]: https://docs.gitlab.com/ee/ci/jobs/job_rules.html
[use ci/cd configuration from other files]: https://docs.gitlab.com/ee/ci/yaml/includes.html
[use extends to reuse configuration sections]: https://docs.gitlab.com/ee/ci/yaml/yaml_optimization.html#use-extends-to-reuse-configuration-sections

<!-- Others -->
[using gitlab scheduled pipelines simplified 101]: https://hevodata.com/learn/gitlab-scheduled-pipeline/
