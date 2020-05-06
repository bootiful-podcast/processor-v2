# !/usr/bin/env python

import os, sys
import urllib.request

if __name__ == '__main__':
    url_for_bootstrap_sh = sys.argv[1]
    rmq_address = sys.argv[2]
    fragment = '_PODCAST_RMQ_ADDRESS_'
    with urllib.request.urlopen(url_for_bootstrap_sh) as response:
        contents = response.read()
        a, b = contents.split(fragment)
        lines = [a, rmq_address, b]
        print(os.linesep.join(lines))
