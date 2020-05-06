import os

from flask import Flask

app = Flask(__name__)


@app.route("/")
def hello():
    return "Hello World!"


if __name__ == "__main__":
    app.run(host='0.0.0.0', port=8080)

    print('hello, world!')
    home = os.environ['HOME']
    path = os.path.join(home, 'hello.txt')
    with open(path, 'w') as fp:
        fp.write('hello, world!')
