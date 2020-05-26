#!/bin/env bash

# Name: train_and_pred.sh
# Desc: excute inversion
# Path: /code/fracturing_inv_tf2.1/train_and_pred.sh
# Usage: 
# Update: 2020-05-26 Yinchu Li

set -e

eval "$(conda shell.bash hook)"
conda activate tf2.1
python excute.py config.ini
python excute.py config.ini
echo "任务1/1已于$(date +'%F %T')完成"
echo "task 1/1 has been done at $(date +'%F %T')"

