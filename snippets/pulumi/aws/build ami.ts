import * as aws from "@pulumi/aws";

const awsRegion_output = aws.getRegionOutput();

const dockerEngineEnabled_ami_al2_x86_recipe = new aws.imagebuilder.ImageRecipe(
    "dockerEngineEnabled-ami-al2-x86",
    {
        name: "DockerEngineEnabled-AMI",
        description: "Amazon Linux 2 with Docker Engine",
        version: "1.0.0",
        parentImage: "arn:aws:imagebuilder:eu-west-1:aws:image/amazon-linux-2-x86/x.x.x",  // 'docker-ce-linux' component does not support al2023
        components: [
            { componentArn: "arn:aws:imagebuilder:eu-west-1:aws:component/docker-ce-linux/x.x.x" },
            { componentArn: "arn:aws:imagebuilder:eu-west-1:aws:component/reboot-test-linux/x.x.x" },
        ],

    },
);
const default_infrastructureConfiguration = new aws.imagebuilder.InfrastructureConfiguration(
    "default",
    {
        name: "Default",
        instanceProfileName: "EC2InstanceProfileForImageBuilder",
    },
);
const dockerEngineEnabled_ami_distributionConfiguration = new aws.imagebuilder.DistributionConfiguration(
    "dockerEngineEnabled-ami",
    {
        name: "DockerEngineEnabled-AMI",
        distributions: [{
            region: awsRegion_output.apply(region => region.name),
            amiDistributionConfiguration: {
                name: "DockerEngineEnabled-{{ imagebuilder:buildDate }}",
                description: "Amazon Linux 2 with Docker Engine",
                amiTags: {
                    Name: "Amazon Linux 2 with Docker Engine",
                },
            },
        }],
    },
);
new aws.imagebuilder.ImagePipeline(
    "dockerEngineEnabled-ami-al2-x86",
    {
        name: "DockerEngineEnabled-AMI",
        description: "Amazon Linux 2 with Docker Engine",
        imageRecipeArn: dockerEngineEnabled_ami_al2_x86_recipe.arn,
        infrastructureConfigurationArn: default_infrastructureConfiguration.arn,
        distributionConfigurationArn: dockerEngineEnabled_ami_distributionConfiguration.arn,
        schedule: {
            // every sunday at midnight ams time if there are updates to the dependencies
            scheduleExpression: "cron(0 0 * * ? *)",
            timezone: "Europe/Amsterdam",
        },
    },
);
