# Check a Pod can connect to an external DB

## TL;DR

```sh
# access a test container
kubectl run --generator=run-pod/v1 --limits 'cpu=200m,memory=512Mi' --requests 'cpu=200m,memory=512Mi' --image alpine ${USER}-mysql-test -it -- sh

# install programs
apk --no-cache add mysql-client netcat-openbsd

# test plain connectivity
nc -vz -w3 10.0.2.15 3306

# test the client can connect
mysql --host 10.0.2.15 --port 3306 --user root
```
