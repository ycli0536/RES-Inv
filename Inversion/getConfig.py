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
args = parser.parse_args()

config_file = args.filename

gConfig = {}
gConfig = get_config(config_file=config_file)
