#!/usr/bin/env python
import sys

repository, sha = sys.argv[1:]
print('ResourceType=instance,Tags=[{Key=github_repository,Value=%s} , {Key=github_sha,Value=%s}]' % (repository, sha))
