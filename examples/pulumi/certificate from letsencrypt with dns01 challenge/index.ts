import * as acme from "@pulumiverse/acme";
import * as aws from "@pulumi/aws";
import * as cloudinit from "@pulumi/cloudinit";
import * as pulumi from "@pulumi/pulumi";
import * as tls from "@pulumi/tls";
import * as yaml from "yaml";

/**
 * NOT WORKING
 * Fails during certificate creation with the following trace:
 *   pulumi:pulumi:Stack (certificates-with-letsencrypt-dev):
 *     2024/09/17 23:50:18 [INFO] acme: Trying to resolve account by key
 *     2024-09-17T23:50:18.789+0200 [INFO]  plugin: configuring client automatic mTLS
 *     2024-09-17T23:50:18.802+0200 [DEBUG] plugin: starting plugin: path=/Users/user/.pulumi/plugins/resource-acme-v0.3.0/pulumi-resource-acme args=["/Users/user/.pulumi/plugins/resource-acme-v0.3.0/pulumi-resource-acme", "-dnsplugin"]
 *     2024-09-17T23:50:18.805+0200 [DEBUG] plugin: plugin started: path=/Users/user/.pulumi/plugins/resource-acme-v0.3.0/pulumi-resource-acme pid=27352
 *     2024-09-17T23:50:18.807+0200 [DEBUG] plugin: waiting for RPC address: plugin=/Users/user/.pulumi/plugins/resource-acme-v0.3.0/pulumi-resource-acme
 *     2024-09-17T23:50:18.842+0200 [INFO]  plugin.pulumi-resource-acme: configuring server automatic mTLS: timestamp="2024-09-17T23:50:18.842+0200"
 *     2024-09-17T23:50:18.847+0200 [DEBUG] plugin.pulumi-resource-acme: plugin address: network=unix address=/var/folders/sw/nd9600w52nn6hp4_yxmykn8h0000gn/T/plugin4288581984 timestamp="2024-09-17T23:50:18.847+0200"
 *     2024-09-17T23:50:18.847+0200 [DEBUG] plugin: using plugin: version=1
 *     2024-09-17T23:50:18.853+0200 [TRACE] plugin.stdio: waiting for stdio data
 *     2024/09/17 23:50:18 [INFO] [gitlab.company.com] acme: Obtaining bundled SAN certificate given a CSR
 *     2024/09/17 23:50:19 [INFO] [gitlab.company.com] AuthURL: https://acme-staging-v02.api.letsencrypt.org/acme/authz-v3/12345678901
 *     2024/09/17 23:50:19 [INFO] [gitlab.company.com] acme: Could not find solver for: tls-alpn-01
 *     2024/09/17 23:50:19 [INFO] [gitlab.company.com] acme: Could not find solver for: http-01
 *     2024/09/17 23:50:19 [INFO] [gitlab.company.com] acme: use dns-01 solver
 *     2024/09/17 23:50:19 [INFO] [gitlab.company.com] acme: Preparing to solve DNS-01
 *     2024/09/17 23:50:19 [INFO] [gitlab.company.com] acme: Cleaning DNS-01 challenge
 *     2024/09/17 23:50:19 [WARN] [gitlab.company.com] acme: cleaning up failed: 2 errors occurred:
 *         * rpc error: code = Unknown desc = route53: not found, ResolveEndpointV2
 *         * error encountered while cleaning token for DNS challenge: rpc error: code = Unknown desc = route53: not found, ResolveEndpointV2
 *     2024/09/17 23:50:19 [INFO] Deactivating auth: https://acme-staging-v02.api.letsencrypt.org/acme/authz-v3/12345678901
 *     2024-09-17T23:50:19.743+0200 [DEBUG] plugin.stdio: received EOF, stopping recv loop: err="rpc error: code = Unavailable desc = error reading from server: EOF"
 *     2024-09-17T23:50:19.744+0200 [INFO]  plugin: plugin process exited: plugin=/Users/user/.pulumi/plugins/resource-acme-v0.3.0/pulumi-resource-acme id=27352
 * It seems to find the DNS zone. It is like it does not find the TXT DNS entry (_acme-challenge.gitlab.company.com) even if I create it manually?
 * Permissions are no issue
 **/


/**
 * LetsEncrypt certificate - start
 * -------------------------------------
 * Leverage the DNS challenge to keep the instance private at all times.
 * The private key *must be RSA* for ACME registration.
 **/

const acme_privateKey = new tls.PrivateKey(
    "privateKey",
    { algorithm: "RSA" },
);
const acme_registration = new acme.Registration(
    "registration",
    {
        accountKeyPem: acme_privateKey.privateKeyPem,
        emailAddress: "example@company.com",
    },
);
const dnsRecord = new aws.route53.Record(
    "gitlabDotCompanyDotcom",
    {
        zoneId: "ABCDEFGH01234",
        name: "gitlab.company.com",
        type: aws.route53.RecordType.A,
        records: [ "127.0.0.1" ],
        ttl: 300,
    },
);
const certificate = pulumi.all([ acme_privateKey.rsaBits, acme_registration.accountKeyPem ]).apply(
    ([ keyType, accountKeyPem ]) => new acme.Certificate(
        "gitlabDotCompanyDotcom",
        {
            commonName: dnsRecord.name,
            minDaysRemaining: 10,
            accountKeyPem: accountKeyPem,
            keyType: keyType.toString(),
            dnsChallenges: [{
                provider: "route53",
                config: {
                    AWS_ACCESS_KEY_ID: "AKIA2HKHF01234567ABC",
                    AWS_SECRET_ACCESS_KEY: "FfEeDdCcBbAa00/11223344556677889900aABcd",
                    AWS_REGION: "eu-west-1",
                    AWS_HOSTED_ZONE_ID: dnsRecord.zoneId,
                },
            }],
        },
    ),
);

/* LetsEncrypt certificate - end */


/**
 * Instance - start
 * -------------------------------------
 * https://serverfault.com/questions/62496/ssl-certificate-location-on-unix-linux#722646
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
                            path: `/etc/pki/tls/certs/${domain}.crt`,
                            content: btoa(certificate),
                            permissions: "0o600",
                            encoding: "base64",
                            defer: true,
                        },
                        {
                            path: `/etc/pki/tls/private/${domain}.key`,
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

/* Instance - end */
