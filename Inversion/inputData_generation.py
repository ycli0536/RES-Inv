import numpy as np
import os
from getConfig import gConfig

from data_generation import data_preprocessing

generator = data_preprocessing()

data_for_pred = generator.inputData_2d(dataPath=gConfig['datapath'],
                                       data_file=gConfig['data_file_name'],
                                       num_samples=gConfig['num_samples'],
                                       im_dim=gConfig['im_dim'],
                                       num_channels=gConfig['num_channels'],
                                       data_form='raw'
                                       )

save_path = gConfig['predictionpath']
np.save(os.path.join(save_path, 'X_test'), data_for_pred)
print('Data for prediction saved at: ', save_path)