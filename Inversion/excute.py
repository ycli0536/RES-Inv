import tensorflow as tf
import numpy as np
from model import fcnModel

from tensorflow.keras.models import load_model
from tensorflow.keras.callbacks import ModelCheckpoint, LearningRateScheduler, ReduceLROnPlateau, EarlyStopping

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


def read_data(data_format, label_format):

    if data_format == '2d':
        train_data = generator.inputData_2d(dataPath=gConfig['datapath'],
                                            num_images=gConfig['num_images'],
                                            im_dim=gConfig['im_dim'],
                                            num_channels=gConfig['num_channels']
                                            )
    elif data_format == '1d':
        train_data = generator.inputData_1d(dataPath=gConfig['datapath'],
                                            data_file=gConfig['data_file_name']
                                            )
    else:
        print('--- Wrong input format! ---')

    if label_format == '2d':
        train_target = generator.label_2d(labelPath=gConfig['labelpath'],
                                          label_file=gConfig['label_file_name'],
                                          num_samples=gConfig['num_images'],
                                          label_dim=gConfig['label_dim'],
                                          num_channels=gConfig['num_label_channels']
                                          )
    elif label_format == '1d':
        train_target = generator.label_1d(labelPath=gConfig['labelpath'],
                                          label_file=gConfig['label_file_name']
                                          )
    else:
        print('--- Wrong label format! ---')
    return train_data, train_target


train_data, train_target = read_data(data_format=gConfig['input_format'],
                                     label_format=gConfig['label_format'])
print('train_data shape: ', train_data.shape)
print('train_target shape: ', train_target.shape)
input_shape, (X_train, y_train), (X_vail, y_vail), (X_test, y_test) = generator.Split(train_data=train_data, train_target=train_target)


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
    if epoch > 800:
        lr *= pow(5e-1, 4)
    elif epoch > 600:
        lr *= pow(5e-1, 3)
    elif epoch > 400:
        lr *= pow(5e-1, 2)
    elif epoch > 200:
        lr *= 5e-1
    return lr


def creat_model():
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


def train():
    model = creat_model()
    models_dir = os.path.join(gConfig['infopath'], 'saved_models')
    model_name = gConfig['model_name_prefix'] + '.{epoch:04d}.h5'
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

    lr_scheduler = LearningRateScheduler(lr_schedule, verbose=1)

    lr_reducer = ReduceLROnPlateau(monitor=monitor,
                                   factor=np.sqrt(0.1),
                                   cooldown=0,
                                   patience=5,
                                   min_lr=0.5e-6)

    earlystopping = EarlyStopping(monitor=monitor,
                                  patience=100,
                                  mode='auto')

    callbacks = [checkpoint, lr_reducer, lr_scheduler, earlystopping]

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
    last_model_name = gConfig['model_name_prefix'] + '.%04d.h5' % gConfig['epochs']
    model.save(os.path.join(info_path, last_model_name))

    # move best model to target folder
    filelist = os.listdir(models_dir)
    filelist.sort()
    print('save best %d models' % gConfig['top_models_count'])
    for filename in filelist[-1 * gConfig['top_models_count']:]:
        movefile(filename, models_dir, info_path)  # must suit %04d
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
    parser.set('strings', 'last_model_name', filelist[-1])
    parser.set('strings', 'mode', 'predict')
    parser.write(open('config.ini', 'w'))
    shutil.copyfile('config.ini', os.path.join(info_path, 'config.ini'))
    print('last_model_name created in config file')
    print('corresponding config information saved at %s' % (os.path.join(info_path, 'config.ini')))

    # save data in npy format
    np.save(os.path.join(info_path, 'X_test'), X_test)
    np.save(os.path.join(info_path, 'y_test'), y_test)
    if gConfig['save_trainingdata']:
        save_trainingData_np(info_path, (X_train, y_train), (X_vail, y_vail))


def predict(test_data, model_path, model_name):
    targetModel = os.path.join(model_path, model_name)
    print('target model path is: %s' % (targetModel))
    model = load_model(targetModel)
    X_test = test_data[0]
    y_test = test_data[1]
    scores = model.evaluate(X_test, y_test, batch_size=gConfig['batch_size'], verbose=1)

    y_pred = model.predict(X_test, batch_size=gConfig['batch_size'])
    np.save(os.path.join(model_path, 'y_pred_' + model_name), y_pred)

    for id, lf in enumerate(model.metrics_names):
        print('Best test (' + lf + '): ', scores[id])


if __name__ == '__main__':
    gConfig = getConfig.get_config()
    if gConfig['mode'] == 'train':
        train()
    if gConfig['mode'] == 'predict':
        X_test = np.load(os.path.join(gConfig['predictionpath'], 'X_test.npy'))
        y_test = np.load(os.path.join(gConfig['predictionpath'], 'y_test.npy'))

        predict(test_data=(X_test, y_test),
                model_path=gConfig['predictionpath'],
                model_name=gConfig['model_name'])
