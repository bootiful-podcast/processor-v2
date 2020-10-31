#!/usr/bin/env python3

import tempfile
import boto3
import podcast
import rmq
import s3
import json
import threading
from common import *
from utils import *
from flask import Flask

def rmq_background_thread_runner():
    address_key = "PODCAST_RMQ_ADDRESS"
    assert address_key in os.environ, 'you must set the "%s" environment variable!' % address_key

    def resolve_config_file_name() -> str:
        bp_mode: str = os.environ.get("BP_MODE", "development")
        log('BP_MODE: %s' % bp_mode)
        return "config-%s.json" % bp_mode

    config_fn: str = resolve_config_file_name()
    config = load_config(config_fn)
    log("=" * 60)
    log("configuration file: %s " % config_fn)
    log("mode: %s " % config_fn)
    log(config)
    log("=" * 60)

    assets_s3_bucket = config["podcast-assets-s3-bucket"]
    assets_s3_bucket_folder = config["podcast-assets-s3-bucket-folder"]
    output_s3_bucket = config["podcast-output-s3-bucket"]
    # input_s3_bucket = config["podcast-input-s3-bucket"]
    requests_q = config["podcast-requests-queue"]
    replies_q = config["podcast-responses-exchange"]
    aws_region_env = os.environ.get("AWS_REGION")
    boto3.setup_default_session(region_name=aws_region_env)
    s3_client: s3.S3Client = s3.S3Client()

    def handle_job(request):
        log("NEW REQUEST:")
        log(request)
        intro_media = request["introduction-file"]
        interview_media = request["interview-file"]
        uid = request["uid"]
        normalized_uid_str = normalize_string(uid)
        tmpdir = os.path.join(tempfile.gettempdir(), normalized_uid_str)
        output_dir = os.path.join(tmpdir, "output")

        def build_full_s3_asset_path_for(fn: str):
            return "s3://%s/%s/%s" % (assets_s3_bucket, assets_s3_bucket_folder, fn)

        asset_closing = build_full_s3_asset_path_for("closing.mp3")
        asset_intro = build_full_s3_asset_path_for("intro.mp3")
        asset_music_segue = build_full_s3_asset_path_for("music-segue.mp3")

        downloaded_files = {}

        def download(s3p: str) -> str:
            log("going to download %s" % s3p)
            parts: typing.List[str] = s3p.split("/")
            bucket, folder, fn = parts[2:]
            local_fn: str = os.path.join(tmpdir, "downloads", bucket, folder, fn)
            the_directory: str = os.path.dirname(local_fn)
            if not os.path.exists(the_directory):
                os.makedirs(the_directory)
            assert os.path.exists(the_directory), (
                    "the directory, %s, should exist but does not" % the_directory
            )
            log("going to download %s to %s" % (s3p, local_fn))
            s3_client.download(bucket, os.path.join(folder, fn), local_fn)
            assert os.path.exists(local_fn), (
                    "the file should be downloaded to %s, but was not." % local_fn
            )
            return local_fn

        for s3_path in [
            asset_closing,
            asset_intro,
            asset_music_segue,
            intro_media,
            interview_media,
        ]:
            downloaded_files[s3_path] = download(s3_path)

        reset_and_recreate_directory(output_dir)
        results = podcast.create_podcast(
            downloaded_files[asset_intro],
            downloaded_files[asset_music_segue],
            downloaded_files[asset_closing],
            downloaded_files[intro_media],
            downloaded_files[interview_media],
            output_dir,
        )

        reply = {"uid": uid, "output-bucket-name": output_s3_bucket}

        for k in ["wav", "mp3"]:
            if k in results:
                upload_key = ".".join([uid, k])
                reply[k] = upload_key
                upload_local_fn = results[k][0]
                log("start: uploading %s to %s" % (upload_local_fn, upload_key))
                s3_client.upload(
                    output_s3_bucket, os.path.join(uid, upload_key), upload_local_fn
                )
                log("stop:  uploaded %s to %s" % (upload_local_fn, upload_key))

        log(reply)

        if os.path.exists(output_dir):
            log("cleaning up %s" % output_dir)
            reset_and_recreate_directory(output_dir)

        return reply

    rmq_uri = parse_uri(os.environ[address_key])

    while True:
        try:
            rmq.start_rabbitmq_processor(
                requests_q,
                replies_q,
                rmq_uri["host"],
                rmq_uri["username"],
                rmq_uri["password"],
                rmq_uri["path"],
                handle_job,
            )
        except Exception as ex:
            exception(
                ex,
                message="There was some sort of error installing a RabbitMQ listener. Restarting the processor... ",
            )


if __name__ == "__main__":

    def run_flask():
        app = Flask(__name__)

        @app.route("/")
        def hello():
            return json.dumps({'status': 'HODOR'})

        log('about to start the Flask service')
        app.run(port=8080)


    def run_rmq():

        retry_count = 0
        max_retries = 5
        while retry_count < max_retries:
            try:
                retry_count += 1
                log('launching RabbitMQ background thread')
                rmq_background_thread_runner()
            except Exception as e:
                exception(
                    e,
                    message="something went wrong trying to start the RabbitMQ processing thread!",
                )

        log("Exhausted retry count of %s times." % max_retries)


    for f in [run_flask, run_rmq]:
        threading.Thread(target=f).start()

    log('launched RabbitMQ and Flask threads.')
