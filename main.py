#!/usr/bin/env python
import os
from flask import Flask

app = Flask(__name__)


@app.route('/hi')
def hello():
    return {'message': "Hello World!"}


if __name__ == '__main__':
    fp = os.path.join(os.environ['HOME'], 'Desktop', 'hello.txt')
    if not os.path.exists(os.path.dirname(fp)):
        os.makedirs(fp)
    with open(fp, 'w') as f:
        f.write('Nihao!')

    app.run(port=8080)
