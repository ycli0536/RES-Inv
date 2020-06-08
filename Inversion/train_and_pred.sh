#!/bin/env bash

# Name: train_and_pred.sh
# Desc: excute inversion
# Path: /code/fracturing_inv_tf2.1/train_and_pred.sh
# Usage: 
# Update: 2020-06-08 Yinchu Li

set -e

eval "$(conda shell.bash hook)"
conda activate tf2.1
python excute.py config.ini train
python excute.py config.ini predict
echo "任务1/1已于$(date +'%F %T')完成"
echo "task 1/1 has been done at $(date +'%F %T')"
