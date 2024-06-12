#!/usr/bin/env sh

printf 'something plain' | base64
echo -n 'something plain' | base64
echo 'c29tZXRoaW5nIHBsYWlu' | base64 -d

echo 'something plain with final newline' | base64
echo 'c29tZXRoaW5nIHBsYWluIHdpdGggZmluYWwgbmV3bGluZQo=' | base64 -d

printf 'something plain' | gzip | base64
echo H4sIAPQWZmYAAyvOz00tycjMS1coyEnMzAMA2StAzA8AAAA= | base64 -d | gzip
