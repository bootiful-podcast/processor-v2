# README


You can run the program by calling `main.py` using Python 3.8 or later.

You can run the Docker image assuming you've got a valid RabbitMQ instance running on your host machine. 

You could also use this script to have Kubernetes [port-forward the remote, in-cluster, instance on to your local machine](https://github.com/bootiful-podcast/deployment/blob/main/proxy_bp_rabbitmq.sh).

```shell 


docker run \
 -e PODCAST_RMQ_ADDRESS=amqp://bp-rmq:bp-rmq@host.docker.internal/ \
 -e AWS_REGION=us-east-1 \
 -e AWS_ACCESS_KEY_ID="${AWS_ACCESS_KEY_ID}" \
 -e AWS_SECRET_ACCESS_KEY="${AWS_SECRET_ACCESS_KEY}" \
 audio-processor


```

