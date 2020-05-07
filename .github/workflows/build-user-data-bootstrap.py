# !/usr/bin/env python3

import sys
import urllib.request
import os

if __name__ == "__main__":
    if len(sys.argv) == 4:  # when run in production
        github_sha = sys.argv[1]
        rmq_address = sys.argv[2]
    else:
        github_sha = "master"
        rmq_address = "a test"


    def replace_fragment(content, fragment, replacement):
        a, b = content.split(fragment)
        lines = [a, replacement, b]
        return os.linesep.join(lines)


    bootstrap_url = 'https://raw.githubusercontent.com/bootiful-podcast/python-test-to-deploy/%s/.github/workflows/bootstrap.sh' % github_sha
    contents = urllib.request.urlopen(bootstrap_url).read().decode("utf8")
    contents = replace_fragment(contents, "PODCAST_RMQ_ADDRESS=_PODCAST_RMQ_ADDRESS_",
                                'PODCAST_RMQ_ADDRESS="%s"' % rmq_address)
    contents = replace_fragment(contents, "GITHUB_SHA=_GITHUB_SHA_", 'GITHUB_SHA="%s"' % rmq_address)
    print(contents)
