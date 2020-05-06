#!/bin/bash

whoami > "$HOME"/run.log

pip3 install --user --upgrade pipenv
start_dir=$(cd . && pwd)
cd $start_dir
pipenv install && pipenv run python3 main2.py
