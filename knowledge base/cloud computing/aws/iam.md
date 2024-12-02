# Identity and Access Management

Controls who is authenticated (signed in) and authorized (has permissions) to use resources.

Authentication is provided by matching the sign-in credentials to a _principal_ trusted by the AWS account.<br/>
Principals are IAM users, federated users, IAM roles, and applications.

Authorization is provided by sending requests to grant the principal access to _resources_.<br/>
Such access is given in response to the authorization request **only** if _policies_ exist that grant the principal
permission to the _actions_ **and** the _resources_ defined in the request.

<details/>
  <summary>Example</summary>

When first signing in to the console, one lands on the console's homepage. At this point, one isn't accessing any
specific service.

When selecting a service, a request for authorization is sent to that service. It checks if one's principal is on the
list of authorized users, what policies are being enforced to control the level of access granted, and any other
policy that might be in effect.

The service returns all the requested data for which the principal passes the checks, and errors for the rest.

</details>

Authorization requests can be made by principals within the same AWS account, or from other AWS accounts trusted by the
first.

Once authorized, the principal can take action or perform operations on resources in the AWS account.

| Principal | Description                                                                                                                     | Notes                                               |
| --------- | ------------------------------------------------------------------------------------------------------------------------------- | --------------------------------------------------- |
| User      | Represents a human or a workload.<br/>Defined by its name and credentials.                                                      | No permissions by default                           |
| Role      | Defines a set of permissions for making requests to AWS services.<br/>Defines what actions can be performed on which resources. | Can be assumed by AWS services and other principals |

Principals and AWS Services can assume Roles.<br/>
Trust is needed both ways, meaning Roles can be assumed if and only if **both**:

- The Principal or Service assum**ing** the Role is granted the `sts:AssumeRole` permissions to that Role.
- The assum**ed** Role's trust relationship does allow the Principal or Service to assume it.

_Service Roles_ are different from _Service-linked Roles_.<br/>
From [Using service-linked roles]:

> A _service role_ is an IAM role that a service assumes to perform actions on your behalf.<br/>
> An IAM administrator can create, modify, and delete a service role from within IAM.
>
> A _service-linked role_ is a type of service role that is linked to an AWS service.<br/>
> The service can assume the role to perform an action on your behalf.<br/>
> Service-linked roles appear in your AWS account and are owned by the service. An IAM administrator can view, but not
> edit the permissions for service-linked roles.

Refer [aws.permissions.cloud] for a community-driven source of truth for AWS IAM.

1. [Users](#users)
1. [Groups](#groups)
1. [Policies](#policies)
   1. [Trust Policies](#trust-policies)
   1. [Trust Relationships](#trust-relationships)
1. [Roles](#roles)
   1. [Assume Roles](#assume-roles)
      1. [Require MFA for assuming Roles](#require-mfa-for-assuming-roles)
1. [Further readings](#further-readings)
   1. [Sources](#sources)

## Users

Refer [IAM users].

Represent a human user or workload needing to interact with AWS resources.<br/>
Consist of a name and credentials.<br/>
Applications using their credentials to make requests are typically referred to as _service accounts_.

IAM Users with administrator permissions are **not** the same thing as the AWS account's root user.

IAM identifies IAM Users via:

- A friendly name that IAM will use to display Users in the AWS Management Console.
- A unique identifier returned only when using the API, and **not** visible in the console.
- An ARN usable to uniquely identify a IAM User across all of AWS.

Users can access AWS in different ways depending on their credentials:

- Console password: nothing more than passwords used to sign in to interactive sessions.<br/>
  Disabling a password (_console access_) for a User prevents them from signing in to the Console using their sign-in
  credentials, but it does not change their permissions nor prevent them from accessing the Console using assumed roles.
- Access keys: allow programmatic requests to AWS' APIs.
- SSH keys: SSH public keys in the OpenSSH format used to authenticate with CodeCommit.
- Server certificates: SSL/TLS certificates usable to authenticate with some services.

When using the Management Console to create IAM Users, one must include a console password or an access key.<br/>
By default, brand new IAM Users created using the APIs have no credentials of any kind.

By default, Users have no permissions and can do nothing.

Users can be assigned _permissions boundaries_.<br/>
Those allow the use of managed policies to limit the maximum permissions that an identity-based policy can grant to an
IAM User or Role.

Each IAM User is associated with one and only one AWS account.<br/>
Any activity performed by IAM Users in one's account is billed to the account.

The number and size of IAM resources in an AWS account are limited.<br/>
Refer [IAM and AWS STS quotas].

## Groups

Refer [IAM user groups].

Collections of IAM users.<br/>
They allow to specify permissions for multiple users.

Groups can be assigned Policies. Any User in a Group inherits the Group's permissions.

Groups **cannot** be used as Principals in a Policy.<br/>
Groups relate to permissions, not authentication, and Principals are authenticated IAM entities.

One Group can contain many Users, and one User can belong to multiple Groups.

Groups can contain only Users, not Roles nor other Groups.

There is no default Group that automatically includes all users in the AWS account.

The number and size of IAM resources in an AWS account are limited.<br/>
Refer [IAM and AWS STS quotas].

## Policies

Refer [Policies](https://blog.awsfundamentals.com/aws-iam-roles-terms-concepts-and-examples#heading-policies).

Define which _actions_ are available for _principals_ on which _resources_ under which _conditions_.<br/>
Their _effect_ can be to `allow` or `deny` such actions. A `deny` statement **always overwrites** `allow` statements.

> Watch out for explicit `Deny` statements, as they could prevent users from do seemingly completely unrelated things -
> like accessing a Pulumi state file in a S3 bucket when an explicit `Deny` statement blocks IAM users from listing IAM
> Groups when they are not logged in with MFA.

Mostly stored as structured JSON documents.<br/>
Each Policy comes with one or several _statements_. Each statement defines an effect.

IAM does not expose Policies' `Sid` element in the IAM API, so it can't be used to retrieve statements.

Policy examples:

<details>
  <summary>Give a user temporary RO access to a bucket</summary>

1. Create the policy:

   ```json
   {
     "Version": "2012-10-17",
     "Statement": [{
       "Sid": "AllowAttachedPrincipalsTemporaryROAccessToBucket",
       "Effect": "Allow",
       "Action": [
         "s3:GetObject",
         "s3:GetObjectAttributes",
         "s3:ListBucket",
         "s3:ListBucketVersions"
       ],
       "Resource": [
         "arn:aws:s3:::my-bucket",
         "arn:aws:s3:::my-bucket/*"
       ],
       "Condition": {
         "DateLessThan": {
           "aws:CurrentTime": "2024-03-01T00:00:00Z"
         }
       }
     }]
   }
   ```

   ```sh
   $ aws iam create-policy --output 'yaml' \
     --policy-name 'temp-ro-access-my-bucket' --policy-document 'file://policy.json'
   - Policy:
       Arn: arn:aws:iam::012345678901:policy/temp-ro-access-my-bucket
       AttachmentCount: 0
       CreateDate: '2024-02-25T09:34:12+00:00'
       DefaultVersionId: v1
       IsAttachable: true
       Path: /
       PermissionsBoundaryUsageCount: 0
       PolicyId: ANPA2HKHE74L11PTJGB3V
       PolicyName: temp-ro-access-my-bucket
       UpdateDate: '2024-02-25T09:34:12+00:00'
   ```

1. Attach the newly created policy to the user:

   ```sh
   aws iam attach-user-policy \
     --user-name 'my-user' --policy-arn 'arn:aws:iam::012345678901:policy/temp-ro-access-my-bucket'
   ```

</details>

### Trust Policies

Specific type of resource-based policy for IAM roles.<br/>
Used to allow Principals ans AWS Services to assume Roles.

### Trust Relationships

[Trust Policies] used by AWS services to assume Roles in one's account to be able to manage resources on behalf of
Users.

## Roles

Refer [IAM roles].

IAM identities that have specific permissions but **cannot** have standard long-term credentials such as passwords or
access keys associated with it.<br/>
Roles are meant to be used to delegate access to AWS Services or other Principals that cannot normally act on those
resources.

Principals and AWS Services can _assume_ Roles to gain such delegated permissions.<br/>
Trust is needed **both** ways, meaning Roles can be assumed if and only if **both**:

- The Principal or Service assum**ing** the Role is granted the `sts:AssumeRole` permissions to that Role.
- The assum**ed** Role's trust relationship does allow the Principal or Service to assume it.

Roles are assumed in _sessions_.<br/>
When assuming Roles, they provide the assuming identity with **temporary** security credentials that are only valid for
that session.

### Assume Roles

Refer [Introduction to AWS IAM AssumeRole].

Principals and AWS Services can assume Roles as long as:

1. The Principal or Service **trying to assume** the end Role has assigned Policies that would allow it to.

   <details style="margin-top: -1em; padding-bottom: 1em;">

   ```json
   {
       "Version": "2012-10-17",
       "Statement": [
           {
               "Sid": "AllowMeToAssumeThoseRoles",
               "Effect": "Allow",
               "Action": "sts:AssumeRole",
               "Resource": [
                   "arn:aws:iam::012345678901:role/EksAdminRole",
                   "arn:aws:iam::987654321098:role/EcsAuditorRole"
               ]
           }
       ]
   }
   ```

   </details>

1. The **assumed** Role's Trust Relationships allows the Principal in the point above to assume it.

   <details style="margin-top: -1em; padding-bottom: 1em;">

   ```json
   {
       "Version": "2012-10-17",
       "Statement": [
           …,
           {
               "Effect": "Allow",
               "Principal": {
                   "AWS": [
                     "arn:aws:iam::012345678901:user/halJordan",
                     "arn:aws:sts::987654321098:role/OtherRole"
                     "arn:aws:sts::987654321098:assumed-role/EcsAuditorRole/specific-session-name"
                   ]
               },
               "Action": "sts:AssumeRole"
           }
       ]
   }
   ```

   </details>

Allowed entities can assume Roles using the [STS AssumeRole API][assumerole api reference].

<details style="margin-top: -1em; padding-bottom: 1em;">

```sh
$ aws sts assume-role --role-arn "arn:aws:iam::012345678901:role/EksAdminRole" \
  --role-session-name "lookAt-halJordan-heIsThe-EksAdminRole-now" --duration-seconds '900' --output 'yaml'

AssumedRoleUser:
  Arn: arn:aws:sts::012345678901:assumed-role/EksAdminRole/lookAt-halJordan-heIsThe-EksAdminRole-now
  AssumedRoleId: AROA2HKHF0123456789OA:lookAt-halJordan-heIsThe-EksAdminRole-now
Credentials:
  AccessKeyId: ASIA2HKHF012345ABCDE
  Expiration: '2024-08-06T10:29:15+00:00'
  SecretAccessKey: C2SGbkwmfHWzf44DX6IQQirg5XCGwpLX0Ai++Qkq
  SessionToken: IQoJb3jPZ2luX2VjEAIaCWV1LXdlc3QtMSJHMEUCIQCGEihh9rBi1cL8ebhQVdcKl8Svzm5VCIC/ebCdxpORiA…4A==
```

</details>

One _can_ assume Roles in a chain fashion, assuming one Role to then assume another Role.

> Role chaining limits one's CLI or API role session duration to a maximum of **1 hour** at the time of writing.<br/>
> This duration **cannot** be increased. Refer [Can I increase the duration of the IAM role chaining session?].

#### Require MFA for assuming Roles

Refer [Using AWS CLI Securely with IAM Roles and MFA].

Add the `"Bool": {"aws:MultiFactorAuthPresent": true}` condition to the Role's Trust Relationships.

<details style="margin-top: -1em; padding-bottom: 1em;">

```json
{
    "Version": "2012-10-17",
    "Statement": [{
        "Effect": "Allow",
        "Principal": {
            "AWS": "arn:aws:iam::012345678901:user/halJordan"
        },
        "Action": "sts:AssumeRole",
        "Condition": {
            "Bool": {
                "aws:MultiFactorAuthPresent": true
            }
        }
    }]
}
```

</details>

When requiring MFA with AssumeRole, identities need to pass values for the SerialNumber and TokenCode parameters.<br/>
SerialNumbers identify the users' hardware or virtual MFA devices, TokenCodes are the time-based one-time password
(TOTP) value that devices produce.

For CLI access, the user will need to add the `mfa_serial` setting to their profile.

<details style="margin-top: -1em; padding-bottom: 1em;">

```ini
[default]
…

[role-with-mfa]
source_profile = default
role_arn = arn:aws:iam::012345678901:role/EksAdminRole
mfa_serial = arn:aws:iam::012345678901:mfa/gopass
```

```sh
$ AWS_PROFILE='role-with-mfa' aws sts get-caller-identity --output 'yaml'
Enter MFA code for arn:aws:iam::012345678901:mfa/gopass:
Account: '012345678901'
Arn: arn:aws:sts::012345678901:assumed-role/EksAdminRole/botocore-session-1234567890
UserId: AROA2HKHF74L72AABBCCDD:botocore-session-1234567890
```

</details>

## Further readings

- [Amazon Web Services]
- [aws.permissions.cloud]
- [Using service-linked roles]
- [IAM and AWS STS quotas]

### Sources

- [Introduction to AWS IAM AssumeRole]
- [IAM JSON policy elements: Principal]
- [IAM JSON policy elements: Sid]
- [Using IAM policy conditions for fine-grained access control to manage resource record sets]
- [Not authorized to perform: sts:AssumeRole]
- [Troubleshooting IAM roles]
- [How can I monitor the account activity of specific IAM users, roles, and AWS access keys?]
- [Using IAM roles]
- [AssumeRole api reference]
- [You might be clueless as to why AWS assume role isn't working, despite being correctly set up]
- [Use an IAM role in the AWS CLI]
- [Creating a role to delegate permissions to an IAM user]
- [How to use the PassRole permission with IAM roles]
- [Avoid the 60 minutes timeout when using the AWS CLI with IAM roles]
- [AWS IAM Roles - Everything You Need to Know & Examples]
- [Using AWS CLI Securely with IAM Roles and MFA]
- [Can I increase the duration of the IAM role chaining session?]
- [IAM users]
- [IAM user groups]
- [IAM roles]
- [Get to Grips with AWS IAM Roles: Terms, Concepts, and Examples]
- [What is exactly "Assume" a role in AWS?]

<!--
  Reference
  ═╬═Time══
  -->

<!-- In-article sections -->
[trust policies]: #trust-policies

<!-- Knowledge base -->
[amazon web services]: README.md

<!-- Files -->
<!-- Upstream -->
[assumerole api reference]: https://docs.aws.amazon.com/STS/latest/APIReference/API_AssumeRole.html
[can i increase the duration of the iam role chaining session?]: https://repost.aws/knowledge-center/iam-role-chaining-limit
[creating a role to delegate permissions to an iam user]: https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_create_for-user.html
[how can i monitor the account activity of specific iam users, roles, and aws access keys?]: https://repost.aws/knowledge-center/view-iam-history
[how to use the passrole permission with iam roles]: https://aws.amazon.com/blogs/security/how-to-use-the-passrole-permission-with-iam-roles/
[iam and aws sts quotas]: https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_iam-quotas.html
[iam json policy elements: principal]: https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_policies_elements_principal.html
[iam json policy elements: sid]: https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_policies_elements_sid.html
[iam roles]: https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles.html
[iam user groups]: https://docs.aws.amazon.com/IAM/latest/UserGuide/id_groups.html
[iam users]: https://docs.aws.amazon.com/IAM/latest/UserGuide/id_users.html
[not authorized to perform: sts:assumerole]: https://repost.aws/questions/QUOY5XngCtRyOX4Desaygz8Q/not-authorized-to-perform-sts-assumerole
[troubleshooting iam roles]: https://docs.aws.amazon.com/IAM/latest/UserGuide/troubleshoot_roles.html
[use an iam role in the aws cli]: https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-role.html
[using iam policy conditions for fine-grained access control to manage resource record sets]: https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/specifying-rrset-conditions.html
[using iam roles]: https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_use.html
[using service-linked roles]: https://docs.aws.amazon.com/IAM/latest/UserGuide/using-service-linked-roles.html

<!-- Others -->
[avoid the 60 minutes timeout when using the aws cli with iam roles]: https://cloudonaut.io/avoid-the-60-minutes-timeout-when-using-the-aws-cli-with-iam-roles/
[aws iam roles - everything you need to know & examples]: https://spacelift.io/blog/aws-iam-roles
[aws.permissions.cloud]: https://aws.permissions.cloud/
[get to grips with aws iam roles: terms, concepts, and examples]: https://blog.awsfundamentals.com/aws-iam-roles-terms-concepts-and-examples
[introduction to aws iam assumerole]: https://aws.plainenglish.io/introduction-to-aws-iam-assumerole-fbef3ce8e90b
[using aws cli securely with iam roles and mfa]: https://dev.to/albac/using-aws-cli-securely-with-iam-roles-and-mfa-56c3
[you might be clueless as to why aws assume role isn't working, despite being correctly set up]: https://medium.com/@kamal.maiti/you-might-be-clueless-as-to-why-aws-assume-role-isnt-working-despite-being-correctly-set-up-1b3138519c07
[what is exactly "assume" a role in aws?]: https://stackoverflow.com/questions/50082732/what-is-exactly-assume-a-role-in-aws
