# Logging

> TODO

Recording of events or actions.

<!-- Remove this line to uncomment if used
## Table of contents <!-- omit in toc -->

1. [TL;DR](#tldr)
1. [Level](#level)
1. [Further readings](#further-readings)
   1. [Sources](#sources)

## TL;DR

Usually composed at least by:

- Timestamp.
- Level (A.K.A. Severity).
- Message.
- Other metadata.

Long term storage is frequently cause of concern.<br/>
Analysis and search is extremely difficult and computationally expensive at scale.<br/>
Locality and standardization are often issues, with each application storing their own logs in their own format on their
own files in different locations. Finding a way to bring all those into a central location for analysis is one of the
goals of aggregation solutions.

## Level

| Level       | Summary                                                                                            |
| ----------- | -------------------------------------------------------------------------------------------------- |
| Debug       | **Detailed** contextual information used during development or for troubleshooting                 |
| Information | Normal, expected events                                                                            |
| Warning     | Situations that are unexpected but not errors; can potentially lead to problems if ignored         |
| Error       | Issues that need immediate attention, but might not require termination of operations              |
| Critical    | Failures or events that require immediate and decisive attention, where operations cannot continue |

## Further readings

- Grafana's [Loki]
- [Fluentd] / [Fluent Bit]
- [LogStash]

### Sources

- [Distributed logging for Microservices]
- [Intro to Logging | Zero to Hero: Loki | Grafana]
- [Structure of Logs (Part 1) | Zero to Hero: Loki | Grafana]

<!--
  Reference
  ═╬═Time══
  -->

<!-- In-article sections -->
<!-- Knowledge base -->
[fluent bit]: fluent%20bit.md
[fluentd]: fluentd.md
[logstash]: logstash.md
[loki]: loki.md

<!-- Files -->
<!-- Upstream -->
<!-- Others -->
[distributed logging for microservices]: https://www.geeksforgeeks.org/distributed-logging-for-microservices/
[Intro to Logging | Zero to Hero: Loki | Grafana]: https://www.youtube.com/watch?v=TLnH7efQNd0
[Structure of Logs (Part 1) | Zero to Hero: Loki | Grafana]: https://www.youtube.com/watch?v=cnhnoFz6xu0
