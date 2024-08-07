#!/usr/bin/env python3

##
# Easy, quick & dirty solution to act upon multiple git repositories at once.
#
# Implementation:
# - Wrap around the existing `git` command instead of using the 'gitpython' library to allow for aliases.
# - Use the 'click' libraries for CLI arguments for ease of use.
#
# Improvements:
# - Use multiprocessing instead of multithreading?
##

import click
import logging
import subprocess

from concurrent.futures import ThreadPoolExecutor
from os import cpu_count, getcwd, walk, EX_DATAERR
from os.path import basename, dirname

logging.basicConfig(level=logging.WARNING)

def call_git(directory, dry_run=False, *args):
    logging.debug(f"call_git: received {locals()}")

    git_command = [
        "git",
        "-C",
        directory
    ]
    git_command.extend(args)
    logging.debug(f"call_git: executing '{' '.join(git_command)}'")

    if dry_run is False:
        subprocess.run(git_command)

def pre_flight(git_subcommand):
    logging.info(f'running pre-flight checks')
    logging.debug(f'pre_flight: using {locals()}')

    result = subprocess.run(['git', '--list-cmds=main,alias'], stdout=subprocess.PIPE)
    git_available_subcommands = result.stdout.decode().splitlines()
    logging.debug(f'pre_flight: available git subcommands: {git_available_subcommands}')

    logging.debug(f'pre_flight: git subcommand to check: {git_subcommand}')
    try:
        assert git_subcommand in git_available_subcommands
    except AssertionError:
        logging.critical(f"'{git_subcommand}' is not a git subcommand in the main or alias groups")
        exit(EX_DATAERR)

@click.command()
@click.option('--debug', '-d', is_flag=True, default=False, help='Enable debug mode.')
@click.option('--dry-run', '-n', is_flag=True, default=False, help='Simulate actions.')
@click.option(
    '--recursive/--no-recursive', ' /--no-r',
    is_flag=True, default=True,
    help='Recurse from the given directories.', show_default=True
)
@click.option('--threads', '-t', default=cpu_count(), help='Number of threads to use.', show_default=True)
@click.option('--verbose', '-v', is_flag=True, default=False, help='Enable verbose mode.')
@click.argument('git_subcommand')
@click.argument(
    'directories', type=click.Path(exists=True, file_okay=False, resolve_path=True),
    nargs=-1, metavar='DIRECTORY...'
)

def main(debug, directories, dry_run, git_subcommand, recursive, threads, verbose):
    """
    Execute the given GIT_SUBCOMMAND in the given DIRECTORIES.
    With -r, execute it on all repositories found in the given DIRECTORIES.

    GIT_SUBCOMMAND  The git subcommand to execute, quoted if with arguments.
    DIRECTORY       The directories to walk while looking for repositories.
    """

    git_subcommand_parts = tuple(git_subcommand.split())
    if len(directories) <= 0:
        directories = (getcwd(),)

    if debug:
        logging.basicConfig(level=logging.DEBUG, force=True)
        logging.warning("debug mode enabled")
    if verbose:
        logging.basicConfig(level=logging.INFO, force=True)
        logging.warning("verbose mode enabled")
    if dry_run:
        logging.warning("dry-run mode enabled")

    logging.debug(f"using globals {globals()}")
    logging.debug(f"using locals {locals()}")

    pre_flight(git_subcommand=git_subcommand_parts[0])

    repositories = []
    if recursive:
        for directory in directories:
            logging.info(f"starting from '{directory}'")

            repositories_in_dir = set(
                dirname(dirpath) for dirpath, _, _ in walk(directory) if basename(dirpath) == '.git'
            )
            logging.debug(f"{directory} has repositories {', '.join(repositories_in_dir)}")

            repositories.extend(repositories_in_dir)
    else:
        # Just trust the user gave repositories in input
        repositories.extend(directories)
    repositories = set(repositories)
    logging.debug(f"repositories: {', '.join(repositories)}")

    logging.debug(f"creating threads")
    with ThreadPoolExecutor(max_workers=threads) as executor:
        for repository in repositories:
            logging.info(f"submitting thread for {repository}")
            executor.submit(call_git, repository, dry_run, *git_subcommand_parts)

if __name__ == "__main__":
    main()
