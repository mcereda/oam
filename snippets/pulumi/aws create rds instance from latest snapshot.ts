/**
 * Source: https://www.pulumi.com/registry/packages/aws/api-docs/rds/getsnapshot/
 **/

import * as aws from "@pulumi/aws";

const prod = new aws.rds.Instance("prod", {
    allocatedStorage: 10,
    engine: "mysql",
    engineVersion: "5.6.17",
    instanceClass: aws.rds.InstanceType.T2_Micro,
    dbName: "mydb",
    username: "foo",
    password: "bar",
    dbSubnetGroupName: "my_database_subnet_group",
    parameterGroupName: "default.mysql5.6",
});
const latestProdSnapshot = aws.rds.getSnapshotOutput({
    dbInstanceIdentifier: prod.identifier,
    mostRecent: true,
});
// Use the latest production snapshot to create a dev instance.
const dev = new aws.rds.Instance("dev", {
    instanceClass: aws.rds.InstanceType.T2_Micro,
    dbName: "mydbdev",
    snapshotIdentifier: latestProdSnapshot.apply(latestProdSnapshot => latestProdSnapshot.id),
});
