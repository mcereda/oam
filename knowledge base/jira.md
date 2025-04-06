# Jira

1. [TL;DR](#tldr)
1. [Common actions](#common-actions)
   1. [Create scheduled tasks](#create-scheduled-tasks)
1. [Further readings](#further-readings)
   1. [Sources](#sources)

## TL;DR

```sh
# Create issues using the APIs.
curl "https://${COMPANY}.atlassian.net/rest/api/2/issue" \
  --dump-header '-' \
  --user "${USER_EMAIL}:${API_TOKEN}" \
  --header 'Content-Type: application/json' \
  --request 'POST' \
  --data '{
    "fields": {
      "project": {
        "key": "PROJECT_KEY"
      },
      "summary": "REST, ye merry gentlemen.",
      "description": "Creating of an issue using project keys and issue type names using the REST API",
      "issuetype": {
        "name": "Task"
      }
    }
  }'
```

## Common actions

### Create scheduled tasks

1. Go to _Project settings_ > _Automation_.
1. In the _Rules_ tab, click on the _Create rule_ button.
1. For the _When_ trigger, choose _Scheduled_.
1. Pick a schedule, or define a cron in the _Advanced_ section.
1. For the _Then_ component, choose _Create issue_.
1. Fill in the task's details.

## Further readings

### Sources

- [Creating JIRA issue using curl from command line]

<!--
  Reference
  ═╬═Time══
  -->

<!-- Others -->
[creating jira issue using curl from command line]: https://stackoverflow.com/questions/31052721/creating-jira-issue-using-curl-from-command-line#31052990
