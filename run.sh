#!/bin/bash

whoami > "$HOME"/run.log

pip install --user --upgrade pipenv
start_dir=$(cd . && pwd)
cd $start_dir
pipenv install && pipenv run python main2.py
