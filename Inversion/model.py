from getConfig import gConfig
from tensorflow.keras.layers import Activation, BatchNormalization, Input
from tensorflow.keras.layers import Conv2D, MaxPooling2D, LeakyReLU
from tensorflow.keras.layers import Conv1D, MaxPooling1D
from tensorflow.keras.layers import UpSampling2D, UpSampling1D, concatenate
from tensorflow.keras.layers import Dropout, Flatten, Dense
from tensorflow.keras.optimizers import Adam
from tensorflow.keras.models import Model
import tensorflow as tf
from tensorflow.keras import backend as K

# initializing a dic containing configure parameters
dr = gConfig['dropout_rate']
leakyReLU_alpha = gConfig['leakyrelu_alpha']


def root_mean_squared_error(y_true, y_pred):
    return K.sqrt(K.mean(K.square(y_pred - y_true)))


def con_block(inputs,
              num_filters=32,
              kernel_size=3,
              strides=1,
              padding='same',
              activation='relu',
              batch_normalization=True,
              dropout=False):
    conv = Conv2D(num_filters,
                  kernel_size=kernel_size,
                  strides=strides,
                  padding=padding,
                  kernel_initializer='he_uniform')  # or glorot_uniform

    x = inputs
    x = conv(x)

    if batch_normalization:
        x = BatchNormalization()(x)
    if dropout:
        x = Dropout(rate=dr)(x)
    if activation is not None:
        if activation == 'LeakyReLU':
            x = LeakyReLU(alpha=leakyReLU_alpha)(x)
        else:
            x = Activation(activation)(x)

    return x


def con_block_1d(inputs,
                 num_filters=16,
                 kernel_size=3,
                 strides=1,
                 padding='same',
                 activation=tf.nn.relu,
                 batch_bormalization=True,
                 dropout=False):
    conv = Conv1D(num_filters,
                  kernel_size=kernel_size,
                  strides=strides,
                  padding=padding,
                  kernel_initializer='he_uniform')  # or glorot_uniform

    x = inputs
    x = conv(x)

    if batch_bormalization:
        x = BatchNormalization()(x)
    if dropout:
        x = Dropout(rate=dr)(x)
    if activation is not None:
        if activation == 'LeakyReLU':
            x = LeakyReLU(alpha=leakyReLU_alpha)(x)
        else:
            x = Activation(activation)(x)

    return x


def fcn_2d_2d(input_shape, num_filters_in=32):
    """ Fully Convolutional Network

     The network consists of 5 levels
     (2 max pooling and 3 upscaling)
     each having three convolutional
      blocks (convolution + batch normalization + ReLU).
    """

    inputs = Input(input_shape)  # [51 51 3]

    conv1 = con_block(inputs, num_filters=num_filters_in, kernel_size=2, padding='valid')
    # [50 50 32]
    conv1 = con_block(conv1, num_filters=num_filters_in, padding='valid')
    # [48 48 32]
    drop1 = Dropout(rate=dr)(conv1)
    # [48 48 32]
    pool1 = MaxPooling2D((2, 2))(drop1)
    # [24 24 32]

    num_filters_in *= 2
    conv2 = con_block(pool1, num_filters=num_filters_in)
    # [24 24 64]
    conv2 = con_block(conv2, num_filters=num_filters_in)
    # [24 24 64]
    drop2 = Dropout(rate=dr)(conv2)
    # [24 24 64]
    pool2 = MaxPooling2D((2, 2))(drop2)
    # [12 12 64]

    num_filters_in *= 2
    conv3 = con_block(pool2, num_filters=num_filters_in)
    # [12 12 128]
    conv3 = con_block(conv3, num_filters=num_filters_in)
    # [12 12 128]
    drop3 = Dropout(rate=dr)(conv3)
    # [12 12 128]
    pool3 = MaxPooling2D((2, 2))(drop3)
    # [6 6 128]

    num_filters_in *= 2
    conv4 = con_block(pool3, num_filters=num_filters_in)
    # [6 6 256]
    conv4 = con_block(conv4, num_filters=num_filters_in)
    # [6 6 256]
    drop4 = Dropout(rate=dr)(conv4)
    # [6 6 256]

    up5 = UpSampling2D(size=(2, 2))(drop4)
    # [12 12 256]
    merge5 = concatenate([conv3, up5], axis=3)
    # [12 12 128+256=384]
    num_filters_in /= 2
    num_filters_in = int(num_filters_in)
    conv5 = con_block(merge5, num_filters=num_filters_in)
    # [12 12 128]
    conv5 = con_block(conv5, num_filters=num_filters_in)
    # [12 12 128]

    up6 = UpSampling2D(size=(2, 2))(conv5)
    # [24 24 128]
    merge6 = concatenate([conv2, up6], axis=3)
    # [24 24 64+128=192]
    num_filters_in /= 2
    num_filters_in = int(num_filters_in)
    conv6 = con_block(merge6, num_filters=num_filters_in)
    # [24 24 64]
    conv6 = con_block(conv6, num_filters=num_filters_in)
    # [24 24 64]

    up7 = UpSampling2D(size=(2, 2))(conv6)
    # [48 48 64]
    merge7 = concatenate([conv1, up7], axis=3)
    # [48 48 32+64=96]
    num_filters_in /= 2
    num_filters_in = int(num_filters_in)
    conv7 = con_block(merge7, num_filters=num_filters_in)
    # [48 48 32]
    conv7 = con_block(conv7, num_filters=num_filters_in)
    # [48 48 32]

    up8 = UpSampling2D(size=(2, 2))(conv7)
    # [96 96 32]
    num_filters_in /= 2
    num_filters_in = int(num_filters_in)
    conv8 = con_block(up8, num_filters=num_filters_in)
    # [96 96 16]
    conv8 = con_block(conv8, num_filters=1)
    # [96 96 1]

    model = Model(inputs=inputs, outputs=conv8)

    return model


def fcn_2d_1d(input_shape, num_filters_in=16):

    inputs = Input(input_shape)  # [51 51 2]

    conv1 = con_block(inputs, num_filters=num_filters_in, kernel_size=2, padding='valid')
    # [50 50 16]
    conv1 = con_block(conv1, num_filters=num_filters_in, padding='valid')
    # [48 48 16]
    pool1 = MaxPooling2D((2, 2))(conv1)
    # [24 24 16]
    num_filters_in *= 2

    conv2 = con_block(pool1, num_filters=num_filters_in)
    # [24 24 32]
    conv2 = con_block(conv2, num_filters=num_filters_in)
    # [24 24 32]
    pool2 = MaxPooling2D((2, 2))(conv2)
    # [12 12 32]
    num_filters_in *= 2

    conv3 = con_block(pool2, num_filters=num_filters_in)
    # [12 12 64]
    conv3 = con_block(conv3, num_filters=num_filters_in)
    # [12 12 64]
    pool3 = MaxPooling2D((2, 2))(conv3)
    # [6 6 64]
    num_filters_in *= 2

    conv4 = con_block(pool3, num_filters=num_filters_in)
    # [6 6 128]
    conv4 = con_block(conv4, num_filters=num_filters_in)
    # [6 6 128]
    num_filters_in /= 2
    num_filters_in = int(num_filters_in)

    up5 = UpSampling2D(size=(2, 2))(conv4)
    # [12 12 64]
    merge5 = concatenate([conv3, up5], axis=3)
    # [12 12 64+64=128]
    conv5 = con_block(merge5, num_filters=num_filters_in)
    # [12 12 64]
    conv5 = con_block(conv5, num_filters=num_filters_in)
    # [12 12 64]
    num_filters_in /= 2
    num_filters_in = int(num_filters_in)

    up6 = UpSampling2D(size=(2, 2))(conv5)
    # [24 24 32]
    merge6 = concatenate([conv2, up6], axis=3)
    # [24 24 32+32=64]
    conv6 = con_block(merge6, num_filters=num_filters_in)
    # [24 24 32]
    conv6 = con_block(conv6, num_filters=num_filters_in)
    # [24 24 32]
    num_filters_in /= 2
    num_filters_in = int(num_filters_in)

    up7 = UpSampling2D(size=(2, 2))(conv6)
    # [48 16]
    merge7 = concatenate([conv1, up7], axis=3)
    # [48 16+16=32]
    conv7 = con_block(merge7, num_filters=num_filters_in)
    # [48 16]
    conv7 = con_block(conv7, num_filters=num_filters_in)
    # [48 16]

    conv8 = con_block(conv7, num_filters=1)

    flatten = Flatten()(conv8)

    drop1 = Dropout(rate=dr)(flatten)

    dense = Dense(1000, activation='relu')(drop1)

    drop = Dropout(rate=dr)(dense)

    output = Dense(gConfig['target_value_length'], activation='relu')(drop)

    model = Model(inputs=inputs, outputs=output)

    return model


def fcn_1d_1d(input_shape, num_filters_in=16):

    inputs = Input(input_shape)  # [51 1]

    conv1 = con_block_1d(inputs, num_filters=num_filters_in, kernel_size=2, padding='valid')
    # [50 16]
    conv1 = con_block_1d(conv1, num_filters=num_filters_in, padding='valid')
    # [48 16]
    conv1 = con_block_1d(conv1, num_filters=num_filters_in)
    # [48 16]
    pool1 = MaxPooling1D(2)(conv1)
    # [24 16]
    num_filters_in *= 2

    conv2 = con_block_1d(pool1, num_filters=num_filters_in)
    # [24 32]
    conv2 = con_block_1d(conv2, num_filters=num_filters_in)
    # [24 32]
    conv2 = con_block_1d(conv2, num_filters=num_filters_in)
    # [24 32]
    pool2 = MaxPooling1D(2)(conv2)
    # [12 32]
    num_filters_in *= 2

    conv3 = con_block_1d(pool2, num_filters=num_filters_in)
    # [12 64]
    conv3 = con_block_1d(conv3, num_filters=num_filters_in)
    # [12 64]
    conv3 = con_block_1d(conv3, num_filters=num_filters_in)
    # [12 64]
    pool3 = MaxPooling1D(2)(conv3)
    # [6 64]
    num_filters_in *= 2

    conv4 = con_block_1d(pool3, num_filters=num_filters_in)
    # [6 128]
    conv4 = con_block_1d(conv4, num_filters=num_filters_in)
    # [6 128]
    conv4 = con_block_1d(conv4, num_filters=num_filters_in)
    # [6 128]
    num_filters_in /= 2
    num_filters_in = int(num_filters_in)

    up5 = UpSampling1D(size=2)(conv4)
    # [12 64]
    merge5 = concatenate([conv3, up5], axis=2)
    # [12 64+64=128]
    conv5 = con_block_1d(merge5, num_filters=num_filters_in)
    # [12 64]
    conv5 = con_block_1d(conv5, num_filters=num_filters_in)
    # [12 64]
    conv5 = con_block_1d(conv5, num_filters=num_filters_in)
    # [12 64]
    num_filters_in /= 2
    num_filters_in = int(num_filters_in)

    up6 = UpSampling1D(size=2)(conv5)
    # [24 32]
    merge6 = concatenate([conv2, up6], axis=2)
    # [24 32+32=64]
    conv6 = con_block_1d(merge6, num_filters=num_filters_in)
    # [24 32]
    conv6 = con_block_1d(conv6, num_filters=num_filters_in)
    # [24 32]
    conv6 = con_block_1d(conv6, num_filters=num_filters_in)
    # [24 32]
    num_filters_in /= 2
    num_filters_in = int(num_filters_in)

    up7 = UpSampling1D(size=2)(conv6)
    # [48 16]
    merge7 = concatenate([conv1, up7], axis=2)
    # [48 16+16=32]
    conv7 = con_block_1d(merge7, num_filters=num_filters_in)
    # [48 16]
    conv7 = con_block_1d(conv7, num_filters=num_filters_in)
    # [48 16]
    conv7 = con_block_1d(conv7, num_filters=num_filters_in)
    # [48 16]

    flatten = Flatten()(conv7)

    drop = Dropout(rate=dr)(flatten)

    output = Dense(gConfig['target_value_length'], activation=tf.nn.relu)(drop)

    model = Model(inputs=inputs, outputs=output)

    return model


def fcn(input_shape, input_format, label_format):
    if (input_format == '1d') & (label_format == '1d'):
        model = fcn_1d_1d(input_shape=input_shape)
    elif (input_format == '2d') & (label_format == '1d'):
        model = fcn_2d_1d(input_shape=input_shape)
    elif (input_format == '2d') & (label_format == '2d'):
        model = fcn_2d_2d(input_shape=input_shape)

    return model


class fcnModel(object):
    def __init__(self, input_shape):
        self.input_shape = input_shape

    def createModel(self, summary=False,
                    input_format=gConfig['input_format'],
                    label_format=gConfig['label_format'],
                    multi_gpu=False):
        if multi_gpu:
            print("Training using multiple GPUs..")
            strategy = tf.distribute.MirroredStrategy(cross_device_ops=tf.distribute.HierarchicalCopyAllReduce())
            with strategy.scope():
                fcn_model = fcn(input_shape=self.input_shape,
                                input_format=input_format,
                                label_format=label_format)
        else:
            fcn_model = fcn(input_shape=self.input_shape,
                            input_format=input_format,
                            label_format=label_format)

        if gConfig['metric_added'] == 'rmse':
            fcn_model.compile(optimizer=Adam(),
                              loss=gConfig['loss_function'],
                              metrics=[tf.keras.metrics.RootMeanSquaredError(name=gConfig['metric_added'])])

        if summary:
            fcn_model.summary()
        return fcn_model
