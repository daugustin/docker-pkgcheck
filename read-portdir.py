#!/usr/bin/env python3

import configparser
import sys

config = configparser.ConfigParser()
config.read(sys.argv[1])
print(config['gentoo']['location'])
