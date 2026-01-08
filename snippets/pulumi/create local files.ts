/*
 * Refer <https://www.pulumi.com/registry/packages/local/api-docs/file/>.
 */

import * as local from "@pulumi/local";
import * as pulumi from "@pulumi/pulumi";

const localFile: local.File = new local.File(
    "someFile",
    {
        filename: "/path/to/file",
        content: "file contents",
    },
);

const redash_config: local.File = new local.File(
    "redashConfig",
    {
        filename: "redash.env",
        content: pulumi
            .all([
                redisCluster.primaryEndpointAddress,
                redisCluster.port,
                rdsDBInstance.address,
                rdsDBInstance.port,
                rdsDBInstance.dbName,
                rdsDBInstance.username,
                httpsListener_dnsRecord.fqdn,
            ])
            .apply(
                ([
                    redis_primaryEndpointAddress,
                    redis_port,
                    pg_host,
                    pg_port,
                    pg_dbname,
                    pg_username,
                    dnsEntry,
                ]) => [
                        `PYTHONUNBUFFERED=0`,
                        `REDASH_LOG_LEVEL=INFO`,
                        `REDASH_HOST=https://${dnsEntry}`,

                        `REDASH_COOKIE_SECRET=aa…00`,
                        `REDASH_SECRET_KEY=aa…00`,

                        `REDASH_DATABASE_URL=postgresql://${pg_username}:${pg_password}${pg_host}:${pg_port}/${pg_dbname || "postgres"}`,
                        `REDASH_REDIS_URL=redis://${redis_primaryEndpointAddress}:${redis_port}/0`,
                    ].join("\n"),
            ),
    },
);
