# Identity and Access Management

| Entity | Description                                                                                                                     | Notes                                                  |
| ------ | ------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------ |
| User   | Represents a human or a workload.<br/>Defined by its name and credentials.                                                      | No permissions by default, need to be assigned to it   |
| Role   | Defines a set of permissions for making requests to AWS services.<br/>Defines what actions can be performed on which resources. | Can be assumed by AWS services, applications and users |

To be able to assume roles:

- Users, roles or services **must** have the permissions to assume the role they want to assume.
- The role's trust relationship **should** allow the users, roles or services to assume it.

From [Using service-linked roles]:

> A _service role_ is an IAM role that a service assumes to perform actions on your behalf.<br/>
> An IAM administrator can create, modify, and delete a service role from within IAM.
>
> A _service-linked role_ is a type of service role that is linked to an AWS service.<br/>
> The service can assume the role to perform an action on your behalf.<br/>
> Service-linked roles appear in your AWS account and are owned by the service. An IAM administrator can view, but not
> edit the permissions for service-linked roles.

Check [aws.permissions.cloud] for a community-driven source of truth for AWS identity.

1. [IAM policies](#iam-policies)
1. [Assume Roles](#assume-roles)
   1. [Require MFA for assuming Roles](#require-mfa-for-assuming-roles)
1. [Further readings](#further-readings)
   1. [Sources](#sources)

## IAM policies

IAM does not expose policies' `Sid` element in the IAM API, so it can't be used to retrieve statements.

Examples:

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

## Assume Roles

Refer [Introduction to AWS IAM AssumeRole].

Users, Roles and Services can assume Roles as long as:

1. The User, Role or Service that is trying to assume the end Role has assigned policies that would allow them to.

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

1. The **end** Role's Trust Relationships allow the entity in the point above to assume it.

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

Allowed entities can assume Roles using the [STS AssumeRole API][assumerole api reference]:

```sh
aws sts assume-role --output 'yaml' \
  --role-arn "arn:aws:iam::012345678901:role/EksAdminRole" \
  --role-session-name "lookAt-halJordan-sheIsThe-EksAdminRole-now"
```

```yaml
AssumedRoleUser:
  Arn: arn:aws:sts::012345678901:assumed-role/EksAdminRole/AIDA0123456789ABCDEFG-as-EksAdminRole-stsSession
  AssumedRoleId: AROA2HKHF0123456789OA:AIDA0123456789ABCDEFG-as-EksAdminRole-stsSession
Credentials:
  AccessKeyId: ASIA2HKHF012345ABCDE
  Expiration: '2024-08-06T10:29:15+00:00'
  SecretAccessKey: C2SGbkwmfHWzf44DX6IQQirg5XCGwpLX0Ai++Qkq
  SessionToken: IQoJb3jPZ2luX2VjEAIaCWV1LXdlc3QtMSJHMEUCIQCGEihh9rBi1cL8ebhQVdcKl8Svzm5VCIC/ebCdxpORiA…
```

### Require MFA for assuming Roles

Refer [Using AWS CLI Securely with IAM Roles and MFA].

Add the `"Bool": {"aws:MultiFactorAuthPresent": true}` condition to the Role's trust relationships:

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

When requiring MFA with AssumeRole, identities need to pass values for the SerialNumber and TokenCode parameters.<br/>
SerialNumbers identify the users' hardware or virtual MFA devices, TokenCodes are the time-based one-time password
(TOTP) value that devices produce.

For CLI access, the user will need to add the `mfa_serial` setting to their profile:

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

## Further readings

- [Amazon Web Services]
- [aws.permissions.cloud]
- [Using service-linked roles]

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

<!--
  References
  -->

<!-- In-article sections -->
<!-- Knowledge base -->
[amazon web services]: README.md

<!-- Files -->
<!-- Upstream -->
[assumerole api reference]: https://docs.aws.amazon.com/STS/latest/APIReference/API_AssumeRole.html
[creating a role to delegate permissions to an iam user]: https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_create_for-user.html
[how can i monitor the account activity of specific iam users, roles, and aws access keys?]: https://repost.aws/knowledge-center/view-iam-history
[how to use the passrole permission with iam roles]: https://aws.amazon.com/blogs/security/how-to-use-the-passrole-permission-with-iam-roles/
[iam json policy elements: principal]: https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_policies_elements_principal.html
[iam json policy elements: sid]: https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_policies_elements_sid.html
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
[introduction to aws iam assumerole]: https://aws.plainenglish.io/introduction-to-aws-iam-assumerole-fbef3ce8e90b
[you might be clueless as to why aws assume role isn't working, despite being correctly set up]: https://medium.com/@kamal.maiti/you-might-be-clueless-as-to-why-aws-assume-role-isnt-working-despite-being-correctly-set-up-1b3138519c07
[using aws cli securely with iam roles and mfa]: https://dev.to/albac/using-aws-cli-securely-with-iam-roles-and-mfa-56c3
