# AWS Secrets Manager

AWS' native secrets management service.

1. [TL;DR](#tldr)
1. [Further readings](#further-readings)
   1. [Sources](#sources)

## TL;DR

Provides integration with the AWS ecosystem and has automatic rotation capabilities specifically designed for AWS
services.

Offers precise access control to each secret via fine-grained IAM permissions with resource-based policies.<br/>
Supports VPC endpoints to enables private network access without the need for Internet routing. Optimal for air-gapped
or highly secure environments.<br/>
Critical secrets can be replicated cross-region.

Costs $0.40 per secret per month, plus $0.05 per 10,000 API calls.<br/>
Secrets that are marked for deletion are not paid for.

Secrets Manager uses keys from [KMS] to encrypt the secrets it manages.<br/>
On first use, Secrets Manager creates the AWS-managed key `aws/secretsmanager` to encrypt the secrets given to it. There
is **no** cost for using this key.<br/>
When _automatic_ rotation is turned on for a secret, Secrets Manager uses a Lambda function to rotate it. The use of the
Lambda function is charged at the current Lambda rate.
The rotation function is **not** called for secrets using _managed_ rotation.

Logs of the API calls that Secrets Manager sends out are sent to CloudTrail, if it is enabled. Costs for CloudTrail are
**in addition** to the ones incurred by using Secrets Manager.

```sh
aws secretsmanager create-secret --name 'TestSecretFromFile' --secret-string 'file://gcp_credentials.json'
aws secretsmanager create-secret \
  --name 'MyTestSecret' --description 'A test secret created with the CLI.' \
  --secret-string '{"user":"diego","password":"EXAMPLE-PASSWORD"}' \
  --tags '[{"Key": "FirstTag", "Value": "FirstValue"}, {"Key": "SecondTag", "Value": "SecondValue"}]'
```

Secrets can be any text or binary up to 65536 bytes (64KB).<br/>
Should one want to automatically rotate them, they must contain the specific JSON fields that the rotation function
expects. Refer the [JSON structure of AWS Secrets Manager secrets].

Secret have versions that hold copies of their encrypted value.<br/>
When changing the secret value, or when the secret is rotated, Secrets Manager creates a new version and serves that by
default. The old version is kept (up to a point), but not accessed unless specifically requested.

One can access a secret across multiple Regions by replicating it.<br/>
When replicating a secret, Secrets Manager creates a copy of the original (A.K.A. _primary_) secret. That copy is known
as a _replica_ secret.<br/>
The replica secret remains linked to the primary secret, and is updated when a new version of the primary is created.

Secrets Manager uses [IAM] to allow only authorized users to access or modify a secret.<br/>
Permissions for them can be set in IAM Policies that are _identity-based_ (the usual ones, granted to IAM Identities),
or _resource-based_ (secret-specific).

_Managed_ secrets are created and managed by the AWS service that created them.<br/>
The managing service might also restrict users from updating secrets, or deleting them without a recovery period.<br/>
Managed secrets use a naming convention that includes the ID of the service managing them.

## Further readings

- [Secrets management]
- [KMS]
- [IAM]

### Sources

- [Authentication and access control for AWS Secrets Manager]

<!--
  Reference
  ═╬═Time══
  -->

<!-- In-article sections -->
<!-- Knowledge base -->
[IAM]: iam.md
[KMS]: iam.md
[Secrets management]: ../../secrets%20management.md

<!-- Upstream -->
[Authentication and access control for AWS Secrets Manager]: https://docs.aws.amazon.com/secretsmanager/latest/userguide/auth-and-access.html

<!-- Others -->
[JSON structure of AWS Secrets Manager secrets]: https://docs.aws.amazon.com/secretsmanager/latest/userguide/reference_secret_json_structure.html
