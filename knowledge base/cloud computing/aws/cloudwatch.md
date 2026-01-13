# CloudWatch

Observability service. with functions for logging, monitoring and alerting.

1. [TL;DR](#tldr)
1. [Queries of interest](#queries-of-interest)
1. [Stream logs](#stream-logs)
1. [Cost-saving measures](#cost-saving-measures)
1. [Further readings](#further-readings)
   1. [Sources](#sources)

## TL;DR

_Metrics_ are whatever needs to be monitored (e.g. CPU usage).<br/>
_Data points_ are the values of a metric over time.<br/>
_Namespaces_ are containers for metrics.

Metrics only exist in the region in which they are created.

[Many AWS services][services that publish cloudwatch metrics] offer basic monitoring by publishing a default set of
metrics to CloudWatch with no charge.<br/>
This feature is automatically enabled by default when one starts using one of these services.

API calls for CloudWatch are **paid**. This **includes** sending logs and metrics to it.<br/>
Refer [Which log group is causing a sudden increase in my CloudWatch Logs bill?] to get an idea of what changed in some
time frame.

It's best practice to **distribute** the `ListMetrics` call to avoid throttling.<br/>
The default limit for `ListMetrics` is 25 transactions per second.

The [CloudWatch console] offers some default good queries.

Logs in Log Groups can be [streamed][stream logs] elsewhere.

CloudWatch retains metrics' data as follows:

- Data points with a period of less than 60 seconds are available for 3 hours.<br/>
  These are high-resolution custom metrics.
- Data points with a period of 60 seconds (1 minute) are available for 15 days.
- Data points with a period of 300 seconds (5 minutes) are available for 63 days.
- Data points with a period of 3600 seconds (1 hour) are available for 455 days (15 months).

Data points are aggregated together for long-term storage after the initial period.<br/>
E.g., data using a period of 1 minute remains available for 15 days with 1-minute resolution, then it is aggregated and
made available with a resolution of 5 minutes; after 63 days, it is further aggregated and made available with a
resolution of 1 hour for 15 months.

<details>
  <summary>CLI commands</summary>

```sh
# List available metrics
aws cloudwatch list-metrics --namespace 'AWS/EC2'
aws cloudwatch list-metrics --namespace 'AWS/EC2' --metric-name 'CPUUtilization'
aws cloudwatch list-metrics --namespace 'AWS/EC2' --dimensions 'Name=InstanceId,Value=i-01234567890abcdef' --query 'Metrics[].MetricName'

# Show alarms information
aws cloudwatch describe-alarms-for-metric --metric-name 'CPUUtilization' --namespace 'AWS/EC2' --dimensions 'Name=InstanceId,Value=i-01234567890abcdef'
```

</details>

## Queries of interest

| What                                 | Section     | Tab             | How to visualize                                      |
| ------------------------------------ | ----------- | --------------- | ----------------------------------------------------- |
| [Top 10 log groups by written bytes] | All Metrics | Graphed metrics | Add Query > Logs > Top 10 log groups by written bytes |

<details style="padding-left: 1em;">
  <summary>Get a dashboard of how much data a <b>small</b> set of log groups ingested in the last 30 days</summary>

> This graph works only with the _Absolute_ time period option.<br/>
> Should you choose _Relative_, the graph returns incorrect data.

1. [CloudWatch console] > _All metrics_ (navigation pane on the left).
1. Choose _Logs_, _Log group metrics_.
1. Select the individual `IncomingBytes` metrics of each log group of interest.
1. Choose the _Graphed metrics_ tab.
1. For each metric:
   - Change `Statistic` to `Sum`.
   - Change `Period` to `30 Days`.
1. Choose the _Graph options_ tab.
1. Choose the _Number_ option group.
1. At the top right of the graph, choose _Custom_ as the time range.
1. Choose _Absolute_.
1. Select the last 30 days as start and end date.

</details>

<details style="padding-left: 1em;">
  <summary>Get a dashboard of how much data <b>all</b> log groups ingested in the last 30 days</summary>

> This graph works only with the _Absolute_ time period option.<br/>
> Should you choose _Relative_, the graph returns incorrect data.

1. [CloudWatch console] > _All metrics_ (navigation pane on the left).
1. Choose the _Graphed metrics_ tab.
1. From the _Add math_ dropdown list, choose _Start with an empty expression_.
1. Paste this as math expression:

   ```plaintext
   SORT(REMOVE_EMPTY(SEARCH('{AWS/Logs,LogGroupName} MetricName="IncomingBytes"', 'Sum', 2592000)),SUM, DESC)
   ```

1. At the top right of the graph, choose _Custom_ as the time range.
1. Choose _Absolute_.
1. Select the last 30 days as start and end date.

</details>

## Stream logs

Refer [Real-time processing of log data with subscriptions].<br/>
Also refer [Streaming CloudWatch Logs data to Amazon OpenSearch Service] to stream to AWS-managed Opensearch domains.

Logs in CloudWatch Log Groups can be streamed [Kinesis], [Firehose] or [Lambda] by leveraging Logs subscriptions.

## Cost-saving measures

- Configure an _appropriate_ log retention period for any log groups.<br/>
  Log groups containing development logs should not usually need more than 1w worth.
- When in doubt, still configure a default, long log retention period for all log groups (10y?).

## Further readings

- [Website]

### Sources

- [Documentation]
- [What is Amazon CloudWatch?]
- [What is AWS CloudWatch? Guide for beginners]
- [Real-time processing of log data with subscriptions]
- [Streaming CloudWatch Logs data to Amazon OpenSearch Service]
- [Which log group is causing a sudden increase in my CloudWatch Logs bill?]
- [Metrics concepts]

<!--
  Reference
  ═╬═Time══
  -->

<!-- In-article sections -->
[stream logs]: #stream-logs

<!-- Knowledge base -->
<!-- Files -->
<!-- Upstream -->
[cloudwatch console]: https://console.aws.amazon.com/cloudwatch/home
[documentation]: https://console.aws.amazon.com/cloudwatch/
[firehose]: https://docs.aws.amazon.com/firehose/latest/dev/what-is-this-service.html
[kinesis]: https://docs.aws.amazon.com/kinesis/
[lambda]: https://docs.aws.amazon.com/lambda/
[Metrics concepts]: https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/cloudwatch_concepts.html
[real-time processing of log data with subscriptions]: https://docs.aws.amazon.com/cloudwatch/latest/logs/Subscriptions.html
[services that publish cloudwatch metrics]: https://docs.aws.amazon.com/cloudwatch/latest/monitoring/aws-services-cloudwatch-metrics.html
[streaming cloudwatch logs data to amazon opensearch service]: https://docs.aws.amazon.com/cloudwatch/latest/logs/CWL_OpenSearch_Stream.html
[top 10 log groups by written bytes]: https://console.aws.amazon.com/cloudwatch/home#metricsV2?graph=~(view~'timeSeries~stacked~false~metrics~(~(~(expression~'SELECT*20SUM*28IncomingBytes*29*0aFROM*20SCHEMA*28*22AWS*2fLogs*22*2c*20LogGroupName*29*20*0aGROUP*20BY*20LogGroupName*0aORDER*20BY*20SUM*28*29*20DESC*0aLIMIT*2010~label~'!*7bLABEL*7d*20*5bsum*3a*20!*7bSUM*7d*5d~id~'q1)))~region~'eu-west-1~title~'Top*2010*20log*20groups*20by*20written*20bytes~yAxis~(left~(label~'Bytes~showUnits~false))~stat~'Average~period~300)
[website]: https://aws.amazon.com/cloudwatch/
[what is amazon cloudwatch?]: https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/WhatIsCloudWatch.html
[which log group is causing a sudden increase in my cloudwatch logs bill?]: https://repost.aws/knowledge-center/cloudwatch-logs-bill-increase

<!-- Others -->
[what is aws cloudwatch? guide for beginners]: https://www.educative.io/blog/aws-cloudwatch
