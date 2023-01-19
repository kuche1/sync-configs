#! /usr/bin/env python3

import os

FORMAT = "%.2f"

avg1, avg5, avg15 = os.getloadavg()
print(FORMAT%avg1, FORMAT%avg5, FORMAT%avg15)
