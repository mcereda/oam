#!/usr/bin/env fish

jd -yaml -color 'values.yaml' (helm show values --repo 'https://dl.gitea.com/charts/' 'gitea' | psub)
