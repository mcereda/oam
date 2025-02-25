#!/usr/bin/env make

include .env
-include .env.local

export

REPOSITORY_ROOT = ${shell git rev-parse --show-toplevel}

debug-env:
	@set | sort
