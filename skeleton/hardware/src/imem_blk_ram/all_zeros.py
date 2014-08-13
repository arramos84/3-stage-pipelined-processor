#!/usr/bin/python

import random
import os


file = open('all_zeros.coe', 'w')

loops = 4096

file.write('memory_initialization_radix=16;' + '\n');
file.write('memory_initialization_vector=' + '\n');

for i in range(loops):
  file.write('00000000' + '\n')

file.write(';')

