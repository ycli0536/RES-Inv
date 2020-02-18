import getConfig
from tensorflow.keras.layers import Activation, BatchNormalization, Input
from tensorflow.keras.layers import Conv2D, MaxPooling2D, LeakyReLU
from tensorflow.keras.layers import UpSampling2D, concatenate
from tensorflow.keras.layers import Dropout, Flatten, Dense
from tensorflow.keras.optimizers import Adam
from tensorflow.keras.models import Model


# initializing a dic containing configure parameters
gConfig = {}
gConfig = getConfig.get_config(config_file='config.ini')
dr = gConfig['dropout_rate']
leakyReLU_alpha = gConfig['leakyrelu_alpha']


def con_block(inputs,
              num_filters=32,
              kernel_size=3,
              strides=1,
              padding='same',
              activation='relu',
              batch_bormalization=True,
              dropout=False):
    conv = Conv2D(num_filters,
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


def fcn(input_shape, num_filters_in=32):
    """ Fully Convolutional Network

     The network consists of 5 levels
     (2 max pooling and 3 upscaling)
     each having three convolutional
      blocks (convolution + batch normalization + ReLU).
    """

    inputs = Input(input_shape)  # [51 51 3]

    conv1 = con_block(inputs, num_filters=num_filters_in)
    # [51 51 32]
    conv1 = con_block(conv1, num_filters=num_filters_in, padding='valid')
    # [51 51 32]
    drop1 = Dropout(rate=dr)(conv1)
    # [49 49 32]
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
    num_filters_in /= 2
    num_filters_in = int(num_filters_in)

    up5 = UpSampling2D(size=(2, 2))(drop4)
    # [12 12 256]
    merge5 = concatenate([conv3, up5], axis=3)
    # [12 12 256+128=384]
    conv5 = con_block(merge5, num_filters=num_filters_in)
    # [12 12 64]
    conv5 = con_block(conv5, num_filters=num_filters_in)
    # [12 12 64]
    num_filters_in /= 2
    num_filters_in = int(num_filters_in)

    up6 = UpSampling2D(size=(2, 2))(conv5)
    # [24 24 64]
    merge6 = concatenate([conv2, up6], axis=3)
    # [24 24 64+128=192]
    conv6 = con_block(merge6, num_filters=num_filters_in)
    # [24 24 32]
    conv6 = con_block(conv6, num_filters=num_filters_in)
    # [24 24 32]
    conv7 = con_block(conv6, num_filters=2)

    # num_filters_in /= 2
    # num_filters_in = int(num_filters_in)

    # up7 = UpSampling2D(size=(2, 2))(conv6)
    # # [48 48 32]
    # conv7 = con_block(up7, num_filters=num_filters_in)
    # # [48 48 16]
    # conv7 = con_block(conv7, num_filters=1)
    # # [48 48 1]

    x = Flatten()(conv7)
    output = Dense(gConfig['target_value_length'], activation='relu')(x)

    model = Model(inputs=inputs, outputs=output)

    return model


class fcnModel(object):
    def __init__(self, input_shape):
        self.input_shape = input_shape

    def createModel(self, summary=False):
        fcn_model = fcn(input_shape=self.input_shape)
        fcn_model.compile(loss='mean_squared_error',
                          optimizer=Adam(lr=0.001),
                          metrics=['mean_squared_error'])
        if summary:
            fcn_model.summary()
        return fcn_model
