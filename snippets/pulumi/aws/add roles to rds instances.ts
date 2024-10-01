import * as aws from "@pulumi/aws";
import * as postgresql from "@pulumi/postgresql";
import * as pulumi from "@pulumi/pulumi";

const config = new pulumi.Config();
const rdsInstance_output = aws.rds.getInstanceOutput({dbInstanceIdentifier: "pikachu-zambia-staging"});

const rdsInstance_postgresqlProvider = new postgresql.Provider(
    "rdsInstance", {
        host: rdsInstance_output.address,
        port: rdsInstance_output.port,
        databaseUsername: rdsInstance_output.masterUsername,
        database: rdsInstance_output.dbName,
        password: config.requireSecret("rdsInstance_masterPassword"),
    },
);

const engineering_postgresqlRole = new postgresql.Role(
    "engineering",
    {
        name: "engineering",
        inherit: true,  // required as it will be used by human users
    },
    { provider: rdsInstance_postgresqlProvider },
);
