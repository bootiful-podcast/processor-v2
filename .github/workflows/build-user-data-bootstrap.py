# !/usr/bin/env python3

import sys
import urllib.request
import os

if __name__ == '__main__':
    url_for_bootstrap_sh = sys.argv[1]
    rmq_address = sys.argv[2]
    fragment = 'PODCAST_RMQ_ADDRESS=_PODCAST_RMQ_ADDRESS_'
    contents = str(urllib.request.urlopen(url_for_bootstrap_sh).read())
    a, b = contents.split(fragment)
    lines = [a, 'PODCAST_RMQ_ADDRESS=%s' % rmq_address, b]
    print(os.linesep.join(lines))
