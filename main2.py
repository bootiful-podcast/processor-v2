import os

from flask import Flask

app = Flask(__name__)


@app.route("/")
def greet():
    return {"greeting": "Hello World!"}


if __name__ == "__main__":
    print("hello, world!")
    home = os.environ["HOME"]
    print("home is " + home)
    path = os.path.join(home, "proof")
    with open(path, "w") as fp:
        env = []
        for k, v in os.environ:
            env.append('%s=%s' % (k, v))
        fp.write(os.linesep.join(env))

    app.run(host="0.0.0.0", port=8080)
