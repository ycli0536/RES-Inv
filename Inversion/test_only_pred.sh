#!/bin/env bash

# Name: test_only_pred.sh
# Desc: excute prediction or inversion after training
# Path: /code/fracturing_inv_tf2.1/test_only_pred.sh
# Usage: 
# Update: 2020-06-08 Yinchu Li

set -e

eval "$(conda shell.bash hook)"
conda activate tf2.1

# 第一次需要通过y_test生成X_test
python inputData_generation.py config_pred.ini predict

python excute.py config_pred.ini predict
echo "预测任务1/1已于$(date +'%F %T')完成"
echo "Prediction task 1/1 has been done at $(date +'%F %T')"
