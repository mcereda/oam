# Jira

## Table of contents <!-- omit in toc -->

1. [TL;DR](#tldr)
1. [Sources](#sources)

## TL;DR

```sh
# Create a ticket from the CLI.
curl https://${COMPANY}.atlassian.net/rest/api/2/issue \
  -D - \
  -u ${USER_EMAIL}:${API_TOKEN} \
  -H "Content-Type: application/json" \
  -X POST \
  --data '{
    "fields": {
      "project": {
        "key": "PROJECT_KEY"
      },
      "summary": "REST ye merry gentlemen.",
      "description": "Creating of an issue using project keys and issue type names using the REST API",
      "issuetype": {
        "name": "Task"
      }
    }
  }'
```

## Sources

- [Creating JIRA issue using curl from command line]

<!--
  References
  -->

<!-- Others -->
[creating jira issue using curl from command line]: https://stackoverflow.com/questions/31052721/creating-jira-issue-using-curl-from-command-line#31052990
