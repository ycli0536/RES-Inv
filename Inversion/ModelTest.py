#%%
import numpy as np
import os
import tensorflow as tf
import matplotlib.pyplot as plt

from keras.models import load_model
from keras import backend as K

# load model
model_dir = "E:/ML_test20191026/models/Model20191026_2152"
model_name = 'Fracturing_model.038.h5'
model_path = os.path.join(model_dir, model_name)

batch_size = 250


def weighted_root_mean_squared_error(g_weighted):
    def wrmse(y_true, y_pred):
        g = K.tile(g_weighted, tf.TensorShape([batch_size, 1, 1, 1]))  # y_pred.shape[0].value
        return K.sqrt(K.mean(K.square(tf.multiply((y_pred - y_true), g))))
    return wrmse


def root_mean_squared_error_(y_true, y_pred):
    return np.sqrt(np.mean(np.square(y_pred - y_true)))
def root_mean_squared_error(y_true, y_pred):
    return K.sqrt(K.mean(K.square(y_pred - y_true)))


LossFunction = 'wrmse'

x, y = np.mgrid[-1: 1: 80j, -1: 1: 80j]
cos_omega = 0.9
zz = np.sqrt(x**2 + y**2)
zz[zz > 2.2*np.pi] = 0
c = 1.3 - 0.5*np.cos(cos_omega*zz)
cos_weighted = K.variable(c**2)
cos_weighted = K.expand_dims(cos_weighted, -1)
cos_weighted = K.expand_dims(cos_weighted, 0)
WRMSE = weighted_root_mean_squared_error(cos_weighted)

best_model = load_model(model_path, custom_objects={LossFunction: WRMSE,
                                                    'root_mean_squared_error': root_mean_squared_error})

# %%
# load data
data_type = "SurfNoise0.05"
home_path = "E:/ML_test20191026/TestData"
data_path = os.path.join(home_path, data_type)
test_data   = np.load(data_path +   '\\test_data_' + data_type + '.npy')
test_target = np.load(data_path + '\\test_target_' + data_type + '.npy')
X_test = test_data
y_test = test_target

# %% Prediction
# Scores of trained model.
scores = best_model.evaluate(X_test, y_test, batch_size=batch_size, verbose=1)
print('Test loss (' + data_type + '):', scores[0])
y_pred = best_model.predict(X_test, batch_size=batch_size, verbose=1)

fig = plt.figure(figsize=(20, 5))

plt_list = enumerate(np.random.randint(0, y_pred.shape[0], size=10))

for i, index in plt_list:
    ax = fig.add_subplot(2, 10, i + 1)
    ax.imshow(y_test[index, :, :, 0], vmin=0, vmax=np.max(test_target))
    ax.axis('off')
    plt.title('#%d' % index)

    ax = fig.add_subplot(2, 10, i + 1 + 10)
    ax.imshow(y_pred[index, :, :, 0], vmin=0, vmax=np.max(test_target))
    plt.title('loss: %.3f' % root_mean_squared_error_(y_test[index, :, :, 0], y_pred[index, :, :, 0]))
    ax.axis('off')
plt.savefig(os.path.join(data_path, 'test_' + data_type + '.png'), facecolor='w')

#%% comparasion with no-noise data
data_path = "F:/Geophysics/ML_test20190830/data/Data"
X_vail = np.load(os.path.join(data_path, 'X_vail.npy'))
y_vail = np.load(os.path.join(data_path, 'y_vail.npy'))
# y_pred_best = np.load(os.path.join(model_dir, 'y_pred_best.npy'))
y_pred_best = best_model.predict(X_vail, batch_size=batch_size, verbose=1)

# Scores of trained model.
scores_best = best_model.evaluate(X_vail, y_vail, batch_size=batch_size, verbose=1)
print('Test loss (no-noise data):', scores_best[0])
print('Test accuracy (no-noise data):', scores_best[1])

fig = plt.figure(figsize=(20, 5))

plt_list = enumerate(np.random.randint(0,y_pred_best.shape[0], size=10))

for i, index in plt_list:
    ax = fig.add_subplot(2, 10, i + 1)
    # ax.imshow(y_vail[index,:,:,0])
    ax.imshow(y_vail[index, :, :, 0], vmin=0, vmax=np.max(test_target))
    # ax.grid()
    ax.axis('off')
    plt.title('#%d' % index)
    ax = fig.add_subplot(2, 10, i + 1 + 10)
    # ax.imshow(y_pred_best[index,:,:,0])
    ax.imshow(y_pred_best[index, :, :, 0], vmin=0, vmax=np.max(test_target))
    # ax.grid()
    plt.title('loss: %.3f' % root_mean_squared_error(y_vail[index, :, :, 0], y_pred_best[index, :, :, 0]))
    ax.axis('off')
plt.savefig('test.png', facecolor='w')
#%%
