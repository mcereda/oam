# NilFS

* -O _feature_: set feature
* -m _percentage_: set percentage of segments reserved to garbage collection (default: 5)
* -n: dry run
* -v: verbose

```sh
sudo mkfs -t 'nilfs2' -L 'label' -O 'block_count' -v '/dev/sdb1'
```
