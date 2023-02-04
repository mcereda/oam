# Python

1. [TL,DR](#tldr)
2. [Web servers](#web-servers)
   1. [Flask](#flask)
   2. [WSGI server](#wsgi-server)
3. [Further readings](#further-readings)

## TL,DR

```py
# String formatting with f-strings.
f"Hello, {name}. You are {age}."
F"{name.lower()} is funny."

# Make elements in a list unique.
# Keep the resulting list mutable.
unique_list = list(set(redundant_list))
```

## Web servers

### Flask

- `request.args` gets query arguments
- `request.form` gets POST arguments

```python
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

```python
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

## Further readings

- [PIP]
- [How To Update All Python Packages]
- [invl/pip-autoremove]
- [Data types]
- [F-strings]
- [How to filter list elements in Python]
- [Logging]
- [Flask at first run: do not use the development server in a production environment]
- [Flask example with POST]
- [Multi-value query parameters with Flask]
- [*args and **kwargs in Python]
- [An intro to threading in Python]
- [ThreadPoolExecutor in Python: the complete guide]

<!-- internal references -->
[pip]: ./pip.md

<!-- external references -->
[*args and **kwargs in python]: https://www.geeksforgeeks.org/args-kwargs-python/
[an intro to threading in python]: https://realpython.com/intro-to-python-threading/
[data types]: https://www.w3schools.com/python/python_datatypes.asp
[f-strings]: https://realpython.com/python-f-strings/
[flask at first run: do not use the development server in a production environment]: https://stackoverflow.com/questions/51025893/flask-at-first-run-do-not-use-the-development-server-in-a-production-environmen#54381386
[flask example with POST]: https://stackoverflow.com/questions/22947905/flask-example-with-post#53725861
[how to update all python packages]: https://www.activestate.com/resources/quick-reads/how-to-update-all-python-packages/
[invl/pip-autoremove]: https://github.com/invl/pip-autoremove
[logging]: https://docs.python.org/3/howto/logging.html
[multi-value query parameters with flask]: https://dev.to/svencowart/multi-value-query-parameters-with-flask-3a92
[threadpoolexecutor in python: the complete guide]: https://superfastpython.com/threadpoolexecutor-in-python/
[how to filter list elements in python]: https://www.pythontutorial.net/python-basics/python-filter-list/
