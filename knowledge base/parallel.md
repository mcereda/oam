# GNU Parallel

## TL;DR

```sh
# Group output ('--group', defaults to on).
# Fill up CPU threads ('--jobs 0' or '--jobs 100%').
# Use newline as delimiter for the arguments in input.
# Simulate and print to output the command that would have been executed.
find . -type f \
| parallel --group --jobs 0 --delimiter '\n' --dry-run clamscan {}

# Rsync all folders in a directory to a NAS.
# So it one by one, and print and properly quote the command before execution.
parallel -qt -j 1 \
  rsync -a --info=stats2 {} nas.lan:/shares/backup/ \
  ::: backup/.snapshots/*

# Get the exit status of all subjobs ('--joblog $outfile').
# Use all the threads you can (--jobs 0), hammering the CPU.
find . -type d -name .git -exec dirname "{}" + \
| parallel --jobs 0 --tagstring {/} --joblog - \
    'git -C {} pull --recurse-submodules'

# Inject Istio's sidecar to all Deployments in a Namespace.
kubectl get deployments -o jsonpath='{.items[*].metadata.name}' \
| parallel --jobs 0 'kubectl -n ${NAMESPACE:-default} apply -f \
    <(istioctl kube-inject -f \
        <(kubectl get deployments,services {} -o json))'

# Given a list of Namespaces, get all Pods in them and the Nodes they are
# running on.
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
