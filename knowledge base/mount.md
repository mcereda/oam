# Mount

## TL;DR

```sh
# Mount a file system by its label.
mount -L 'label' '/path/to/mount/point'

# Mount a file system by its UUID.
mount -U 'uuid' '/path/to/mount/point'

# Manually Mount a SMB share.
mount -t 'cifs' -o 'username=user_name' '//server/share_name' '/mount/point'

# Mount a SMB share using an encrypted SMB 3.0 connection.
mount -t 'cifs' -o 'username=DOMAIN\Administrator,seal,vers=3.0' \
  '//server_name/share_name' '/mount/point'

# Mount a NFS share
mount -t 'nfs' 'server:/share_name' '/mount/point'
mount -t 'nfs' -o 'nfsvers=3,nolock' 'server:/share_name' '/mount/point'

# Mount a temporary RAM disk.
mount -t tmpfs tmpfs '/mount/point' -o 'size=2048m'
```

## Further readings

- [Mount a disk partition using LABEL]
- [Mount a disk partition using UUID]
- [How to mount a .img file]
- [Manually Mounting an SMB Share]
- [Access denied by server while mounting NFS share]

[access denied by server while mounting nfs share]: https://www.thegeekdiary.com/mount-nfs-access-denied-by-server-while-mounting-how-to-resolve/
[how to mount a .img file]: https://www.linuxquestions.org/questions/linux-general-1/how-to-mount-img-file-882386/#post4366162
[manually mounting an smb share]: https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/7/html/storage_administration_guide/mounting_an_smb_share
[mount a disk partition using label]: https://www.cyberciti.biz/faq/rhel-centos-debian-fedora-mount-partition-label/
[mount a disk partition using uuid]: https://www.cyberciti.biz/faq/linux-finding-using-uuids-to-update-fstab/
