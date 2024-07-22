import * as acme from '@pulumiverse/acme';
import * as aws from "@pulumi/aws";
import * as cloudinit from "@pulumi/cloudinit";
import * as command from "@pulumi/command";
import * as pulumi from "@pulumi/pulumi";
import * as tls from "@pulumi/tls";
import * as yaml from "yaml";
import * as time from "@pulumiverse/time";

/**
 * Requirements - start
 * -------------------------------------
 **/

const ami = aws.ec2.getAmiOutput({
    owners: [ "amazon" ],
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

const role = aws.iam.getRoleOutput({
    name: "gitlab-omnibus",
});

const subnet = aws.ec2.getSubnetOutput({
    filters: [{
        name: "tag:Name",
        values: [ "Private A" ]
    }],
});

/* Requirements - end */


/**
 * LetsEncrypt certificate - start
 * -------------------------------------
 * Leverage the DNS challenge to keep the instance private at all times.
 **/

const privateKey = new tls.PrivateKey(
    "privateKey",
    { algorithm: "RSA" },
);
const registration = new acme.Registration(
    "registration",
    {
        accountKeyPem: privateKey.privateKeyPem,
        emailAddress: "example@company.com",
    },
);
const certificate = new acme.Certificate(
    "certificate",
    {
        accountKeyPem: registration.accountKeyPem,
        commonName: "gitlab.company.com",
        dnsChallenges: [{
            provider: "route53",
        }],
    },
);

/* LetsEncrypt certificate - end */


/**
 * Instance - start
 * -------------------------------------
 **/

const userData = new cloudinit.Config(
    "cloudConfig",
    {
        gzip: true,
        base64Encode: true,
        parts: [
            {
                contentType: "text/cloud-config",
                content: pulumi.all([
                    certificate.certificateDomain.apply(v => v),
                    certificate.certificatePem.apply(v => v),
                    certificate.privateKeyPem.apply(v => v),
                ]).apply(([domain, certificate, privateKey]) => yaml.stringify({
                    write_files: [
                        {
                            path: `/etc/gitlab/ssl/${domain}.crt`,
                            content: btoa(certificate),
                            permissions: "0o600",
                            encoding: "base64",
                            defer: true,
                        },
                        {
                            path: `/etc/gitlab/ssl/${domain}.key`,
                            content: btoa(privateKey),
                            permissions: "0o600",
                            encoding: "base64",
                            defer: true,
                        },
                    ],
                })),
                filename: "cloud-config.letsencrypt.certificate.yml",
                mergeType: "dict(recurse_array,no_replace)+list(append)",
            },
        ],
    },
);

const keyPair = new aws.ec2.KeyPair(
    "keypair",
    {
        keyName: "gitlab-omnibus",
        publicKey: "ssh-ed25519 AAAAC3NzaC1lZBI1NTE5AAAAIA1CBRl1FnUu/-rUC4NTKo-d99M3bfmJHWckGbYmtYui",
    },
);

const instance = new aws.ec2.Instance(
    "instance",
    {
        availabilityZone: subnet.apply(s => s.availabilityZone),
        subnetId: subnet.apply(s => s.id),
        associatePublicIpAddress: false,

        instanceType: "t4g.xlarge",
        ami: ami.apply(ami => ami.id),
        iamInstanceProfile: role.name,
        disableApiTermination: true,
        monitoring: true,
        userData: userData.rendered,

        ebsOptimized: true,
        keyName: keyPair.keyName,
        rootBlockDevice: {
            volumeType: "gp3",
            volumeSize: 100,
            tags: {
                Description: "Instance root disk",
                Name: "Gitlab Omnibus",
            },
        },

        tags: {
            Name: "Gitlab Omnibus",
            SSMManaged: "true",
        },
    },
);

const wait5Minutes = new time.Sleep(
    "wait5Minutes",
    { createDuration: "30s" },
    { dependsOn: [instance] }
);

new command.local.Command(
    "ansiblePlaybook",
    { create: "make run" },
    {
        dependsOn: [
            instance,
            wait5Minutes,
        ],
    },
);

/* Instance - end */
