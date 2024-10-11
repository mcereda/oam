import * as cloudinit from "@pulumi/cloudinit";
import * as pulumi from "@pulumi/pulumi";
import * as fs from 'fs';
import * as yaml from 'yaml';

const gitlabUrl = "https://gitlab.example.org";
const runnerToken = "glrt-…";

const securityUpdates_part = {
    filename: "cloud-config.security-updates.yml",
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
};


const userData = new cloudinit.Config(
    "userData",
    {
        gzip: false,
        base64Encode: false,
        parts: [
            securityUpdates_part,
            {
                filename: "cloud-config.docker.yml",
                mergeType: "dict(recurse_array,no_replace)+list(append)",
                contentType: "text/cloud-config",
                content: fs.readFileSync("./docker.yum.yaml", "utf8"),
            },
            {
                filename: "cloud-config.gitlab-runner.yml",
                mergeType: "dict(recurse_array,no_replace)+list(append)",
                contentType: "text/cloud-config",
                content: pulumi.all([ gitlabUrl, runnerToken ]).apply(
                    ([ gitlabUrl, runnerToken ]) => yaml.stringify({
                        yum_repos: {
                            "gitlab-runner": {
                                name: "Gitlab Runner",
                                baseurl: "https://packages.gitlab.com/runner/gitlab-runner/amazon/2023/$basearch",
                                gpgcheck: true,
                                gpgkey: [
                                    "https://packages.gitlab.com/runner/gitlab-runner/gpgkey",
                                    "https://packages.gitlab.com/runner/gitlab-runner/gpgkey/runner-gitlab-runner-4C80FB51394521E9.pub.gpg",
                                    "https://packages.gitlab.com/runner/gitlab-runner/gpgkey/runner-gitlab-runner-49F16C5CC3A0F81F.pub.gpg",
                                ].join("\n"),
                                sslverify: true,
                                sslcacert: "/etc/pki/tls/certs/ca-bundle.crt",
                                metadata_expire: 300,
                            },
                        },
                        write_files: [{
                            path: "/etc/gitlab-runner/config.toml",
                            permissions: "0600",
                            content: [
                                `concurrent = 1`,
                                `check_interval = 0`,
                                `shutdown_timeout = 0`,
                                ``,
                                `[session_server]`,
                                `  session_timeout = 1800`,
                                `[[runners]]`,
                                `  name = "runner autoscaler"`,
                                `  url = "${gitlabUrl}"`,
                                `  token = "${runnerToken}"`,
                                `  executor = "sh"`,
                            ].join("\n"),
                        }],
                        packages: [ "gitlab-runner-17.4.0" ],
                        runcmd: [
                            "systemctl daemon-reload",
                            "systemctl enable --now 'gitlab-runner'",
                        ],
                    })
                ),
            },
            {
                filename: "cloud-config.postgres.yml",
                mergeType: "dict(recurse_array,no_replace)+list(append)",
                contentType: "text/cloud-config",
                content: yaml.stringify({
                    package_upgrade: false,
                    packages: [ "postgresql" ],
                    runcmd: [
                        "systemctl daemon-reload",
                        "systemctl enable --now 'postgres'",
                    ]
                }),
            },
        ],
    },
);

export userData.rendered;
