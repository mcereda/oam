import * as cloudinit from "@pulumi/cloudinit";
import * as yaml from 'yaml';

const userData = new cloudinit.Config(
    "userData",
    {
        gzip: false,
        base64Encode: false,
        parts: [
            {
                // docker on AmazonLinux 2023
                filename: "cloud-config.docker-engine.yml",
                contentType: "text/cloud-config",
                content: yaml.stringify({
                    package_upgrade: false,
                    packages: [
                        "docker",
                        "amazon-ecr-credential-helper",
                    ],
                    write_files: [
                        {
                            path: "/root/.docker/config.json",
                            permissions: "0644",
                            content: `{ "credsStore": "ecr-login" }`,
                        },
                    ],
                    runcmd: [
                        "systemctl daemon-reload",
                        "systemctl enable --now docker.service",
                        "grep docker /etc/group -q && usermod -a -G docker ec2-user"
                    ],
                }),
            },
        ],
    },
);

export userData.rendered;
