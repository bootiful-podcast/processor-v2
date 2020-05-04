# Todo
import os
import uuid

import boto3


def create_bucket_name(bucket_prefix):
    return "".join([bucket_prefix, str(uuid.uuid4())])


def create_bucket(s3, bucket):
    s3_connection = s3.meta.client
    session = boto3.session.Session()
    current_region = session.region_name
    if current_region == "us-east-1":
        bucket_response = s3_connection.create_bucket(Bucket=bucket)
    else:
        bucket_response = s3_connection.create_bucket(
            Bucket=bucket, LocationConstraint=current_region
        )
    return bucket, bucket_response


def write_file(s3, bucket, key, local_fn):
    s3.meta.client.upload_file(local_fn, bucket, key)


def download_file(s3, bucket, key, local_fn):
    if os.path.exists(local_fn):
        return True

    s3.meta.client.download_file(bucket, key, local_fn)
    assert os.path.exists(local_fn), (
        "the local file %s should have been downloaded" % local_fn
    )


def list_buckets(s3):
    return s3.buckets.all()


class S3Client(object):
    def __init__(self, s3=boto3.resource("s3")):
        self.s3 = s3

    def upload(self, bucket_name, key, fn):
        write_file(self.s3, bucket_name, key, fn)

    def download(self, bucket_name, key, fn):
        download_file(self.s3, bucket_name, key, fn)
        return fn

    def create_bucket(self, bucket_name):
        return create_bucket(self.s3, bucket_name)

    @property
    def buckets(self):
        return list_buckets(self.s3)
