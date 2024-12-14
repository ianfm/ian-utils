#!/usr/bin/env python

"""
This example shows how listening works.
"""

import can

def listen():
    with can.Bus() as bus:
        for msg in bus:
            print(msg.data)
        

if __name__ == "__main__":
    listen()