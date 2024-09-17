import * as acme from "@pulumiverse/acme";
import * as aws from "@pulumi/aws";
import * as cloudinit from "@pulumi/cloudinit";
import * as pulumi from "@pulumi/pulumi";
import * as tls from "@pulumi/tls";
import * as yaml from "yaml";

/**
 * NOT WORKING
 * Fails during certificate creation with errors "not found" and "response from server: EOF"
 * It seems to find the DNS zone. It is like it does not find the DNS entry even if I create it manually?
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
