# Print a compressed stream to stdout

```sh
cat file.zip | zcat
cat file.zip | busybox unzip -p -
cat file.gz | gunzip -c -
curl 'https://example.com/some.zip' | bsdtar -xOf -
```

## Sources

- [Unzip from stdin to stdout]

[unzip from stdin to stdout]: https://serverfault.com/questions/735882/unzip-from-stdin-to-stdout-funzip-python
