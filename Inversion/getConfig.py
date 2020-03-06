import configparser


def get_config(config_file='config.ini'):
    parser = configparser.ConfigParser()
    parser.read(config_file)

    _conf_ints = [(key, int(value)) for key, value in parser.items('ints')]
    _conf_floats = [(key, float(value)) for key, value in parser.items('floats')]
    _conf_strings = [(key, str(value)) for key, value in parser.items('strings')]
    _conf_booleans = [(key, bool(value)) for key, value in parser.items('boolean')]

    return dict(_conf_ints + _conf_floats + _conf_strings + _conf_booleans)
