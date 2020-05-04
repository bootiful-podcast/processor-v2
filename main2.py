import datetime
import os

if __name__ == '__main__':
    print('hello, world!')
    home = os.environ['HOME']
    path = os.path.join(home, 'hello.txt')
    with open(path, 'w') as fp:
        fp.write('hello, world! (%s)' % datetime.datetime.isoformat())
