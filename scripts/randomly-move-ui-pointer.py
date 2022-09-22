#!/usr/bin/env python3

import pyautogui
import random
import time

try:
    while True:
        for i in range(1, random.randint(1, 9), 1):
            pyautogui.moveRel(random.randint(-100, 100), random.randint(-100, 100))
            time.sleep(random.random())
        time.sleep(random.randint(1, 4))
except KeyboardInterrupt: pass
