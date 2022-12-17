#!/usr/bin/env python3

# /usr/bin/env python3 -m pip install --user gitpython

import logging
import subprocess

from concurrent.futures import ThreadPoolExecutor
from os import cpu_count, getcwd, walk
from os.path import basename, dirname, isdir
from sys import argv

log_level = logging.DEBUG
root_directory = getcwd()
threads_count = cpu_count()

def git_command(directory, *args):
    logging.debug(f"thread for {directory}")
    logging.debug(f"using args {args}")

    command = [
        "git",
        "-C",
        directory
    ]
    command.extend(args)
    logging.debug(command)

    subprocess.call(command)

if __name__ == "__main__":
    if argv[1] == "--debug":
        logging.basicConfig(level=log_level)
        argv.remove("--debug")

    logging.debug(f"using globals {globals()}")
    logging.debug(f"using locals {locals()}")

    logging.debug(f"using cli args {argv[1:]}")

    if isdir(argv[-1]):
        root_directory = argv[-1]
        git_args = argv[1:-1]
    else: git_args = argv[1:]
    logging.debug(f"starting from {root_directory}")
    logging.debug(f"using git args {git_args}")

    repositories = set([dirname(dirpath) for dirpath, _, _ in walk(root_directory) if basename(dirpath) == ".git"])
    logging.debug(f"found repositories {repositories}")

    logging.debug(f"creating threads")
    with ThreadPoolExecutor(max_workers=threads_count) as executor:
        for repository in repositories:
            executor.submit(git_command, repository, *git_args)
