import * as pulumi from "@pulumi/pulumi";
import * as bitwarden from "@pulumi/bitwarden";

/*
 * Get an Item's attachment from Bitwarden Password Manager
 * -----------------
 * Only works for Bitwarden Password Manager, the Secrets Manager offers different resources.
 * Refer <https://www.pulumi.com/registry/packages/bitwarden/>.
 *
 * Requirements:
 *  - `pulumi package add 'terraform-provider' 'maxlaverse/bitwarden'`
 *  - `export BW_CLIENTID='user.abcdef01-2345-6789-abcd-ef0123456789' \
 *       BW_CLIENTSECRET='someBitwardenApiKeySecret' BW_PASSWORD='someBitwardenMasterPassword'`
 */

/*
 * Just looking for it
 * -----------------
 */

let bitwardenItem: pulumi.Output<bitwarden.GetItemLoginResult> = bitwarden.getItemLoginOutput({
    search: "Some item in the whole vault",
});

/*
 * Specifying successive resources
 * -----------------
 */

const bitwardenOrganization: pulumi.Output<bitwarden.GetOrganizationResult> = bitwarden.getOrganizationOutput({
    search: "Some organization",
})
const bitwardenCollection: pulumi.Output<bitwarden.GetOrgCollectionResult> = bitwarden.getOrgCollectionOutput({
    organizationId: bitwardenOrganization.apply(org => org.id!),
    search: "Some collection in the organization",
});
bitwardenItem = bitwarden.getItemLoginOutput({
    filterCollectionId: bitwardenCollection.apply(org => org.id!),
    search: "Some item in the organization's collection",
});

/*
 * Use the item's attachment
 * -----------------
 */

const attachment: pulumi.Output<bitwarden.GetAttachmentResult> = bitwarden.getAttachmentOutput({
    itemId: bitwardenItem.id!.apply(itemId => itemId!),
    id: bitwardenItem.attachments!.apply(
        attachments => attachments
            .find(attachment => attachment.fileName === "ssh_key.pub"))
            .apply(attachment => attachment!.id),
});
attachment.apply(attachment => console.log(attachment.content));
