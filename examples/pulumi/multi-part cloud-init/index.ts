import * as cloudinit from "@pulumi/cloudinit";
import * as fs from 'fs';
import * as yaml from 'yaml';

export const userData = new cloudinit.Config(
    "userData",
    {
        gzip: false,
        base64Encode: false,
        parts: [
            {
                contentType: "text/cloud-config",
                content: fs.readFileSync("../../cloud-init/aws.ssm.yaml", "utf8"),
                filename: "cloud-config.ssm.yml",
            },
            {
                contentType: "text/cloud-config",
                content: fs.readFileSync("../../cloud-init/docker.yum.yaml", "utf8"),
                filename: "cloud-config.docker.yml",
                mergeType: "dict(recurse_array,no_replace)+list(append)",
            },
            {
                contentType: "text/cloud-config",
                content: yaml.stringify({
                    write_files: [{
                        path: "/etc/cron.daily/security-updates",
                        permissions: "0755",
                        content: [
                            "#!/bin/bash",
                            "dnf -y upgrade --security --nobest",
                        ].join("\n"),
                        defer: true,
                    }],
                }),
                filename: "cloud-config.security-updates.yml",
                mergeType: "dict(recurse_array,no_replace)+list(append)",
            },
        ],
    },
);
