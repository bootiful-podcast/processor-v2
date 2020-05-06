#!/bin/bash

start_dir=$(cd "$(dirname $0)" && pwd)
cd $start_dir
pip3 install --user --upgrade pipenv
pipenv install && pipenv run python3 main2.py
