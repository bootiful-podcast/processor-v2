from unittest import TestCase

import utils
import s3
import os, sys, time, re


class TestParseUri(TestCase):
    def test_persist_with_sub_folders(self):
        if False:
            fn = os.path.abspath(os.path.join(__file__, os.path.pardir, "README.md"))
            assert os.path.exists(fn), f"the file {fn} does not exist!"
            s3_client = s3.S3Client()
            s3_client.upload("podcast-output-bucket", "123/test.jpg", fn)


if __name__ == "__main__":
    import unittest

    unittest.main()
