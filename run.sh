#!/bin/bash

start_dir=$(cd . && pwd )
cd $start_dir
whoami > $HOME/run.log
pipenv install && pipenv run python main2.py
