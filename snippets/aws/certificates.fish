#!/usr/bin/env fish

# Get certificates
aws acm get-certificate --certificate-arn 'arn:aws:acm:eu-west-1:012345678901:certificate/abcdef01-2345-6789-abcd-ef0123456789'
