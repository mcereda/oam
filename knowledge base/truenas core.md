# TrueNAS core

## Table of contents <!-- omit in toc -->

1. [TL;DR](#tldr)
1. [Default permissions on files and directories](#default-permissions-on-files-and-directories)
   1. [Default permissions in SMB shares](#default-permissions-in-smb-shares)
1. [Further readings](#further-readings)
1. [Sources](#sources)

## TL;DR

## Default permissions on files and directories

Suppose you want a shared dataset to set the default permissions of newly created files and directories to `0664` and `0775` respectively.

The best way to achieve this would be to set up the dataset's ACLs accordingly:

| Who       | ACL Type | Permissions Type | Permissions                                                                                                                                                                                   | Flags Type | Flags             | Translated `getfacl` Tags                | Resulting Unix Permissions |
| --------- | -------- | ---------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ---------- | ----------------- | ---------------------------------------- | -------------------------- |
| owner@    | Allow    | Advanced         | Read Data, Write Data, Append Data<br/>Read Named Attributes, Write Named Attributes<br/>Read Attributes, Write Attributes<br/>Delete<br/>Read ACL, Write ACL<br/>Write Owner<br/>Synchronize | Advanced   | File Inherit      | `   owner@:rw-p-daARWcCos:f------:allow` | `-rw-------`               |
| owner@    | Allow    | Basic            | Full Control                                                                                                                                                                                  | Advanced   | Directory Inherit | `   owner@:rwxpDdaARWcCos:-d-----:allow` | `drwx------`               |
| group@    | Allow    | Advanced         | Read Data, Write Data, Append Data<br/>Read Named Attributes, Write Named Attributes<br/>Read Attributes, Write Attributes<br/>Delete<br/>Read ACL, Write ACL<br/>Write Owner<br/>Synchronize | Advanced   | File Inherit      | `   group@:rw-p-daARWcCos:f------:allow` | `----rw----`               |
| group@    | Allow    | Basic            | Full Control                                                                                                                                                                                  | Advanced   | Directory Inherit | `   group@:rwxpDdaARWcCos:-d-----:allow` | `d---rwx---`               |
| everyone@ | Allow    | Advanced         | Read Data<br/>Read Named Attributes<br/>Read Attributes<br/>Read ACL                                                                                                                          | Advanced   | File Inherit      | `everyone@:r-----a-R-c---:f------:allow` | `-------r--`               |
| everyone@ | Allow    | Advanced         | Read Data<br/>Read Named Attributes<br/>Execute<br/>Read Attributes<br/>Read ACL                                                                                                              | Advanced   | Directory Inherit | `everyone@:r-x---a-R-c---:-d-----:allow` | `d------r-x`               |

### Default permissions in SMB shares

A simpler but arguably worse way to achieve a similar result **only for SMB shares** is by using the _mask_ `smb.conf` additional parameters in the share definition:

```txt
create mask = 664
directory mask = 775
```

If a dataset has no ACLs set and you create a SMB share for it, you are asked to create them for its filesystem.<br/>
You can cancel at this point and go for the additional parameters instead.

## Further readings

- [Website]
- [Proxmox]
- [OpenMediaVault]

## Sources

All the references in the [further readings] section, plus the following:

- [How to run TrueNAS on Proxmox?]

<!--
  References
  -->

<!-- Upstream -->
[website]: https://www.truenas.com/truenas-core/

<!-- In-article sections -->
[further readings]: #further-readings

<!-- Knowledge base -->
[disks maintenance]: disks%20maintenance.md
[openmediavault]: openmediavault.md
[proxmox]: proxmox.md

<!-- Others -->
[how to run truenas on proxmox?]: https://www.youtube.com/watch?v=M3pKprTdNqQ
