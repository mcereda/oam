/**
 * https://repost.aws/knowledge-center/rds-mysql-export-snapshot
 */

import * as aws from "@pulumi/aws";
new aws.iam.Role(
    "rdsS3Exporter",
    {
        name: "rdsS3Exporter",
        assumeRolePolicy: JSON.stringify({
            Version: "2012-10-17",
            Statement: [{
                Effect: "Allow",
                Action: "sts:AssumeRole",
                Principal: {
                    Service: "export.rds.amazonaws.com",
                },
            }],
        }),
        inlinePolicies: [{
            name: "AllowExportingDataToS3",
            policy: JSON.stringify({
                Version: "2012-10-17",
                Statement: [
                    {
                        Effect: "Allow",
                        Action: [
                            "s3:ListBucket",
                            "s3:GetBucketLocation",
                        ],
                        Resource: "arn:aws:s3:::backups",
                    },
                    {
                        Effect: "Allow",
                        Action: [
                            "s3:PutObject*",
                            "s3:GetObject*",
                            "s3:DeleteObject*",
                        ],
                        Resource: "arn:aws:s3:::backups/rds_exports/*",
                    },
                ],
            }),
        }],
    },
    { protect: true },
);
