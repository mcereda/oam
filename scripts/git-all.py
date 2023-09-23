#!/usr/bin/env python3

# Easy, quick & dirty solution to act upon multiple git repositories at once.

# TODO:
#   - use 'gitpython' instead of calling `git`?

import click
import logging
import subprocess

from concurrent.futures import ThreadPoolExecutor
from os import cpu_count, getcwd, walk
from os.path import basename, dirname

logging.basicConfig(level=logging.WARNING)

def call_git(directory, dry_run = False, *args):
    logging.debug(f"received {locals()}")

    command = [
        "git",
        "-C",
        directory
    ]
    command.extend(args)
    logging.debug(f"executing '{' '.join(command)}'")

    if dry_run is False:
        subprocess.call(command)

@click.command()
@click.option('--debug', '-d', is_flag=True, default=False, help='Enable debug mode.')
@click.option('--dry-run', '-n', is_flag=True, default=False, help='Simulate actions.')
@click.option('--threads', '-t', default=cpu_count(), help='Number of threads to use.', show_default=True)
@click.argument('command')
@click.argument('root_directories', type=click.Path(exists=True, file_okay=False, resolve_path=True), nargs=-1)
def main(command, debug, dry_run, root_directories, threads):
    """
    Executes the COMMAND on all repositories found in the ROOT_DIRECTORIES.

    COMMAND           The git command to execute. Quoted if given with arguments.
    ROOT_DIRECTORIES  The directories to walk while looking for repositories.
    """

    command_parts = tuple(command.split(" "))
    if len(root_directories) <= 0:
        root_directories = (getcwd(),)

    if debug:
        logging.basicConfig(level=logging.DEBUG, force=True)
        logging.warning("debug mode enabled")
    if dry_run:
        logging.warning("dry-run mode enabled")

    logging.debug(f"using globals {globals()}")
    logging.debug(f"using locals {locals()}")

    repositories = []
    for directory in root_directories:
        logging.debug(f"starting from '{directory}'")

        repositories_in_dir = set(dirname(dirpath) for dirpath, _, _ in walk(directory) if basename(dirpath) == '.git')
        logging.debug(f"{directory} has repositories {', '.join(repositories_in_dir)}")

        repositories.extend(repositories_in_dir)
    repositories = set(repositories)
    logging.debug(f"found repositories {', '.join(repositories)}")

    logging.debug(f"creating threads")
    with ThreadPoolExecutor(max_workers=threads) as executor:
        for repository in repositories:
            logging.debug(f"submitting thread for {repository}")
            executor.submit(call_git, repository, dry_run, *command_parts)

if __name__ == "__main__":
    main()
