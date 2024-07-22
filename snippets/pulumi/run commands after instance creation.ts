/**
 * Run commands after creation
 * -----------------------------------------------------------------------------
 *
 * Replace the 'command.local.Command' resource to run it again:
 * `pulumi up --replace "urn:pulumi:any::stackName::command:local:Command::ansiblePlaybook-ssh"`
 **/

import * as aws from "@pulumi/aws";
import * as command from "@pulumi/command";

const instance = new aws.ec2.Instance(
    "instance",
    { … }
);

command.local.Command(
    "notify",
    { create: "say 'instance created'" }
);

instance.privateDns.apply(host => new command.local.Command(
    "ansiblePlaybook-ssh",
    { create: `ansible-playbook -i '${host},' -D 'playbook.yaml'` },
));

instance.id.apply(id => new command.local.Command(
    "ansiblePlaybook-awsSsm",
    {
        create: `
            ansible-playbook
                -e 'ansible_aws_ssm_plugin=/usr/local/sessionmanagerplugin/bin/session-manager-plugin'
                -e 'ansible_connection=aws_ssm'
                -e 'ansible_aws_ssm_bucket_name=ssm-bucket'
                -e 'ansible_aws_ssm_region=eu-west-1'
                -e 'ansible_remote_tmp=/tmp/.ansible-\${USER}/tmp'
                -i '${id},'
                -D 'playbook.yaml'
        `,
    },
));
