# Python

## Table of contents <!-- omit in toc -->

1. [TL;DR](#tldr)
1. [Dictionaries](#dictionaries)
1. [F-strings](#f-strings)
1. [Logging](#logging)
1. [CLI helpers](#cli-helpers)
1. [Web servers](#web-servers)
   1. [Flask](#flask)
   1. [WSGI server](#wsgi-server)
1. [Execute commands on the host](#execute-commands-on-the-host)
1. [Concurrent execution](#concurrent-execution)
1. [Further readings](#further-readings)
1. [Sources](#sources)

## TL;DR

```py
# Declare tuples.
# If only 1 element, it requires the ending ','.
(1, 'string')
('element',)

# Declare dictionaries.
{'spam': 2, 'ham': 1, 'eggs': 3}
dict(spam=2,ham=1,eggs=3)
dict([('spam',2),('ham',1),('eggs',3)])

# String formatting with f-strings.
f"Hello, {name}. You are {age}."
F"{name.lower()} is funny."

# Make elements in a list unique.
# Keep the resulting list mutable.
# Sorts the elements (it is a set "feature").
unique_elements = list(set(redundant_elements))
```

## Dictionaries

```py
# Declare dictionaries.
d = {'spam': 2, 'ham': 1, 'eggs': 3}
d = dict(spam=2,ham=1,eggs=3)
d = dict([('spam',2),('ham',1),('eggs',3)])
d = {x: x for x in range(5)}
d = {c.lower(): c + '!' for c in ['SPAM','EGGS','HAM']}
d = dict.fromkeys('abc',0)

# Change elements.
d['ham'] = ['grill', 'bake', 'fry']

# Add new elements.
d['brunch'] = 'bacon'

# Delete elements.
del d['eggs']
d.pop('eggs')

# List values and/or keys.
d.values()
d.keys()
d.items()

# Print the elements and their values.
for k,v in d.items(): print(k,v)

# Merge dictionaries.
d1 = {'spam': 2, 'ham': 1, 'eggs': 3}
d2 = {'toast': 4, 'muffin': 5, 'eggs': 7}
d1.update(d2)

# Copy dictionaries.
d1 = {'spam': 2, 'ham': 1, 'eggs': 3}
d2 = d1.copy()
```

## F-strings

```py
f"Hello, {name}. You are {age}."
F"{name.lower()} is funny."
```

## Logging

Very basic logger:

```py
import logging
logging.basicConfig(level=logging.WARNING)

logging.critical("CRITICAL level message")
logging.exception("ERROR level message")
logging.error("ERROR level message")
logging.warning("WARNING level message")
logging.info("INFO level message")
logging.debug("DEBUG level message")
logging.log(level, "{level} level message")
```

See [logging howto] and [logging library] for more information.

## CLI helpers

See [click]:

```py
import click

@click.command()
@click.option('--count', default=1, help='Number of greetings.')
@click.option('--name', prompt='Your name',
              help='The person to greet.')
def hello(count, name):
    """Simple program that greets NAME for a total of COUNT times."""
    for x in range(count):
        click.echo(f"Hello {name}!")

if __name__ == '__main__':
    hello()
```

## Web servers

### Flask

- `request.args` gets query arguments
- `request.form` gets POST arguments

```py
from flask import request, jsonify

@app.route('/get/questions/', methods=['GET', 'POST','DELETE', 'PATCH'])
def question():
    if request.method == 'GET':
        start = request.args.get('start', default=0, type=int)
        limit_url = request.args.get('limit', default=20, type=int)
        data = [doc for doc in questions]
        return jsonify(
            isError = False,
            message = "Success",
            statusCode = 200,
            data= data
        ), 200
    if request.method == 'POST':
        question = request.form.get('question')
        topics = request.form.get('topics')
        return jsonify(
            isError = True,
            message = "Conflict",
            statusCode = 409,
            data = data
        ), 409
```

### WSGI server

You can use `waitress`:

```py
from flask import Flask

app = Flask(__name__)

@app.route("/")
def index():
    return "<h1>Hello!</h1>"

if __name__ == "__main__":
    from waitress import serve
    serve(app, host="0.0.0.0", port=8080)
```

```sh
pip install flask waitress
python hello.py
```

## Execute commands on the host

Very basic execution:

```py
import subprocess
subprocess.call(command)
```

See [subprocess library] for more information.

## Concurrent execution

Very basic multi-threaded operations:

```py
from concurrent.futures import ThreadPoolExecutor
from os import cpu_count

with ThreadPoolExecutor(max_workers=cpu_count()) as executor:
    for element in elements:
        logging.debug(f"submitting thread for {element}")
        executor.submit(function_name, function_arg_1, function_arg_n)
```

See [concurrent execution] for more information.

## Further readings

- [Dictionaries]
- [PIP]
- [`pipx`][pipx]
- [How To Update All Python Packages]
- [invl/pip-autoremove]
- [Data types]
- [F-strings]
- [How to filter list elements in Python]
- [Logging howto]
- [Flask at first run: do not use the development server in a production environment]
- [Flask example with POST]
- [Multi-value query parameters with Flask]
- [*args and **kwargs in Python]
- [An intro to threading in Python]
- [ThreadPoolExecutor in Python: the complete guide]
- [Concurrent execution]

## Sources

All the references in the [further readings] section, plus the following:

- [10 python one-liners for dictionaries]
- [Logging library]
- [Subprocess library]
- [Click]

<!--
  References
  -->

<!-- Upstream -->
[concurrent execution]: https://docs.python.org/3/library/concurrency.html
[dictionaries]: https://docs.python.org/3/tutorial/datastructures.html#dictionaries
[logging howto]: https://docs.python.org/3/howto/logging.html
[logging library]: https://docs.python.org/3/library/logging.html
[subprocess library]: https://docs.python.org/3/library/subprocess.html

<!-- In-article sections -->
[further readings]: #further-readings

<!-- Knowledge base -->
[pip]: pip.md
[pipx]: pipx.md

<!-- Others -->
[*args and **kwargs in python]: https://www.geeksforgeeks.org/args-kwargs-python/
[10 Python One-Liners for Dictionaries]: https://medium.com/codex/10-python-one-liners-for-dictionaries-d58754386a1d
[an intro to threading in python]: https://realpython.com/intro-to-python-threading/
[click]: https://click.palletsprojects.com/en/
[data types]: https://www.w3schools.com/python/python_datatypes.asp
[f-strings]: https://realpython.com/python-f-strings/
[flask at first run: do not use the development server in a production environment]: https://stackoverflow.com/questions/51025893/flask-at-first-run-do-not-use-the-development-server-in-a-production-environmen#54381386
[flask example with POST]: https://stackoverflow.com/questions/22947905/flask-example-with-post#53725861
[how to filter list elements in python]: https://www.pythontutorial.net/python-basics/python-filter-list/
[how to update all python packages]: https://www.activestate.com/resources/quick-reads/how-to-update-all-python-packages/
[invl/pip-autoremove]: https://github.com/invl/pip-autoremove
[multi-value query parameters with flask]: https://dev.to/svencowart/multi-value-query-parameters-with-flask-3a92
[threadpoolexecutor in python: the complete guide]: https://superfastpython.com/threadpoolexecutor-in-python/
