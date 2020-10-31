#!/usr/bin/env python

import os
import sys

if __name__ == "__main__":
    ## AWS
    # this should be equal to $HOME/.aws, but just in case it needs to change
    assert len(sys.argv) > 0, "you must specify a directory!"
    aws_dir = sys.argv[1]

    if not os.path.exists(aws_dir):
        os.makedirs(aws_dir)

    ## CREDENTIALS
    aws_region = os.environ["AWS_REGION"]
    aws_access_key_id = os.environ["AWS_ACCESS_KEY_ID"]
    aws_secret_access_key = os.environ["AWS_SECRET_ACCESS_KEY"]
    tpl = """
[default]
aws_access_key_id = %s
aws_secret_access_key = %s
    """.strip()

    with open(os.path.join(aws_dir, "credentials"), "w") as fp:
        fp.write(tpl % (aws_access_key_id, aws_secret_access_key))

    ## CONFIG
    tpl = (
        """
[default]
region = %s
    """.strip()
        % aws_region
    )
    with open(os.path.join(aws_dir, "config"), "w") as fp:
        fp.write(tpl)
