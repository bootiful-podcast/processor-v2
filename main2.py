import os

from flask import Flask

app = Flask(__name__)


@app.route("/")
def hello():
    return "Hello World!"


if __name__ == "__main__":
    app.run()

    print('hello, world!')
    home = os.environ['HOME']
    path = os.path.join(home, 'hello.txt')
    with open(path, 'w') as fp:
        fp.write('hello, world!')

