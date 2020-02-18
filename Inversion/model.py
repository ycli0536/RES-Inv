import getConfig
from tensorflow.keras.layers import Activation, BatchNormalization, Input
from tensorflow.keras.layers import Conv2D, MaxPooling2D, LeakyReLU
from tensorflow.keras.layers import UpSampling2D
from tensorflow.keras.layers import Dropout
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

    inputs = Input(input_shape)

    conv1 = con_block(inputs, num_filters=num_filters_in)
    conv1 = con_block(conv1, num_filters=num_filters_in)
    conv1 = con_block(conv1, num_filters=num_filters_in)
    drop1 = Dropout(rate=dr)(conv1)
    pool1 = MaxPooling2D((2, 2))(drop1)
    num_filters_in *= 2

    conv2 = con_block(pool1, num_filters=num_filters_in)
    conv2 = con_block(conv2, num_filters=num_filters_in)
    conv2 = con_block(conv2, num_filters=num_filters_in)
    drop2 = Dropout(rate=dr)(conv2)
    pool2 = MaxPooling2D((2, 2))(drop2)
    num_filters_in *= 2

    conv3 = con_block(pool2, num_filters=num_filters_in, padding='valid')
    conv3 = con_block(conv3, num_filters=num_filters_in)
    conv3 = con_block(conv3, num_filters=num_filters_in)
    drop3 = Dropout(dr)(conv3)
    num_filters_in /= 2
    num_filters_in = int(num_filters_in)

    up4 = UpSampling2D(size=(2, 2))(drop3)
    conv4 = con_block(up4, num_filters=num_filters_in)
    conv4 = con_block(conv4, num_filters=num_filters_in)
    conv4 = con_block(conv4, num_filters=num_filters_in)
    num_filters_in /= 2
    num_filters_in = int(num_filters_in)

    up5 = UpSampling2D(size=(2, 2))(conv4)
    conv5 = con_block(up5, num_filters=num_filters_in)
    conv5 = con_block(conv5, num_filters=num_filters_in)
    conv5 = con_block(conv5, num_filters=num_filters_in)
    num_filters_in /= 2
    num_filters_in = int(num_filters_in)

    up6 = UpSampling2D(size=(2, 2))(conv5)
    conv6 = con_block(up6, num_filters=num_filters_in)
    conv6 = con_block(conv6, num_filters=num_filters_in)
    conv6 = con_block(conv6, num_filters=num_filters_in)
    num_filters_in /= 2
    num_filters_in = int(num_filters_in)

    conv7 = con_block(conv6, num_filters=num_filters_in)
    num_filters_in /= 4
    num_filters_in = int(num_filters_in)
    conv7 = con_block(conv7, num_filters=num_filters_in)
    conv7 = con_block(conv7, num_filters=1)

    model = Model(inputs=inputs, outputs=conv7)

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
