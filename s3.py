# Todo
import os
import uuid

import boto3
import utils


#
# https://linuxacademy.com/guide/14209-automating-aws-with-python-and-boto3/
# why is the current region None?
#


# def create_bucket_name(bucket_prefix):
#     return "".join([bucket_prefix, str(uuid.uuid4())])


class S3Client(object):
    def __init__(self, s3=boto3.resource("s3")):
        self.s3 = s3

    def upload(self, bucket_name, key, fn):
        self.s3.meta.client.upload_file(fn, bucket_name, key)

    def download(self, bucket_name, key, local_fn):
        if os.path.exists(local_fn):
            return True
        self.s3.meta.client.download_file(bucket_name, key, local_fn)
        assert os.path.exists(local_fn), (
            "the local file %s should have been downloaded" % local_fn
        )
        return local_fn

    def create_bucket(self, bucket_name, region_name="us-east-1"):
        return (
            bucket_name,
            self.s3.meta.client.create_bucket(
                Bucket=bucket_name, LocationConstraint=region_name
            ),
        )

    @property
    def buckets(self):
        return self.s3.buckets.all()
