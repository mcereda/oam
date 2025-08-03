# AWS Key Management Service

AWS' native encryption keys management service.

1. [TL;DR](#tldr)
1. [Aliases](#aliases)
1. [Further readings](#further-readings)
   1. [Sources](#sources)

## TL;DR

Creates and controls encryption keys one can use to encrypt data.<br/>
Keys created with KMS are protected by FIPS 140-3 Security Level 3 validated HSMs.<br/>
They are created, managed, used, and deleted entirely **within** the managed service. They **never** leave KMS
unencrypted. To use or manage keys in KMS, one **must** interact with the service.

The service costs $0.03 to $12 per 10,000 API calls, depending on the action and type of key used.<br/>
Refer [Pricing].

Key policies are the **primary** way to control access to KMS keys.<br/>
Every KMS key must have **exactly one** key policy.<br/>
Statements in such policies determine **who** has permission to use KMS keys, and **how** they can use it. One _can_
configure **additional** [IAM] policies and grants for keys.<br/>
Key policies are Regional.

> [!important]
> IAM policies manage access to a KMS key **only** if the key policy **explicitly** allows it.<br/>
> Without permission from the key policy, IAM policies have no effect.<br/>
> The default key policy enables IAM policies.

**No** AWS principal, **including** the account root user and the key creator, has **any** permissions to a key until
a key policy, IAM policy, or grant **explicitly** allows, and never denies, access to it.

Keys created by customers are referred to as _customer managed keys_.<br/>
They are recommended when wanting **full control** over the lifecycle and usage of the keys.<br/>
Customer managed keys incur in both management and usage costs.

_AWS managed keys_ are keys that exists in an account, but can only be used in the context of an AWS service and only
in the same account. One **cannot** share resources encrypted under an AWS managed key with other accounts.<br/>
They do **not** allow managing anything about their lifecycle or permissions.<br/>
AWS managed keys do not have management costs, but incur in usage costs.<br/>
These keys use an alias in the form `aws/<service code>`, e.g. `aws/ebs`.

AWS managed keys are a legacy key type, and are no longer being created for new AWS services as of 2021. Instead,
services are now using _AWS owned keys_ to encrypt customer data by default.<br/>
AWS owned keys are stored in an AWS account managed by the related AWS service. Only the service's operators can manage
the keys' lifecycle and usage permissions.<br/>
By using AWS owned keys, AWS services can transparently encrypt data and allow for cross-account or cross-region sharing
of data.<br/>
Customers are **not** charged for the keys' existence **nor** their usage, but they cannot change their policies, audit
activities on these keys, nor delete them.

KMS can provide encryption keys for protecting data in other AWS services (e.g., [EBS], [RDS], [S3]).
AWS services that integrates with KMS only use _symmetric_ encryption keys to encrypt data.<br/>
These services do **not** support encryption with _asymmetric_ keys.

Asymmetric keys are related public key and private key pairs.<br/>
The **private** key is created in KMS and never leaves the service unencrypted. To use the private key, one **must**
interact with KMS.<br/>
One can use the **public** key by calling the AWS APIs, or download it and use it outside of KMS.

Use a **symmetric** encryption KMS key to encrypt the data one stores or manages in an AWS service.

## Aliases

Refer [Aliases in AWS KMS].

Each key is represented by its key ID, but can have one or more aliases associated.<br/>
Aliases allow using a human-friendly name to identify the key they are associated to in _some_ AWS operations.<br/>
They are **not** a property of a key, and actions on the alias do **not** affect the associated key. However, all
aliases associated with a key are deleted when that key is deleted.

> [!important]
> Specifying an alias as resource in an IAM policy will make the policy refer **to the alias**, not to the key it is
> associated with.

## Further readings

- [Secrets management]

### Sources

- [AWS Key Management Service]

<!--
  Reference
  ═╬═Time══
  -->

<!-- In-article sections -->
<!-- Knowledge base -->
[EBS]: ebs.md
[IAM]: iam.md
[RDS]: rds.md
[S3]: s3.md
[Secrets management]: ../../secrets%20management.md

<!-- Upstream -->
[AWS Key Management Service]: https://docs.aws.amazon.com/kms/latest/developerguide/overview.html
[Pricing]: https://aws.amazon.com/kms/pricing/
[Aliases in AWS KMS]: https://docs.aws.amazon.com/kms/latest/developerguide/kms-alias.html

<!-- Others -->
