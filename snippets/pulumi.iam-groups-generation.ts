import * as aws from "@pulumi/aws";

const iamGroups = new Map<string, aws.iam.Group>();
[ "business-intelligence", "engineering", "product" ].forEach(
    (name: string) => iamGroups.set(
        name,
        new aws.iam.Group(
            name,
            { name: name },
            {
                import: name,
                protect: true,
            },
        ),
    ),
);

const iamUsers = new Map<string, aws.iam.User>();
[
    {
        name: "me",
        groups: [ "engineering" ],
    },
    {
        name: "admin",
        groups: [
            "business-intelligence",
            "engineering",
            "product",
        ],
    },
].forEach(
    (user: { name: string, groups: string[] }) => {
        // Create the IAM user
        const iamUser = new aws.iam.User(
            user.name,
            { name: user.name },
            {
                ignoreChanges: [
                    // tags are used to store the users' keys' id
                    "tags",
                    "tagsAll",
                ],
                import: user.name,
                protect: true,
            },
        );

        // Add the IAM user to the 'users' Map
        iamUsers.set(user.name, iamUser);

        // Add the user to the groups in its definition.
        iamUser.name.apply(username => new aws.iam.UserGroupMembership(
            username,
            {
                user: username,
                groups: user.groups,
            },
            {
                import: `${username}/${user.groups.join('/')}`,
                protect: true,
            },
        ));
    },
);
