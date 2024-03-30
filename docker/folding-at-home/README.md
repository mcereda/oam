# Folding at home

```sh
CURRENT_UID=$(id -u):$(id -g) docker-compose up
```

does not work. the container fails after reading the GPU list. Maybe mine is not there?

## Sources

- [Official Folding@home Containers]
- [Folding@home GPU Container]
- [Folding@home GPU Container readme]
- [fah-rocm - Folding@home GPU Container for AMD ROCm stack]

[Folding@home GPU Container readme]: https://github.com/FoldingAtHome/containers/blob/master/fah-gpu/README.md
[fah-rocm - Folding@home GPU Container for AMD ROCm stack]: https://github.com/FoldingAtHome/containers/tree/master/fah-gpu-amd
[Official Folding@home Containers]: https://github.com/foldingathome/containers/
[Folding@home GPU Container]: https://hub.docker.com/r/foldingathome/fah-gpu
