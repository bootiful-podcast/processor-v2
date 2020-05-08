# !/usr/bin/env python3

import sys
import urllib.request
import os

if __name__ == "__main__":
    # curl http://169.254.169.254/latest/user-data
    ## that'll show the current instances user-data to confirm everything's working

    def replace_fragment(content, fragment, replacement):
        a, b = content.split(fragment)
        lines = [a, replacement, b]
        return os.linesep.join(lines)

    github_sha = "master"
    rmq_address = "a test"
    bp_mode = 'development'
    if len(sys.argv) > 1:
        github_sha = sys.argv[1]
        rmq_address = sys.argv[2]
        bp_mode = sys.argv[3]

    bootstrap_url = (
            "https://raw.githubusercontent.com/bootiful-podcast/python-test-to-deploy/%s/.github/workflows/bootstrap.sh"
            % github_sha
    )

    envs = {'PODCAST_RMQ_ADDRESS': rmq_address, 'GITHUB_SHA': github_sha, 'BP_MODE': bp_mode}
    contents = urllib.request.urlopen(bootstrap_url).read().decode("utf8")
    for k, v in envs.items():
        contents = replace_fragment(contents, '%s=_%s_' % (k, k), '%s=%s' % (k, v))

    print(contents)
    print("#" + bootstrap_url)
