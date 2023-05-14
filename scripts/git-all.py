#!/usr/bin/env python3

# Easy, quick & dirty solution to act upon multiple git repositories at once.

# TODO:
#   - proper commands
#   - use 'gitpython' instead of calling `git`

import logging
import subprocess

from concurrent.futures import ThreadPoolExecutor
from os import cpu_count, getcwd, walk
from os.path import basename, dirname, isdir
from sys import argv

dry_run = False
log_level = logging.WARNING
root_directory = getcwd()
threads_count = cpu_count()

logging.basicConfig(level=log_level)

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

    if dry_run is False:
        subprocess.call(command)

if __name__ == "__main__":
    if "--debug" in argv:
        logging.basicConfig(level=logging.DEBUG, force=True)
        logging.warning("debug mode")
        argv.remove("--debug")

    if "--dry-run" in argv:
        dry_run = True
        logging.warning("dry-run mode")
        argv.remove("--dry-run")

    logging.debug(f"using globals {globals()}")
    logging.debug(f"using locals {locals()}")

    logging.debug(f"using cli args {argv[1:]}")

    if isdir(argv[-1]):
        root_directory = argv[-1]
        git_args = argv[1:-1]
    else:
        git_args = argv[1:]

    logging.debug(f"starting from {root_directory}")
    logging.debug(f"using git args {git_args}")

    repositories = set([dirname(dirpath) for dirpath, _, _ in walk(root_directory) if basename(dirpath) == ".git"])
    logging.debug(f"found repositories {repositories}")

    logging.debug(f"creating threads")
    with ThreadPoolExecutor(max_workers=threads_count) as executor:
        for repository in repositories:
            logging.debug(f"submitting thread for {repository}")
            executor.submit(git_command, repository, *git_args)
