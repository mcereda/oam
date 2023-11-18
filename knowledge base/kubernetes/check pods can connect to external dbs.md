# Check Pods can connect to external DBs

## Table of contents <!-- omit in toc -->

1. [TL;DR](#tldr)
1. [Further readings](#further-readings)

## TL;DR

1. Get a shell on a test container.

   ```sh
   kubectl run --generator='run-pod/v1' --image 'alpine' -it --rm \
     --limits 'cpu=200m,memory=512Mi' --requests 'cpu=200m,memory=512Mi' \
     ${USER}-mysql-test -- sh
   ```

1. Install the utility applications needed for the tests.

   ```sh
   apk --no-cache add 'mysql-client' 'netcat-openbsd''
   ```

1. Test basic connectivity to the external service.

   ```sh
   nc -vz -w3 '10.0.2.15' '3306'
   ```

1. Test application connectivity.

   ```sh
   mysql --host '10.0.2.15' --port '3306' --user 'root'
   ```

## Further readings

- [Kubernetes]
- [`kubectl`][kubectl]

<!--
  References
  -->

<!-- Knowledge base -->
[kubectl]: kubectl.md
[kubernetes]: README.md
