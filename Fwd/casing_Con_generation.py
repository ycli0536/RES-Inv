import matplotlib.pyplot as plt
import numpy as np
from scipy.io import loadmat

import argparse
import os


def plot_casing_prof(images_range, data, savePath):
    for i in range(images_range):
        depth = np.append(0, data[i][0][:, 5])
        casing_con = np.append(data[i][0][0, 6], data[i][0][:, 6])

        fig, ax = plt.subplots(figsize=(2, 3))

        ax.step(casing_con, depth, where='post')
        # ax.plot(casing_con, depth, 'C0o', alpha=0.5)

        # ax.set_ylim(-1500, 0)
        # ax.set_xlim(300, 510)

        ax.ticklabel_format(axis='x', style='sci', scilimits=(0, 1))
        ax.xaxis.get_offset_text().set_fontsize(8)
        ax.tick_params(labelsize=8)

        ax.set_xlabel('conductivity', fontsize=8)
        ax.set_ylabel('depth (m)', fontsize=8)
        ax.set_title('Conducitivity of caisng', fontsize=10)

        ax.grid()
        fig.savefig(os.path.join(savePath, '%05d' % i + "casing_profile.png"), dpi=300, bbox_inches='tight')


def target_generator(data, num_segments, Maxdepth, miniSize):
    length_of_vector = (0 - Maxdepth) / miniSize + 1
    print('miniSize is %.2fm, target value length is %d (%d)' %(miniSize, length_of_vector, length_of_vector - 1))
    depths = np.linspace(0, Maxdepth, int(length_of_vector))
    target_data = []
    for i in range(np.size(data)):
        casingCon = np.empty_like(depths)
        for j in range(num_segments[i + 1, 0]-1, -1, -1):
            casingCon_nodes = data[i][0][:, 6]
            casingCon[np.where(depths >= data[i][0][j, 5])] = casingCon_nodes[j]
        casingCon = casingCon[0:-1]
        target_data.append(casingCon)
    return target_data


def main():
    parser = argparse.ArgumentParser(description='python code plotting casing conductivity profiles for check',
                                     epilog="Created in 02/15/2020, last modified in 02/25/2020 by Yinchu Li")
    parser.add_argument("filename", help="please input data file")
    # 2 ways: 1. with path; 2. without path
    parser.add_argument("-s", "--save", action="store_true",
                        help="save all or not")
    parser.add_argument("-op", "--outputPATH", type=str,
                        help="the path to put the profile images, default saving path is ./profiles")
    parser.add_argument("-g", "--generationPATH", type=str,
                        help="the path to put the target data, default saveing path is ./labels")
    args = parser.parse_args()

    dataPATH = os.path.abspath(args.filename)
    print("Data path is: " + dataPATH)
    data = loadmat(dataPATH)["C"]
    target_data = data[1:]
    print('Total number of samples: %d' % (np.size(target_data)))
    Maxdepth = min(data[0][0][:, 5])
    print('Max depth is: %.2fm' % Maxdepth)

    if args.generationPATH is not None:
        num_segments = loadmat(dataPATH)["num_segments"]
        train_target = target_generator(data=target_data,
                                        num_segments=num_segments,
                                        Maxdepth=Maxdepth,
                                        miniSize=10)
        targetPath = os.path.join(os.path.abspath(args.generationPATH), 'labels')
        print('target path is :', targetPath)
        if not os.path.isdir(targetPath):
            os.makedirs(targetPath)
        # print(np.shape(train_target))
        # print(np.shape(train_target[0]))
        np.save(os.path.join(targetPath, 'train_target'), train_target)

    if args.save:
        if args.outputPATH is not None:
            savePath = os.path.abspath(args.outputPATH)
            if not os.path.isdir(savePath):
                os.makedirs(savePath)
            plot_casing_prof(images_range=np.size(data),
                             data=data,
                             savePath=savePath)
        else:
            savePath = os.path.join(os.getcwd(), 'casing_Con_profiles')
            if not os.path.isdir(savePath):
                os.makedirs(savePath)
            plot_casing_prof(images_range=np.size(data),
                             data=data,
                             savePath=savePath)


if __name__ == "__main__":
    main()
