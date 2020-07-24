# Todo
import os
import uuid

import boto3
import utils

import typing


class S3Client(object):

    def __init__(self, s3=boto3.resource("s3")):
        self.s3 = s3

    def upload(self, bucket_name: str, key: str, fn: str):
        self.s3.meta.client.upload_file(fn, bucket_name, key)

    def download(self, bucket_name: str, key: str, local_fn: str):
        if os.path.exists(local_fn):
            return True
        self.s3.meta.client.download_file(bucket_name, key, local_fn)
        assert os.path.exists(local_fn), (
            "the local file %s should have been downloaded" % local_fn
        )
        return local_fn

    def create_bucket(
        self, bucket_name, region_name: str = "us-east-1"
    ) -> typing.Tuple[str, typing.Dict[str, str]]:
        create_bucket_config = {"LocationConstraint": region_name}
        return (
            bucket_name,
            self.s3.meta.client.create_bucket(
                Bucket=bucket_name, CreateBucketConfiguration=create_bucket_config
            ),
        )

    @property
    def buckets(self) -> typing.List:
        return self.s3.buckets.all()
