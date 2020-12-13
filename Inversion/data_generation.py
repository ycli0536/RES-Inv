# -*- coding: utf-8 -*-
"""
Created on Feb 2020
@author: Yinchu Li (11849188@mail.sustech.edu.cn)
"""

################################################
########        DATA  GENERATION        ########
################################################


from getConfig import gConfig
import os
import numpy as np
from PIL import Image
from matplotlib.path import Path
from sklearn.model_selection import train_test_split
from scipy.io import loadmat


class data_preprocessing(object):

    def inputData_1d(self, dataPath, data_file, num_samples, vec_dim, num_channels=1):
        train_data = np.zeros([num_samples, vec_dim, num_channels])
        loaded_data = loadmat(os.path.join(dataPath, data_file))["data_output"]
        train_data[:, :, 0] = loaded_data
        return train_data

    def label_1d(self, labelPath, label_file, num_samples, label_dim, num_channels=1):
        # load y_train (casingCon_vector)
        train_target = np.zeros([num_samples, label_dim, num_channels])
        curve_data = loadmat(os.path.join(labelPath, label_file))["casingCon_discrete"]
        # log
        data_CasingCurve = np.log10(curve_data[1:, :])
        # scale to [0, 1]
        data_CasingCurve /= np.max(data_CasingCurve)
        train_target[:, :, 0] = data_CasingCurve
        return train_target

    def inputData_2d(self, dataPath, data_file,
                     num_samples, im_dim, num_channels,
                     data_form='log+scale', subtract_pixel_mean=True):
        # load X_train (images)
        if data_form == 'image':
            images = np.zeros([num_samples, im_dim, im_dim, num_channels])
            for i, img_name in enumerate(os.listdir(dataPath)):
                image_path = os.path.join(dataPath, img_name)
                img = Image.open(image_path)
                img_data = np.asarray(img, np.uint8)
                images[i, :, :, :] = img_data

            train_data = images.astype(np.float32) / 255.
            # If subtract pixel mean is enabled
            if subtract_pixel_mean:
                train_data_mean = np.mean(train_data, axis=0)
                train_data -= train_data_mean

        if data_form == 'log+scale': # log amplitudes, scaled angles
            train_data = np.zeros([num_samples, im_dim, im_dim, num_channels])
            amp_data = loadmat(os.path.join(dataPath, data_file))["data_log_amp"]
            ang_data = loadmat(os.path.join(dataPath, data_file))["data_scaled_ang"]
            train_data[:, :, :, 0] = amp_data
            train_data[:, :, :, 1] = ang_data

        return train_data

    def label_2d(self, labelPath, label_file, num_samples,
                 label_dim, num_channels):
        shape_data = loadmat(os.path.join(labelPath, label_file))["ShapeCollect"]
        fracLoc = loadmat(os.path.join(labelPath, label_file))["fracLoc"]
        train_target = np.zeros([num_samples, label_dim, label_dim, num_channels])

        # verts.shape = (9, num_samples * 2)
        verts = np.append(shape_data, shape_data[0].reshape(1, shape_data.shape[1]), axis=0)
        dim1, dim2 = label_dim, label_dim
        # Create vertex coordinates for each grid cell...
        # (<0,0> is at the top left of the grid in this system)
        x, y = np.meshgrid(np.linspace(fracLoc[0][2], fracLoc[0][3], num=dim1), np.linspace(fracLoc[0][4], fracLoc[0][5], num=dim2))
        x, y = x.flatten(), y.flatten()

        points = np.vstack((x, y)).T

        for i in range(num_samples):
            poly_verts = verts[:, 2 * (i + 1): 2 * ((i + 1) + 1)] # + 1 to skip first Shape data (none)
            path = Path(poly_verts)
            grid = path.contains_points(points)
            data_FracturingShape = grid.reshape((dim2, dim1))
            train_target[i, :, :, 0] = data_FracturingShape.astype(np.float32)
        return train_target

    def Split(self, train_data, train_target):
        X_train, X_vail, y_train, y_vail = train_test_split(train_data,
                                                            train_target,
                                                            test_size=gConfig['splitsize_train_others'],
                                                            random_state=gConfig['seed'])
        X_vail, X_test, y_vail, y_test = train_test_split(X_vail, y_vail,
                                                          test_size=gConfig['splitsize_vail_test'],
                                                          random_state=gConfig['seed'])

        input_shape = X_train.shape[1:]
        return input_shape, (X_train, y_train), (X_vail, y_vail), (X_test, y_test)
