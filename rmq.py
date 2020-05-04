#!/usr/bin/env python

import json

import pika

import utils


def start_rabbitmq_processor(
    requests_q: str,
    replies_q: str,
    rabbit_host: str,
    rabbit_username: str,
    rabbit_password: str,
    rabbit_vhost: str,
    process_job_requests_fn,
):
    utils.log(
        """Establishing a connection to RabbitMQ host '%s', having virtual host '%s', with username '%s'. """.strip()
        % (rabbit_host, rabbit_vhost, rabbit_username)
    )

    if rabbit_vhost is not None:
        rabbit_vhost = rabbit_vhost.strip()
        if rabbit_vhost == "/" or rabbit_vhost == "":
            rabbit_vhost = None

    if rabbit_vhost is None:
        params = pika.ConnectionParameters(
            host=rabbit_host,
            credentials=pika.PlainCredentials(rabbit_username, rabbit_password),
        )
    else:
        params = pika.ConnectionParameters(
            host=rabbit_host,
            virtual_host=rabbit_vhost,
            credentials=pika.PlainCredentials(rabbit_username, rabbit_password),
        )

    with pika.BlockingConnection(params) as connection:
        with connection.channel() as channel:
            for method_frame, properties, body in channel.consume(requests_q):
                utils.log("processing new request:")
                utils.log(body)
                object_request = json.loads(body)
                result = process_job_requests_fn(object_request)
                json_response = json.dumps(result)
                utils.log(
                    "sending json_response %s to replies queue %s with the following replies routing key %s "
                    % (json_response, replies_q, replies_q)
                )
                channel.basic_publish(
                    replies_q,
                    replies_q,
                    json_response,
                    pika.BasicProperties(content_type="text/plain", delivery_mode=1),
                )
                channel.basic_ack(method_frame.delivery_tag)
