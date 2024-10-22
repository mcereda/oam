#!/usr/bin/env sh

# Encrypt
# Avoid including the last new line character
printf 'something plain' | base64
echo -n 'something plain' | base64
# Include the last new line character
echo 'something plain *with* final newline' | base64
base64 <<< 'something plain'
openssl enc -base64 <<< 'something plain'
perl -MMIME::Base64 -ne 'printf "%s\n",encode_base64($_)' <<< 'something plain'
python -m base64 <<< 'something plain'

# Decrypt
echo 'c29tZXRoaW5nIHBsYWlu' | base64 -d
base64 -d <<< 'c29tZXRoaW5nIHBsYWluCg=='
echo 'c29tZXRoaW5nIHBsYWluICp3aXRoKiBmaW5hbCBuZXdsaW5lCg==' | base64 -di
openssl enc -base64 -d <<< 'c29tZXRoaW5nIHBsYWluICp3aXRoKiBmaW5hbCBuZXdsaW5lCg=='
perl -MMIME::Base64 -ne 'printf "%s\n",decode_base64($_)' <<< 'c29tZXRoaW5nIHBsYWluCg=='
python -m base64 -d <<< 'c29tZXRoaW5nIHBsYWluCg=='


# Compress and encrypt
printf 'something plain' | gzip | base64

# Decrypt compressed strings
echo H4sIAPQWZmYAAyvOz00tycjMS1coyEnMzAMA2StAzA8AAAA= | base64 -d | gunzip


# Strings spanning multiple lines
openssl enc -base64 <<< 'Should the data be a tad longer, the base64 encoded result will span multiple lines.'
openssl enc -base64 -dA << EOF
U2hvdWxkIHRoZSBkYXRhIGJlIGEgdGFkIGxvbmdlciwgdGhlIGJhc2U2NCBlbmNv
ZGVkIHJlc3VsdCB3aWxsIHNwYW4gbXVsdGlwbGUgbGluZXMuCg==
EOF
