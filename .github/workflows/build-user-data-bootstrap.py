# !/usr/bin/env python3

import sys
import urllib.request
import os

if __name__ == "__main__":
    # curl http://169.254.169.254/latest/user-data
    ## that'll show the current instances user-data to confirm everything's working

    if len(sys.argv) == 1:  # when run in dev
        github_sha = "master"
        rmq_address = "a test"
    else:
        github_sha = sys.argv[1]
        rmq_address = sys.argv[2]


    def replace_fragment(content, fragment, replacement):
        a, b = content.split(fragment)
        lines = [a, replacement, b]
        return os.linesep.join(lines)


    bootstrap_url = 'https://raw.githubusercontent.com/bootiful-podcast/python-test-to-deploy/%s/.github/workflows/bootstrap.sh' % github_sha
    contents = urllib.request.urlopen(bootstrap_url).read().decode("utf8")
    contents = replace_fragment(contents, "PODCAST_RMQ_ADDRESS=_PODCAST_RMQ_ADDRESS_",
                                'PODCAST_RMQ_ADDRESS="%s"' % rmq_address)
    contents = replace_fragment(contents, "GITHUB_SHA=_GITHUB_SHA_", 'GITHUB_SHA="%s"' % github_sha)
    print(contents)
    print('#' + bootstrap_url)
