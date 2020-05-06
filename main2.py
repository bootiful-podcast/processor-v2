import os

from flask import Flask

app = Flask(__name__)


@app.route("/")
def greet():
    return {"greeting": "Hello World!"}


if __name__ == "__main__":
    # home = os.environ["HOME"]
    # path = os.path.join(home, "env")
    # contents = []
    # for k, v in os.environ.items():
    #     contents.append('%s=%s' % (k, v))
    # with open(path, 'w') as fp:
    #     fp.write(os.linesep.join(contents))
    app.run(host="0.0.0.0", port=8080)
