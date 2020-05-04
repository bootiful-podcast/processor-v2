#!/usr/bin/env python
import os

if __name__ == '__main__':
    fp = os.path.join(os.environ['HOME'], 'Desktop', 'hello.txt')
    if not os.path.exists(os.path.dirname(fp)):
        os.makedirs(fp)
    with open(fp, 'w') as f:
        f.write('Nihao!')
