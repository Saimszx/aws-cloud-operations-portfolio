# CloudWatch Logs Insights Query Library

## Purpose

These queries turn raw nginx and cloud-init logs into repeatable operational
evidence. Select the named log group, choose a narrow time range, and then run the
matching query in CloudWatch Logs Insights.

Narrow time ranges reduce query cost and make incident timelines easier to read.

## Recent HTTP Requests

Log group: `/portfolio/cloudops/lab/nginx-access`

```text
fields @timestamp, @message, @logStream
| sort @timestamp desc
| limit 50
```

Use this query after opening the public URL. It proves that nginx received the
request and identifies the instance log stream that handled it.

## HTTP Status-Code Distribution

Log group: `/portfolio/cloudops/lab/nginx-access`

```text
parse @message /"(?<method>\S+) (?<path>\S+) \S+" (?<status>\d{3}) (?<bytes>\d+)/
| stats count(*) as requestCount by status
| sort requestCount desc
```

Use this query when the site appears unhealthy. A rise in `4xx` values suggests a
client or path problem; `5xx` values suggest a server-side failure.

## Most Requested Paths

Log group: `/portfolio/cloudops/lab/nginx-access`

```text
parse @message /"(?<method>\S+) (?<path>\S+) \S+" (?<status>\d{3}) (?<bytes>\d+)/
| stats count(*) as requestCount by method, path
| sort requestCount desc
| limit 20
```

Use this query to understand traffic shape and to confirm which endpoint was
tested during the incident.

## Recent nginx Errors

Log group: `/portfolio/cloudops/lab/nginx-error`

```text
fields @timestamp, @message, @logStream
| sort @timestamp desc
| limit 50
```

Use this query when nginx is not responding or returns a server error. An empty
result is still useful evidence when metrics indicate that the problem is CPU
pressure rather than an application failure.

## Boot and Agent Failures

Log group: `/portfolio/cloudops/lab/cloud-init`

```text
fields @timestamp, @message
| filter @message like /(?i)(error|failed|exception)/
| sort @timestamp desc
| limit 100
```

Use this query when the instance does not appear in Systems Manager, the memory
metric is missing, or log streams are absent. It searches first-boot output for
package, service, and agent configuration failures.

## Boot Timeline

Log group: `/portfolio/cloudops/lab/cloud-init`

```text
fields @timestamp, @message
| sort @timestamp asc
| limit 200
```

Use this query to reconstruct the order of first-boot events. It is especially
useful when comparing the launch time, agent startup, and first successful web
request.
