# -*- coding: utf-8 -*-
"""
Created on Feb 2020
@author: Yinchu Li (11849188@mail.sustech.edu.cn)
"""

##########################################
########        INI READER        ########
##########################################


import configparser
import argparse


def get_config(config_file):
    parser = configparser.ConfigParser()
    parser.read(config_file)

    _conf_ints = [(key, int(value)) for key, value in parser.items('ints')]
    _conf_floats = [(key, float(value)) for key, value in parser.items('floats')]
    _conf_strings = [(key, str(value)) for key, value in parser.items('strings')]
    _conf_booleans = [(key, bool(value)) for key, value in parser.items('boolean')]

    return dict(_conf_ints + _conf_floats + _conf_strings + _conf_booleans)


parser = argparse.ArgumentParser(description='read config.ini')
parser.add_argument("filename", help="please input config file")
parser.add_argument("mode", help="please select the mode: training or prediction")
args = parser.parse_args()

config_file = args.filename
mode = args.mode

gConfig = {}
gConfig = get_config(config_file=config_file)
