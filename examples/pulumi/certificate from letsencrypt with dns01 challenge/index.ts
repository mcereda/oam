import * as acme from '@pulumiverse/acme';
import * as cloudinit from "@pulumi/cloudinit";
import * as pulumi from "@pulumi/pulumi";
import * as tls from "@pulumi/tls";
import * as yaml from "yaml";


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
