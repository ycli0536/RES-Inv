import matplotlib.pyplot as plt
import numpy as np
from PIL import Image
from scipy.io import loadmat

import argparse
import os


# target path (default path: pwd)
# [-f] file name
# [-o] output path
# [-s] save or not
# [-plt] show certain profile


def plot_casing_prof(images_range, num_segments, data):
    depths = np.linspace(0, Maxdepth, 10000)
    casingCon_prifle = np.empty_like(depths)
    fot i in range():

        for j in range(num_segments[i, 0]-1, -1, -1):
            casingCon = data[i][0][:, 6]
            casingCon_prifle[np.where(depths >= data[0][0][j, 5])] = casingCon[j]
            return 


def main():
    parser = argparse.ArgumentParser(description='python code plotting casing conductivity profiles for check',
                                     epilog="Yinchu Li 02/15/2020")
    parser.add_argument("filename", help="please input data file")
    # 2 ways: 1. with path; 2. without path
    parser.add_argument("-s", "--save", action="store_true", help="save all or not")
    parser.add_argument("-op", "--outputPATH", action="store_true", help="the path to put the profile images, default saving path is ./profiles")
    args = parser.parse_args()

    dataPATH = os.path.abspath(args.filename)
    print("Data path is: " + dataPATH)
    data = loadmat(dataPATH)["C"]
    print('Total number of samples: %d' % (np.size(data)))
    Maxdepth = min(data[0][0][:, 5])
    print('Max depth is: %.2fm' % Maxdepth)

    num_segments = loadmat(dataPATH)["num_segments"]
    if args.save:
        if args.outputPATH:
            plot_casing_prof(images_range=111,
                             num_segments=num_segments,
                             data=data,
                             savePath=os.path.abspath(arg.outputPATH))
        else:
            savePath = os.path.join(os.getcwd, 'casing_Con_profiles')
            if not os.path.isdir(savePath):
                os.makedirs(savePath)
            plot_casing_prof(images_range=111,
                             num_segments=num_segments,
                             data=data,
                             savePath=)


if __name__ == "__main__":
    main()
