#! /usr/bin/env python3

import os

FORMAT = "[%d]%.2f"

avg1, avg5, avg15 = os.getloadavg()
print(FORMAT % (1, avg1), FORMAT % (5, avg5), FORMAT % (15, avg15))
