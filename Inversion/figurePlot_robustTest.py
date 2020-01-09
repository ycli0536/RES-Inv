# -*- coding: utf-8 -*-
"""
Created on Fri Oct 11 12:36:46 2019

@author: Yinchu Li
"""
#%%
from scipy.io import loadmat
import numpy as np 
import matplotlib.pyplot as plt
from matplotlib.path import Path
from PIL import Image

import time
import os
import re

def listdir(path, match_item='coe', filetype='mat'):
    target_files = []
    files = os.listdir(path)
    pattern = re.compile(r'' + match_item + '', re.I)
    for file_name in files:
        if os.path.splitext(file_name)[1] == '.' + filetype:
            match = pattern.search(file_name)
            if match:
                target_files.append(file_name)
    return target_files


home_path = "E:/ML_test20191026/TestData"
# home_path = "F:/Geophysics/fwd_robust/robust_test"
data_type = "changedCaseCon0.5"
earthConNoise = False

image_file = '51X51_ObsData_test_'
data_path = os.path.join(home_path, data_type)
if not os.path.isdir(data_path):
    os.makedirs(data_path)

test_target_mat_files = listdir(data_path, match_item='Plot')
test_target_save_path = os.path.join(data_path, "detailed_shape")
well_logging_save_path = os.path.join(data_path, "well_logging")
if not os.path.isdir(well_logging_save_path):
    os.makedirs(well_logging_save_path)
if not os.path.isdir(test_target_save_path):
    os.makedirs(test_target_save_path)

target_file_name = test_target_mat_files[0]
target_path = os.path.join(data_path, target_file_name)
Plot_info = loadmat(target_path)

shapeLoc = Plot_info['ShapeCollect']
earthCon_list = Plot_info['earthCon_list']
earthCon_ref = Plot_info['earthCon_ref']
interfaces = Plot_info['interface']
fracCon_list = Plot_info['fracCon_list']
fracCon_ref = 250

num_target = earthCon_list.shape[1]

#%% load test_data and test_target

# load image_data
image_path = os.path.join(data_path, image_file + data_type)

images = np.zeros([num_target, 51, 51, 3])

for i, img_name in enumerate(os.listdir(image_path)):
    test_data_path = os.path.join(image_path, img_name)
    img = Image.open(test_data_path)
    img_data = np.asarray(img, np.uint8)
    images[i, :, :, :] = img_data

test_data = images.astype(np.float32) / 255.

subtract_pixel_mean = True
# If subtract pixel mean is enabled
if subtract_pixel_mean:
    test_data_mean = np.mean(test_data, axis=0)
    test_data -= test_data_mean

# test_target (label)

width = 80
height = 80
data_FracCon = np.zeros([num_target, width, height, 1])

xb, yb = np.meshgrid(np.linspace(-200, 200, width, endpoint=True), np.linspace(-2100, -1700, height, endpoint=True))
coors = np.hstack((xb.reshape(-1, 1), yb.reshape(-1, 1)))
for i in range(num_target):
    x = shapeLoc[:, 2*i]
    y = shapeLoc[:, 2*i + 1]
    polygon = np.hstack((x.reshape(-1, 1), y.reshape(-1, 1)))
    poly_path = Path(polygon)
    mask = poly_path.contains_points(coors)
    data_FracCon[i, :, :, 0] = np.flipud(mask.reshape(xb.shape[0], xb.shape[1])) * fracCon_list[0][i]

# max_fracCon = np.max(fracCon_list)
test_target = data_FracCon.astype(np.float32) / fracCon_ref

# %% save data for model-test
np.save(data_path +   '\\test_data_' + data_type, test_data)
np.save(data_path + '\\test_target_' + data_type, test_target)

# %% save figures
# plot and save test_target (png)
start1 = time.time()
for id in range(num_target):
    plt.imshow(test_target[id, :, :, 0])
    plt.xticks([])
    plt.yticks([])
    fig = 'shape_' + '%04d' %(id + 1) + '.png'
    plt.clim(0., np.max(test_target))
    plt.savefig(os.path.join(test_target_save_path, fig),
                bbox_inches = 'tight', pad_inches = 0, facecolor="w")
    plt.close()
end1 = time.time()
print('time cost for generating fracturing figures: ', end1 - start1)

# plot and save well-logging profile (png)
depth = np.linspace(0, -2160, 500, endpoint=True)
resistivity_ref = np.linspace(0, -2160, 500, endpoint=True)
resistivity = np.linspace(0, -2160, 500, endpoint=True)
# Reference earth conductivity
for i in range(len(earthCon_ref)):
    resistivity_ref[depth <= interfaces[i][0]] = 1./ earthCon_ref[i][0]

if earthConNoise:
    start2 = time.time()
    # Reference earth conductivity
    for i in range(num_target):
        for j in range(len(earthCon_ref)):
            resistivity[depth <= interfaces[j][0]] = 1./ earthCon_list[j][i]
        plt.figure(figsize=(4, 6))
        plt.plot(resistivity_ref, depth)
        plt.plot(resistivity, depth)
        plt.xlim((0, 600))
        plt.ylim((-2160, 0))
        fig = 'well-logging profile_' + '%04d' %(i + 1) + '.png'
        plt.savefig(os.path.join(well_logging_save_path, fig), facecolor="w")
        plt.close()
    end2 = time.time()
    print('time cost for generating well-logging figures: ', end2 - start1)
else:
    plt.figure(figsize=(4, 6))
    plt.plot(resistivity_ref, depth)
    plt.xlim((0, 600))
    plt.ylim((-2160, 0))
    fig = 'well-logging profile.png'
    plt.savefig(os.path.join(well_logging_save_path, fig), facecolor='w')
    plt.close()


#%%
