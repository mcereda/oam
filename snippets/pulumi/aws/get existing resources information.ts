import * as aws from "@pulumi/aws";
import * as pulumi from "@pulumi/pulumi";

const ec2Ami_amazonLinux2023_arm64_available_latest_output: pulumi.Output<aws.ec2.GetAmiResult> = aws.ec2.getAmiOutput({
    owners: [ "amazon", ],
    nameRegex: "^al2023-ami-2023.*",
    filters: [
        {
            name: "architecture",
            values: [ "arm64" ],
        },
        {
            name: "state",
            values: [ "available" ],
        },
    ],
    mostRecent: true,
});
const ec2KeyPair_output: pulumi.Output<aws.ec2.GetKeyPairResult> = aws.ec2.getKeyPairOutput({ keyName: "john-ec2KeyPair" });
const ec2Subnet: pulumi.Output<aws.ec2.GetSubnetResult> = aws.ec2.getSubnetOutput({
    filters: [{
        name: "tag:Name",
        values: [ "Private Subnet in AZ C" ],
    }],
});
pulumi.all([
    ec2Ami_amazonLinux2023_arm64_available_latest_output,
    ec2KeyPair_output,
    ec2Subnet,
]).apply( ([ ami, keyPair, subnet ]) => console.log(`${ami.arn}, ${keyPair.arn}, ${subnet.arn}`) );


const s3bucket_output = aws.s3.getBucketOutput({ bucket: "some-bucket" });
s3bucket_output.arn.apply(
    (bucketArn: aws.ARN) => new aws.iam.Role(
        "bucket",
        {
            name: "BucketInstanceRole",
            assumeRolePolicy: JSON.stringify({
                Version: "2012-10-17",
                Statement: [{
                    Effect: "Allow",
                    Principal: { Service: "ec2.amazonaws.com" },
                    Action: "sts:AssumeRole",
                }],
            }),
            inlinePolicies: [{
                name: "AllowManagingOwnBucket",
                policy: JSON.stringify({
                    Version: "2012-10-17",
                    Statement: [{
                        Effect: "Allow",
                        Action: "s3:*",
                        Resource: [
                            `${bucketArn}`,
                            `${bucketArn}/*`,
                        ],
                    }],
                }),
            }],
        },
    ),
);
