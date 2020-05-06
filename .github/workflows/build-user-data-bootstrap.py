# !/usr/bin/env python3

import sys
import urllib.request
import os

if __name__ == '__main__':
    if len(sys.argv) == 3: # when run in production
        url_for_bootstrap_sh = sys.argv[1]
        rmq_address = sys.argv[2]
    else:
        url_for_bootstrap_sh = 'https://raw.githubusercontent.com/bootiful-podcast/python-test-to-deploy/master/.github/workflows/bootstrap.sh'
        rmq_address = 'a test'

    fragment = 'PODCAST_RMQ_ADDRESS=_PODCAST_RMQ_ADDRESS_'
    contents = urllib.request.urlopen(url_for_bootstrap_sh).read().decode("utf8")
    a, b = contents.split(fragment)
    lines = [a, 'PODCAST_RMQ_ADDRESS="%s"' % rmq_address, b]
    print(os.linesep.join(lines))
