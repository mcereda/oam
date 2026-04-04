---
name: aws-action
description: >-
  Take actions on AWS resources using the AWS API. Use when the user asks to manage, modify, inspect, or operate on AWS
  infrastructure such as EC2 instances, S3 buckets, Lambda functions, RDS databases, IAM roles, and other AWS services.
argument-hint: [action description]
disable-model-invocation: true
---

# AWS Action Skill

You are performing an AWS infrastructure action requested by the user.

**Request:** $ARGUMENTS

## Safety Rules

1. **Always confirm destructive actions** before executing.<br/>
   Examples include terminate, delete, remove, revoke, detach, deregister, etc.
1. **Never modify any resource** without explicit user approval of the exact changes.
1. **The default region is `eu-west-1`**, unless the user specifies otherwise.
1. **Always show a dry-run or preview** of what will change when possible.<br/>
   E.g., using `--dry-run` for EC2.

## Workflow

### Step 1: Understand the request

Parse the user's request and identify:

- Which AWS services are involved.
- What operation is needed
  Examples include _describe_/_get_/_read_, _create_, _update_/_change_/_modify_, _delete_.
- What resource identifiers are provided, or if they need to be looked up.

### Step 2: Discover (if needed)

If the user hasn't provided specific resource IDs, use `mcp__aws-api__call_aws` to list or describe resources
first.<br/>

Examples:

- `aws ec2 describe-instances --filters Name=tag:Name,Values=<name>`
- `aws s3 ls`
- `aws lambda list-functions`

If you are unsure about the exact CLI command, use `mcp__aws-api__suggest_aws_commands` with a clear natural-language
description of what you need.

### Step 3: Plan the action

Present the user with:

- The **exact** AWS CLI commands you intend to run.
- What the expected outcome is.
- Any risks or side effects.

**Wait for user confirmation** before proceeding with any mutating operation.

### Step 4: Execute

Use `mcp__aws-api__call_aws` to run the **approved** commands.

### Step 5: Verify

After execution, run a follow-up _describe_/_get_ command to confirm the action succeeded.<br/>
Report the result clearly.

## Common Patterns

### Inspect resources

```sh
aws <service> describe-<resource> --<resource>-id <id>
```

### Tag resources

```sh
aws <service> create-tags --resources <id> --tags Key=<key>,Value=<value>
```

### Stop/Start EC2 instances

```sh
aws ec2 stop-instances --instance-ids <id>
aws ec2 start-instances --instance-ids <id>
```

### Scale ECS services

```sh
aws ecs update-service --cluster <cluster> --service <service> --desired-count <n>
```

## Error Handling

**Never** retry destructive commands automatically on failure.

If a command fails:

1. Read the error message carefully.<br/>
   Common issues include missing permissions, wrong region, resource not found, or invalid parameters.
1. Suggest fixes, or ask the user for clarification.
