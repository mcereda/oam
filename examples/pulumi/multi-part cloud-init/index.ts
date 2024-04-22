import * as cloudinit from "@pulumi/cloudinit";
import * as fs from 'fs';

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
        ],
    },
);
