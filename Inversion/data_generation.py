from getConfig import gConfig
import os
import numpy as np
from PIL import Image
from matplotlib.path import Path
from sklearn.model_selection import train_test_split
from sklearn.preprocessing import MinMaxScaler
from scipy.io import loadmat


class data_preprocessing(object):

    def inputData_1d(self, dataPath, data_file):
        train_data = loadmat(os.path.join(dataPath, data_file))["data_output"]
        feature_range = (0, 1)
        scaler = MinMaxScaler(feature_range=feature_range)
        train_data = scaler.fit_transform(train_data)
        train_data = train_data.reshape((train_data.shape[0], train_data.shape[1], 1))
        return train_data

    def label_1d(self, labelPath, label_file):
        # load y_train (casingCon_vector)
        # only train_target need log transform (train_data: log10 data)
        train_target = np.load(os.path.join(labelPath, label_file))
        train_target = train_target / np.max(train_target)
        # feature_range = (0, 1)
        # scaler = MinMaxScaler(feature_range=feature_range)
        # train_target = scaler.fit_transform(train_target)

        # set useless data after MinMaxScaler as 1.0 (max)
        # index = np.where(train_target.max(axis=0) - train_target.min(axis=0) == 0)[0]
        # for id in index:
        #     train_target[:, int(id)] = feature_range[1]

        return train_target

    def inputData_2d(self, dataPath, data_file,
                     num_samples, im_dim, num_channels,
                     data_form='raw', subtract_pixel_mean=True):
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

        if data_form == 'raw':
            amp_data = loadmat(os.path.join(dataPath, data_file))["data_log_amp_orig"]
            ang_data = loadmat(os.path.join(dataPath, data_file))["data_log_ang_orig"]
            train_data = np.zeros([num_samples, im_dim, im_dim, num_channels])
            train_data[:, :, :, 0] = amp_data
            train_data[:, :, :, 1] = ang_data

        if data_form == 'HSV+amp':
            amp_data = loadmat(os.path.join(dataPath, data_file))["data_log_amp"]
            ang_data = loadmat(os.path.join(dataPath, data_file))["data_log_ang"]
            train_data = np.zeros([num_samples, im_dim, im_dim, num_channels])
            images = np.zeros([num_samples, im_dim, im_dim, 3])
            for i, img_name in enumerate(os.listdir(imagePath)):
                image_path = os.path.join(imagePath, img_name)
                img = Image.open(image_path)
                img_data = np.asarray(img, np.uint8)
                images[i, :, :, :] = img_data
            train_data[:, :, :, :3] = images.astype(np.float32) / 255.
            # If subtract pixel mean is enabled
            if subtract_pixel_mean:
                train_data_mean = np.mean(train_data, axis=0)
                train_data -= train_data_mean
            train_data[:, :, :, 4] = amp_data

        return train_data

    def label_2d(self, labelPath, label_file, num_samples,
                 label_dim, num_channels):
        shape_data = loadmat(os.path.join(labelPath, label_file))["ShapeCollect"]
        data_FracturingShape = np.zeros([num_samples, label_dim, label_dim, num_channels])

        # verts.shape = (9, num_samples * 2)
        verts = np.append(shape_data, shape_data[0].reshape(1, shape_data.shape[1]), axis=0)
        dim1, dim2 = label_dim, label_dim
        # Create vertex coordinates for each grid cell...
        # (<0,0> is at the top left of the grid in this system)
        x, y = np.meshgrid(np.linspace(-200, 200, num=dim1), np.linspace(-1700, -2100, num=dim2))
        x, y = x.flatten(), y.flatten()

        points = np.vstack((x, y)).T

        for i in range(num_samples):
            poly_verts = verts[:, 2 * i:2 * (i + 1)]
            path = Path(poly_verts)
            grid = path.contains_points(points)
            grid = grid.reshape((dim2, dim1))
            data_FracturingShape[i, :, :, 0] = grid.astype(np.float32)
        train_target = data_FracturingShape
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
