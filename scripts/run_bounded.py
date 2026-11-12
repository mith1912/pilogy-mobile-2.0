#!/usr/bin/env python3
"""Bound discovery tools and terminate only their own process group on timeout."""
import os
import signal
import subprocess
import sys
try:
    process = subprocess.Popen(sys.argv[2:], stdin=subprocess.DEVNULL,
                               stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
                               text=True, start_new_session=True)
    try:
        output, _ = process.communicate(timeout=int(sys.argv[1]))
    except subprocess.TimeoutExpired:
        os.killpg(process.pid, signal.SIGKILL)
        process.communicate()
        print('FAIL: command timed out; repair this tool before building.', file=sys.stderr)
        sys.exit(124)
    print(output[-16000:], end='')
    sys.exit(process.returncode)
except OSError as error:
    print('FAIL: '+str(error), file=sys.stderr)
    sys.exit(1)
