#!/usr/bin/python3

import os
import psutil
import time
import logging

os.environ['DISPLAY'] = ':0.0'
os.environ['XDG_RUNTIME_DIR'] = '/run/user/1000'

logging.basicConfig(filename='execution.log', level=logging.INFO, 
                    format='%(asctime)s %(message)s', datefmt='%m/%d/%Y %I:%M:%S %p')

def check_battery():
    battery = psutil.sensors_battery()
    plugged = battery.power_plugged
    percent = battery.percent

    logging.info(f'Battery percent: {percent}, Plugged in: {plugged}')

    if percent < 95 and not plugged:
        os.system('/usr/bin/mpg123 -q /home/alex/alarm2.mp3')
        #os.system('/usr/bin/mplayer -really-quiet alarm2.mp3')
        #os.system('/usr/bin/cvlc alarm2.mp3')
        logging.warning('Battery level below 80% and not plugged in. Alarm triggered.')

if __name__ == "__main__":
    check_battery()
