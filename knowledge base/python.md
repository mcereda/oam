# Python

## String formatting

```python
# f-strings
f"Hello, {name}. You are {age}."
F"{name.lower()} is funny."
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

## Maintenance

```sh
# generate a list of all outdated packages
pip list --outdated

# upgrade all packages (oneliner)
pip install --requirement <(pip freeze | sed 's/==/>=/') --upgrade

# remove orphaned dependencies
# after installation of pip-autoremove
pip-autoremove

# upgrade onboard pip on mac os x
pip3 install --user --upgrade pip
echo 'export PATH="${HOME}/Library/Python/3.8/bin:${PATH}"' >> ${HOME}/.zprofile
```

## Further readings

- [flask at first run: do not use the development server in a production environment]
- [f-strings]
- [data types]
- [flask example with POST]
- [multi-value query parameters with flask]
- [How To Update All Python Packages]
- [invl/pip-autoremove]

[data types]: https://www.w3schools.com/python/python_datatypes.asp
[f-strings]: https://realpython.com/python-f-strings/
[flask at first run: do not use the development server in a production environment]: https://stackoverflow.com/questions/51025893/flask-at-first-run-do-not-use-the-development-server-in-a-production-environmen#54381386
[flask example with POST]: https://stackoverflow.com/questions/22947905/flask-example-with-post#53725861
[how to update all python packages]: https://www.activestate.com/resources/quick-reads/how-to-update-all-python-packages/
[multi-value query parameters with flask]: https://dev.to/svencowart/multi-value-query-parameters-with-flask-3a92
[invl/pip-autoremove]: https://github.com/invl/pip-autoremove
