import getConfig
import os
import numpy as np
from PIL import Image
from sklearn.model_selection import train_test_split
from sklearn.preprocessing import MinMaxScaler
from scipy.io import loadmat

gConfig = {}
gConfig = getConfig.get_config(config_file='config.ini')


class data_preprocessing(object):
    def read_data_2d(self, dataPath, labelPath,
                     num_images, im_dim, num_channels,
                     subtract_pixel_mean=True):
        # load X_train (images)
        images = np.zeros([num_images, im_dim, im_dim, num_channels])
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

        # # load y_train (casingCon_vector/array)
        train_target = np.load(os.path.join(labelPath, 'train_target.npy'))
        scaler = MinMaxScaler()
        train_target = scaler.fit_transform(train_target)
        return train_data, train_target

    def read_data_1d(self, dataPath, data_file, labelPath):
        train_data = loadmat(os.path.join(dataPath, data_file))["data_output"]
        scaler = MinMaxScaler()
        # # load y_train (casingCon_vector/array)
        train_target = np.load(os.path.join(labelPath, 'train_target.npy'))
        train_data = scaler.fit_transform(train_data)
        train_target = scaler.fit_transform(train_target)
        return train_data, train_target

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
