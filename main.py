#!/usr/bin/env python
import os
from flask import Flask

app = Flask(__name__)


@app.route('/hi')
def hello():
    return {'message': "Hello World!"}


if __name__ == '__main__':
    fp = os.path.join(os.environ['HOME'], 'Desktop', 'hello.txt')
    dir_for_fp = os.path.dirname(fp)
    if not os.path.exists(dir_for_fp):
        os.makedirs(dir_for_fp)
    with open(fp, 'w') as f:
        f.write('Nihao!')

    app.run(port=8080)
