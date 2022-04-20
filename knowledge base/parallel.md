# GNU Parallel

## TL;DR

```shell
# group output (--group)
# fill up cpu threads (--jobs 100%)
# use newline as delimiter for the arguments in input
# simulate and print to output the command that would have been executed
find . -type f \
| parallel --group --jobs 0 --delimiter '\n' --dry-run clamscan {}

# get the exit status of all subjobs (--joblog $outfile)
# use all the threads you can (--jobs 0), hammering the cpu
find . -type d -name .git -exec dirname "{}" + \
| parallel --group --jobs 0 --tagstring {/} --joblog - \
    'git -C {} pull --recurse-submodules'

# inject istio to all deployments in a namespace in (GNU) parallel
kubectl get deployments -o jsonpath='{.items[*].metadata.name}' \
| parallel --group --jobs 0 'kubectl -n ${NAMESPACE:-default} apply -f \
    <(istioctl kube-inject -f \
        <(kubectl get deployments,services {} -o json))'

# given a list of namespaces get pods and their nodes
parallel --group --jobs 100% --tag \
  "kubectl --context $KUBE_CONTEXT --namespace {} get pods --output json \
   | jq -r '.items[] | .metadata.name + \"\t\" + .spec.nodeName' -" \
  ::: "${NAMESPACES}" \
| column -t
```

## Further readings

- GNU Parallel's [man page]
- GNU Parallel's [tutorial]
- [Obtaining exit status values from GNU parallel]

[man page]: https://www.gnu.org/software/parallel/man.html
[tutorial]: https://www.gnu.org/software/parallel/parallel_tutorial.html

[obtaining exit status values from gnu parallel]: https://stackoverflow.com/questions/6310181/obtaining-exit-status-values-from-gnu-parallel#6789085
