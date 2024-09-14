#!/usr/bin/env make

bootstrap:
	@npm install
	@${MAKE} staticsite-build


staticsite-build:
	@npm run build

local-serve: staticsite-build
	@npm run serve


composition-go-brrr: staticsite-build
	@docker compose up -d

composition-stop:
	@docker compose down

composition-refresh: composition-stop composition-go-brrr
