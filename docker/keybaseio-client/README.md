# Keybase client

The image gets `git` so I can use it to manage my repositories on keybase.io.

Can surely be vastly improved.

1. [TL;DR](#tldr)
2. [Permissions mismatch in the binded directory](#permissions-mismatch-in-the-binded-directory)
3. [Further readings](#further-readings)

## TL;DR

```sh
# Build it.
docker build -t 'michelecereda/keybaseio-client' .

# Start the service.
# Needs '--privileged' do be able to write to the disk.
docker run \
  -d --name 'keybaseio-client' \
  -e KEYBASE_SERVICE='1' \
  -e KEYBASE_USERNAME='user' \
  -e KEYBASE_PAPERKEY='paper key …' \
  --privileged \
  -v '/path/to/repos/root:/repos.ro' \
  'michelecereda/keybaseio-client'

# `bindfs` needs to be run as 'root' to use the '--create-for-user' flag.
# Need to automate this when the container starts (entrypoint?).
docker exec -u root 'keybaseio-client' \
  bindfs \
    --force-user='keybase' --force-group='keybase' \
    --create-for-user='keybase' --create-for-group='keybase' \
    --chown-ignore --chgrp-ignore \
    '/repos.ro' \
    '/repos.rw'

# Leverage the service to execute commands.
docker exec -u 'keybase' 'keybaseio-client' keybase whoami
docker exec -u 'keybase' 'keybaseio-client' \
  git clone 'keybase://private/user/repo' '/repos.rw/repo'

# Fix ownership of the new files in the directory (if needed).
# The container will still be able to see them as its own.
chown -R 'user':'group' /path/to/repos/root
```

## Permissions mismatch in the binded directory

Due to continers' nature and user management, there might be a mismatch between the user id in the container and the one of the user owning the repositories directory on the host.

To solve this, I applied Hongli Lai's solution in [Docker and the Host Filesystem Owner Matching Problem]:

```sh
# Contents of the current test folder.
$ ls -l
drwxr-xr-x 1 myuser users   0 Sep 17 20:31 repos

# Start the service.
$ docker run \
>   -d --name 'keybaseio-client' \
>   --privileged \
>   -v "${PWD}/repos:/repos.ro" \
>   -e KEYBASE_SERVICE='1' \
>   -e KEYBASE_USERNAME='user' \
>   -e KEYBASE_PAPERKEY='paper key …' \
>   'michelecereda/keybaseio-client'
e6c550e02e1796cabfd752d8326e3c99d5f3646baa2e9befa34964b94ae67609

# Mount the ro folder in the container to a rw folder I can use.
$ docker exec -u root 'keybaseio-client' \
>   bindfs --chown-ignore --chgrp-ignore \
>     --force-user='keybase' --force-group='keybase' \
>     --create-for-user='keybase' --create-for-group='keybase' \
>     '/repos.ro' '/repos.rw'

# Current permissions of the mounted folder on the host.
$ ls -l repos
total 0
-rwx------ 1 myuser users   0 Sep 18 01:21 file.txt

# Current permissions of the mounted folder in the container.
$ docker exec -u keybase -ti 'keybaseio-client' ls -l '/repos.rw'
total 0
-rwx------ 1 keybase keybase   0 Sep 17 23:21 file.txt

# Clone a repository from keybase.
$ docker exec -u keybase -ti 'keybaseio-client' git clone keybase://private/mek/repo /repos.rw/repo
Cloning into '/repos.rw/repo'...
Initializing Keybase... done.
Syncing with Keybase... done.
Counting: 10.46 KB... done.
Cryptographic cloning: (100.00%) 10.46/10.46 KB... done.

# Current permissions of the mounted folder in the container.
$ sudo docker exec -u keybase -ti 'keybaseio-client' ls -l '/repos.rw'
total 0
-rwx------ 1 keybase keybase   0 Sep 17 23:21 file.txt
drwxr-xr-x 1 keybase keybase 304 Sep 18 08:04 repo

# Current permissions of the mounted folder on the host.
$ ls -l repos
total 0
-rwx------ 1 myuser users   0 Sep 18 01:21 file.txt
drwxr-xr-x 1 1000   1000  304 Sep 18 08:04 repo

# Fix the permissions on the host.
$ sudo chown -R 'myuser':'users' 'repos/repo'
$ ls -l repos
total 0
-rwx------ 1 myuser users   0 Sep 18 01:21 file.txt
drwxr-xr-x 1 myuser users 304 Sep 18 10:04 repo

# Check the permissions of the mounted folder in the container.
$ docker exec -u keybase -ti 'keybaseio-client' ls -l '/repos.rw'
total 0
-rwx------ 1 keybase keybase   0 Sep 17 23:21 file.txt
drwxr-xr-x 1 keybase keybase 304 Sep 18 08:04 repo
```

## Further readings

- [keybaseio/client] on DockerHub
- [Configure the selinux label]
- [How to create docker volume device/host path] (not used but interesting)
- [Docker and the Host Filesystem Owner Matching Problem]

[keybaseio/client]: https://hub.docker.com/r/keybaseio/client

[configure the selinux label]: https://docs.docker.com/storage/bind-mounts/#configure-the-selinux-label
[how to create docker volume device/host path]: https://stackoverflow.com/questions/49950326/how-to-create-docker-volume-device-host-path#49952217
[docker and the host filesystem owner matching problem]: https://www.fullstaq.com/knowledge-hub/blogs/docker-and-the-host-filesystem-owner-matching-problem
