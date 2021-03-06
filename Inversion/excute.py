# -*- coding: utf-8 -*-
"""
Created on Feb 2020
@author: Yinchu Li (11849188@mail.sustech.edu.cn)
"""

##############################################################
########        EXCUTE TRAINING AND PREDICTION        ########
##############################################################


import tensorflow as tf
import numpy as np
from model import fcnModel

from tensorflow.keras.models import load_model
from tensorflow.keras.callbacks import ModelCheckpoint, LearningRateScheduler, ReduceLROnPlateau, TensorBoard

from data_generation import data_preprocessing
from getConfig import gConfig, config_file, mode
from scipy.io import savemat
import configparser
import os
import time
import shutil
import json


def read_data(data_format, label_format):

    if data_format == '2d':
        train_data = generator.inputData_2d(dataPath=gConfig['datapath'],
                                            data_file=gConfig['data_file_name'],
                                            num_samples=gConfig['num_samples'],
                                            im_dim=gConfig['im_dim'],
                                            num_channels=gConfig['num_channels']
                                            )
    elif data_format == '1d':
        train_data = generator.inputData_1d(dataPath=gConfig['datapath'],
                                            data_file=gConfig['data_file_name'],
                                            num_samples=gConfig['num_samples'],
                                            vec_dim=gConfig['vec_dim']
                                            )
    else:
        print('--- Wrong input format! ---')

    if label_format == '2d':
        train_target = generator.label_2d(labelPath=gConfig['labelpath'],
                                          label_file=gConfig['label_file_name'],
                                          num_samples=gConfig['num_samples'],
                                          label_dim=gConfig['label_dim'],
                                          num_channels=gConfig['num_label_channels']
                                          )
    elif label_format == '1d':
        train_target = generator.label_1d(labelPath=gConfig['labelpath'],
                                          label_file=gConfig['label_file_name'],
                                          num_samples=gConfig['num_samples'],
                                          label_dim=gConfig['vec_dim']
                                          )
    else:
        print('--- Wrong label format! ---')
    return train_data, train_target


def save_trainingData_np(save_path, train_data, vail_data):

    X_train = train_data[0]
    y_train = train_data[1]
    X_vail = vail_data[0]
    y_vail = vail_data[1]

    np.save(os.path.join(save_path, 'X_vail'), X_vail)
    np.save(os.path.join(save_path, 'y_vail'), y_vail)
    np.save(os.path.join(save_path, 'X_train'), X_train)
    np.save(os.path.join(save_path, 'y_train'), y_train)
    print('All training data saved at: ', save_path)


class MyEncoder(json.JSONEncoder):
    def default(self, obj):
        if isinstance(obj, np.integer):
            return int(obj)
        elif isinstance(obj, np.floating):
            return float(obj)
        elif isinstance(obj, np.ndarray):
            return obj.tolist()
        else:
            return super(MyEncoder, self).default(obj)


def lr_schedule(epoch):
    lr = 1e-3
    if epoch >200:
        lr *= pow(5e-1, 5)
    elif epoch > 160:
        lr *= pow(5e-1, 4)
    elif epoch > 120:
        lr *= pow(5e-1, 3)
    elif epoch > 80:
        lr *= pow(5e-1, 2)
    elif epoch > 40:
        lr *= 5e-1
    return lr


def creat_model(input_shape):
    model = fcnModel(input_shape=input_shape)
    model = model.createModel(summary=True,
                              input_format=gConfig['input_format'],
                              label_format=gConfig['label_format']
                              )
    return model


def movefile(file, src_path, dst_path):
    srcfile = os.path.join(src_path, file)
    dstfile = os.path.join(dst_path, file)
    if not os.path.isfile(srcfile):
        print("%s not exist!" % (srcfile))
    else:
        if not os.path.exists(dst_path):
            os.makedirs(dst_path)
        shutil.move(srcfile, dstfile)
        print("move %s -> %s" % (srcfile, dstfile))


def ave_pooling(arr, nrows, ncols):
    """
    If arr is a 2D array, the returned array should look like n subblocks (nrows * ncols) with
    each subblock preserving the "physical" layout of arr, where n * nrows * ncols = arr.size.
    """
    h, w = arr.shape
    assert h % nrows == 0, "{} rows is not evenly divisble by {}".format(h, nrows)
    assert w % ncols == 0, "{} cols is not evenly divisble by {}".format(w, ncols)
    sub_arrs = arr.reshape(h//nrows, nrows, -1, ncols).swapaxes(1,2).reshape(-1, nrows, ncols)
    temp = np.empty_like(np.arange(int(h / nrows) * int(w / ncols), dtype=float))
    for i in range(sub_arrs.shape[0]):
        temp[i] = np.average(sub_arrs[i])
    result = temp.reshape((int(h / nrows), int(w / ncols)))
    return result


def coe_generation_2d(input_data, dim=8):
    """Dataset of fracturing coe matching the actual mesh in forward modeling

    default num_label_channels = 1

    default size of each label: (8, 8)
    """
    num_samples = input_data.shape[0]
    data_dim = input_data.shape[1]
    coe = np.empty([num_samples, dim, dim])
    for i in range(num_samples):
        coe[i] = ave_pooling(input_data[i], nrows=int(data_dim / dim), ncols=int(data_dim / dim))
    print('Size of FracCon coe dataset\'s: ', coe.shape)
    return coe

def casingCon_generation(input_data, dim=50, edgeSize=50, max_casingCon=1.5e5):
    """Dataset of casingCon matching the actual mesh in forward modeling

    default num_label_channels = 1

    default size of each label: 50

    """
    num_samples = input_data.shape[0]
    vec_length = input_data.shape[1]
    casingCon = np.empty([num_samples, dim])
    # dim * edgeSize = casing_length
    # dx = casing_length / (vec_length - 1)
    dx = int((dim * edgeSize) / (vec_length - 1))
    n = int((vec_length - 1) / dim) # edgeSize / dx
    print(n, dx)
    input_data_log = input_data * np.log10(max_casingCon)
    print(input_data_log.shape)
    for i in range(num_samples):
        for j in range(dim):
            eq_anomalous_casingRes = np.abs(np.trapz(1 / np.power(10, input_data_log[i][n*j: n*(j+1)+1]), dx=dx))
            casingCon[i][j] = edgeSize / eq_anomalous_casingRes
    print('Size of CasingCon dataset\'s: ', casingCon.shape)
    return casingCon

def train():
    """ U-net neural network training

    1. Load data and network model
    2. Settings: loss function + callbacks
    3. Duration time report
    4. Save model and necessary log information
    5. Save test data (X_test and y_test)
    """
    ## Pre-training
    # load and split data
    train_data, train_target = read_data(data_format=gConfig['input_format'],
                                         label_format=gConfig['label_format'])
    print('train_data shape: ', train_data.shape)
    print('train_target shape: ', train_target.shape)
    input_shape, (X_train, y_train), (X_vail, y_vail), (X_test, y_test) = generator.Split(train_data=train_data, train_target=train_target)

    # load network (model) architecture
    model = creat_model(input_shape)

    ## Settings
    # 1. Set loss function and monitor during training
    if gConfig['loss_function'] == 'rmse':
        monitor = 'val_' + gConfig['loss_function']
    else:
        monitor = 'val_loss'

    # 2. Callbacks
    # temp models' saving path
    models_dir = os.path.join(gConfig['infopath'], gConfig['temp_models'])
    model_name = gConfig['model_name_prefix'] + '.{epoch:04d}.h5'
    if not os.path.isdir(models_dir):
        os.makedirs(models_dir)
    filepath = os.path.join(models_dir, model_name)

    # Callback: save the Keras model or model weights at some frequency
    checkpoint = ModelCheckpoint(filepath=filepath,
                                 monitor=monitor,
                                 mode='min',
                                 verbose=0,
                                 save_best_only=True)

    # Callback: use custom learning rate scheduler
    lr_scheduler = LearningRateScheduler(lr_schedule, verbose=0)

    # Callback: reduce learning rate under certain condition
    lr_reducer = ReduceLROnPlateau(monitor=monitor,
                                   factor=np.sqrt(0.1),
                                   cooldown=0,
                                   patience=5,
                                   min_lr=0.5e-6)

    time_info = time.strftime('%Y%m%d_%H%M', time.localtime(time.time()))
    model_info_dir = os.path.join(gConfig['infopath'], 'models')
    Model_info = 'Model' + time_info
    info_path = os.path.join(model_info_dir, Model_info)
    if not os.path.isdir(info_path):
        os.makedirs(info_path)

    tensorboard_callback = TensorBoard(info_path, histogram_freq=1)

    # Callback: earlystopping
    # earlystopping = EarlyStopping(monitor=monitor,
    #                               patience=100,
    #                               mode='auto')

    callbacks = [checkpoint, lr_reducer, lr_scheduler, tensorboard_callback]

    ## model training
    start_time = time.time()
    history = model.fit(X_train, y_train,
                        batch_size=gConfig['batch_size'],
                        epochs=gConfig['epochs'],
                        validation_data=(X_vail, y_vail),
                        shuffle=True,
                        callbacks=callbacks,
                        verbose=0)
    duration = time.time() - start_time
    print('Duration time (s): ', duration)

    ## Save outputs to info_path
    # save last one model either overfitting or underfitting
    last_model_name = gConfig['model_name_prefix'] + '.%04d.h5' % gConfig['epochs']
    model.save(os.path.join(info_path, last_model_name))

    parser = configparser.ConfigParser()
    parser.read(config_file)

    # move best model to target folder
    filelist = os.listdir(models_dir)
    filelist.sort()
    model_id_count = 0
    print('save best %d models' % gConfig['top_models_count'])
    for filename in filelist[-1 * gConfig['top_models_count']:]:
        movefile(filename, models_dir, info_path)  # must suit %04d
        model_id_count += 1
        parser.set('strings', 'model_id%d' % model_id_count, filename)
        parser.set('ints', 'model_id_count', str(model_id_count))
        print(model_id_count)
    shutil.rmtree(models_dir)
    print('model_name created in config file')

    # save history information
    jsObj = json.dumps(history.history, cls=MyEncoder)
    fileObject = open(info_path + '/history_%s.json' % time_info, 'w')
    fileObject.write(jsObj)
    fileObject.close()

    # save ini in model folder
    parser.set('strings', 'predictionPath', info_path)
    parser.write(open(config_file, 'w'))
    shutil.copyfile(config_file, os.path.join(info_path, config_file))
    print('corresponding config information saved at %s' % (os.path.join(info_path, config_file)))

    # save data in npy format
    np.save(os.path.join(info_path, 'X_test'), X_test)
    np.save(os.path.join(info_path, 'y_test'), y_test)
    if gConfig['save_trainingdata']:
        save_trainingData_np(info_path, (X_train, y_train), (X_vail, y_vail))


def predict(test_data, model_path, model_count):
    """ U-net neural network prediction

    1. Load optimal network models from training phase
    2. Prediction (y_pred)
    3. Evaluation test dataset
    4. Record prediction path to config file
    5. Return y_pred for coe generation
    """
    for i in range(model_count):
        model_name = gConfig['model_id%d' % (i+1)]
        targetModel = os.path.join(model_path, model_name)
        model = load_model(targetModel)
        X_test = test_data[0]
        y_test = test_data[1]
        scores = model.evaluate(X_test, y_test, batch_size=gConfig['batch_size'], verbose=1)

        y_pred = model.predict(X_test, batch_size=gConfig['batch_size'])
        print('target model path is: %s' % (targetModel))
        np.save(os.path.join(model_path, 'y_pred_' + model_name), y_pred)

        for id, lf in enumerate(model.metrics_names):
            print('Best test (' + lf + '): ', scores[id])

    shutil.copyfile(config_file, os.path.join(model_path, config_file))
    print('corresponding config information saved at %s' % (os.path.join(model_path, config_file)))
    # return last y_pred (best one)
    return y_pred


if __name__ == '__main__':

    # select GPU device
    os.environ['CUDA_VISIBLE_DEVICES']='0'

    # tf.debugging.set_log_device_placement(True)
    print('dataPath is :', gConfig['datapath'])
    print('labelPath is: ', gConfig['labelpath'])
    generator = data_preprocessing()

    if mode == 'train':
        train()
    if mode == 'predict':
        X_test = np.load(os.path.join(gConfig['predictionpath'], 'X_test.npy'))
        y_test = np.load(os.path.join(gConfig['predictionpath'], 'y_test.npy'))

        y_pred = predict(test_data=(X_test, y_test),
                         model_path=gConfig['predictionpath'],
                         model_count=gConfig['model_id_count'])

        # save test_label and pred_label matching the actual mesh in forward modeling for calculate data misfit
        if gConfig['label_format'] == '2d':
            test_label = coe_generation_2d(input_data=np.squeeze(y_test, axis=3), dim=8)
            pred_label = coe_generation_2d(input_data=np.squeeze(y_pred, axis=3), dim=8)
        elif gConfig['label_format'] == '1d':
            test_label = casingCon_generation(input_data=np.squeeze(y_test, axis=2), dim=50)
            pred_label = casingCon_generation(input_data=np.squeeze(y_pred, axis=2), dim=50)
        print('Save actual label mat files for datamisfit calculation at %s.' % (gConfig['predictionpath']))
        savemat(os.path.join(gConfig['predictionpath'], 'test_label.mat'), {'test_label': test_label})
        savemat(os.path.join(gConfig['predictionpath'], 'pred_label.mat'), {'pred_label': pred_label})
