# README


You can run the program by calling `main.py` using Python 3.7 or later.

You'll need several environment variables to get the application up and running correctly. 

* `AWS_REGION` : the region in which you want the application to run 
* `AWS_ACCESS_KEY_ID`: AWS access key ID
* `AWS_SECRET_ACCESS_KEY`: AWS access key secret

All of those values will be put in to the $HOME/.aws directory in the respective files so that all the AWS-client code in the application works correctly. See `config_aws.py` for the details. 

The python process itself lives in `main.py`. When it starts up it will need some configuration that tells it where to find the RabbitMQ queues and exchanges with which it should work. 

In order to get this to work I had to create a VPC. The VPC in turn required a subnet. I 

 