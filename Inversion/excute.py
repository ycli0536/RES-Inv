import tensorflow as tf
import numpy as np
from model import fcnModel

from tensorflow.keras.models import load_model
from tensorflow.keras.callbacks import ModelCheckpoint, LearningRateScheduler, ReduceLROnPlateau

from data_generation import data_preprocessing
import getConfig
import configparser
import os
import time
import shutil
import json

# tf.debugging.set_log_device_placement(True)

gConfig = {}
gConfig = getConfig.get_config(config_file='config.ini')
print('dataPath is :', gConfig['datapath'])
print('labelPath is: ', gConfig['labelpath'])
generator = data_preprocessing()
if gConfig['input_format'] == '2d':
    train_data, train_target = generator.read_data_2d(
                               dataPath=gConfig['datapath'],
                               labelPath=gConfig['labelpath'],
                               labelFile=gConfig['label_name'],
                               num_images=gConfig['num_images'],
                               im_dim=gConfig['im_dim'],
                               num_channels=gConfig['num_channels']
                               )
    print('train_data shape: ', train_data.shape)
    print('train_target shape: ', train_target.shape)
    input_shape, (X_train, y_train), (X_vail, y_vail), (X_test, y_test) = generator.Split(train_data=train_data, train_target=train_target)
elif gConfig['input_format'] == '1d':
    train_data, train_target = generator.read_data_1d(
                               dataPath=gConfig['datapath'],
                               data_file=gConfig['1d_file_name'],
                               labelPath=gConfig['labelpath'],
                               labelFile=gConfig['label_name']
                               )
    train_data = train_data.reshape((train_data.shape[0], train_data.shape[1], 1))
    print('train_data shape: ', train_data.shape)
    print('train_target shape: ', train_target.shape)
    input_shape, (X_train, y_train), (X_vail, y_vail), (X_test, y_test) = generator.Split(train_data=train_data, train_target=train_target)
else:
    print('--- Wrong input format! ---')

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
    # if epoch > 75:
    #     lr *= 1e-3
    # elif epoch > 50:
    #     lr *= 1e-2
    # elif epoch > 25:
    #     lr *= 1e-1
    print('Learning rate: ', lr)
    return lr


def creat_model():
    model = fcnModel(input_shape=input_shape)
    model = model.createModel(summary=True, input_format=gConfig['input_format'])
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


def train():
    model = creat_model()
    models_dir = os.path.join(gConfig['infopath'], 'saved_models')
    model_name = gConfig['model_name_prefix'] + '.{epoch:03d}.h5'
    if not os.path.isdir(models_dir):
        os.makedirs(models_dir)
    filepath = os.path.join(models_dir, model_name)

    if gConfig['loss_function'] == 'rmse':
        monitor = 'val_' + gConfig['loss_function']
    else:
        monitor = 'val_loss'

    checkpoint = ModelCheckpoint(filepath=filepath,
                                 monitor=monitor,
                                 mode='min',
                                 verbose=1,
                                 save_best_only=True)

    lr_scheduler = LearningRateScheduler(lr_schedule)

    lr_reducer = ReduceLROnPlateau(factor=np.sqrt(0.1),
                                   cooldown=0,
                                   patience=5,
                                   min_lr=0.5e-6)

    callbacks = [checkpoint, lr_reducer, lr_scheduler]

    start_time = time.time()
    history = model.fit(X_train, y_train,
                        batch_size=gConfig['batch_size'],
                        epochs=gConfig['epochs'],
                        validation_data=(X_vail, y_vail),
                        shuffle=True,
                        callbacks=callbacks)
    duration = time.time() - start_time
    print('Duration time (s): ', duration)

    model_info_dir = os.path.join(gConfig['infopath'], 'models')
    time_info = time.strftime('%Y%m%d_%H%M', time.localtime(time.time()))
    Model_info = 'Model' + time_info
    info_path = os.path.join(model_info_dir, Model_info)
    if not os.path.isdir(info_path):
        os.makedirs(info_path)

    # save last one model either overfitting or underfitting
    last_model_name = gConfig['model_name_prefix'] + '.%03d.h5' % gConfig['epochs']
    model.save(os.path.join(info_path, last_model_name))

    # move best model to target folder
    filelist = os.listdir(models_dir)
    filelist.sort()
    movefile(filelist[-1], models_dir, info_path)
    shutil.rmtree(models_dir)

    # save history information
    jsObj = json.dumps(history.history, cls=MyEncoder)
    fileObject = open(info_path + '/history_%s.json' % time_info, 'w')
    fileObject.write(jsObj)
    fileObject.close()

    # save ini in model folder
    parser = configparser.ConfigParser()
    parser.read('config.ini')
    parser.set('strings', 'predictionPath', info_path)
    parser.set('strings', 'model_name', last_model_name)
    parser.write(open('config.ini', 'w'))
    shutil.copyfile('config.ini', os.path.join(info_path, 'config.ini'))
    print('model_name created in config file')
    print('corresponding config file path is %s' % (os.path.join(info_path, 'config.ini')))


def predict(test_data, model_path, model_name):
    targetModel = os.path.join(model_path, model_name)
    print('target model path is: %s' % (targetModel))
    model = load_model(targetModel)
    X_test = test_data[0]
    y_test = test_data[1]
    scores = model.evaluate(X_test, y_test, batch_size=gConfig['batch_size'], verbose=1)

    y_pred = model.predict(X_test, batch_size=gConfig['batch_size'])
    np.save(os.path.join(model_path, 'y_pred_' + model_name), y_pred)
    np.save(os.path.join(model_path, 'y_test_' + model_name), y_test)

    for id, lf in enumerate(model.metrics_names):
        print('Best test (' + lf + '): ', scores[id])


if __name__ == '__main__':
    gConfig = getConfig.get_config()
    if gConfig['mode'] == 'train':
        train()
    if gConfig['mode'] == 'predict':
        predict((X_test, y_test), gConfig['predictionpath'], gConfig['model_name'])
