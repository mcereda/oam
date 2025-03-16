# Image Builder

AWS service automating the creation, management, and deployment of customized AMIs or Docker images.

1. [TL;DR](#tldr)
1. [Further readings](#further-readings)
   1. [Sources](#sources)

## TL;DR

Images created by Image Builder in one's account are owned by that account.

Leverages AWS' Task Orchestrator and Executor component management application.<br/>
For AMIs, it:

1. Creates EC2 instances for building and validation.
1. Creates a snapshots of the result.
1. Terminates the EC2 instances used for building.
1. Uses that snapshot to create new EC2 instances for testing.

For containers, it:

1. Creates EC2 instances for building and validation.
1. Builds container images.
1. Runs containers from the images for testing.
1. Terminates the EC2 instances used for building.

<details>
  <summary>Glossary</summary>

| Term                         | Summary                                                                                         |
| ---------------------------- | ----------------------------------------------------------------------------------------------- |
| Component                    | YAML-based document defining the steps to take to build, validate or test images                |
| Recipe                       | Document defining the base image and the components to apply to it to produce the desired image |
| Infrastructure Configuration | The EC2 infrastructure to use to build and test the desired image                               |
| Distribution Configuration   | How the outputted images are made available to specified AWS Regions                            |
| Pipeline                     | Automation framework for creating and maintaining custom images                                 |

</details>

<details style="padding-bottom: 1em;">
  <summary>Supported operating systems</summary>

Refer [Supported operating systems] for the updated table.

| Operating system/distribution      | Supported versions                             |
| ---------------------------------- | ---------------------------------------------- |
| Amazon Linux                       | 2, 2023                                        |
| CentOS                             | 7, 8                                           |
| CentOS Stream                      | 8                                              |
| Mac OS X                           | 12.x (Monterey), 13.x (Ventura), 14.x (Sonoma) |
| Red Hat Enterprise Linux (RHEL)    | 7, 8, 9                                        |
| SUSE Linux Enterprise Server (SLE) | 12, 15                                         |
| Ubuntu                             | 18.04 LTS, 20.04 LTS, 22.04 LTS, 24.04 LTS     |
| Windows Server                     | 2012 R2, 2016, 2019, 2022                      |

</details>

Image Builder costs **nothing** to create custom AMI or container images per se.<br/>
However, standard pricing applies for the other services that are used by or in the process, like EC2 instances, EBS
volumes, and ECR storage.

Components can be specified **at most once** in an image recipe.

Steps:

<details>
  <summary>AMI creation</summary>

1. \[optional] Create new _components_ as needed.
1. \[optional] Create a new image _recipe_.
1. \[optional] Create a new _infrastructure configuration_.
1. \[optional] Create a new _distribution configuration_.
1. Create a new _pipeline_.

</details>
<details>
  <summary>Container image creation</summary>

TODO

</details>

## Further readings

- [Image baking in AWS using Packer and Image builder]

### Sources

- [What is Image Builder?]
- [Building a Reusable Image Pipeline with AWS Image Builder]

<!--
  Reference
  ═╬═Time══
  -->

<!-- In-article sections -->
<!-- Knowledge base -->
<!-- Files -->
<!-- Upstream -->
[supported operating systems]: https://docs.aws.amazon.com/imagebuilder/latest/userguide/what-is-image-builder.html#image-builder-os
[what is image builder?]: https://docs.aws.amazon.com/imagebuilder/latest/userguide/what-is-image-builder.html

<!-- Others -->
[building a reusable image pipeline with aws image builder]: https://dev.to/aws-builders/building-a-reusable-image-pipeline-with-aws-image-builder-17eh
[image baking in aws using packer and image builder]: https://dev.to/santhoshnimmala/image-baking-in-aws-using-packer-and-image-builder-1ed3
