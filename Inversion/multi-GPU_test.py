import tensorflow as tf 
from keras.applications import Xception
from keras.utils import multi_gpu_model
import numpy as np 

num_samples = 1000
height = 224
width = 224
num_classes = 1000

with tf.device("/cpu:0"):
    model = Xception(weights=None,
                     input_shape=(height, width, 3),
                     classes=num_classes)

