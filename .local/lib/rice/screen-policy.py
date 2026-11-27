#!/usr/bin/python3
"""60 Hz on battery, 240 Hz on AC; discover the current Hyprland session."""
import json
import os
import subprocess
import time
from pathlib import Path

last_error = None
while True:
    try:
        instances = json.loads(subprocess.check_output(['hyprctl', '-j', 'instances'], text=True, stderr=subprocess.DEVNULL))
        instances = [i for i in instances if Path('/proc', str(i['pid'])).exists()]
        if not instances:
            time.sleep(5)
            continue
        instance = max(instances, key=lambda i: i['time'])['instance']
        command = ['hyprctl', '--instance', instance]
        supplies = Path('/sys/class/power_supply')
        plugged = any(p.read_text().strip() == '1' for p in supplies.glob('*/online'))
        battery = not plugged and any(p.read_text().strip() == 'Discharging' for p in supplies.glob('BAT*/status'))
        rate = 60 if battery else 240
        monitors = json.loads(subprocess.check_output(command + ['-j', 'monitors'], text=True, stderr=subprocess.DEVNULL))
        panel = next((m for m in monitors if m['name'] == 'eDP-1'), None)
        if panel and abs(panel['refreshRate'] - rate) > 1:
            rule = {'output':'eDP-1', 'mode':f"2560x1600@{rate}", 'position':f"{panel['x']}x{panel['y']}", 'scale':panel['scale']}
            fields = ', '.join(k + ' = ' + json.dumps(v) for k, v in rule.items())
            result = subprocess.run(command + ['repl', 'hl.monitor({ ' + fields + ' })'], text=True, capture_output=True, check=True)
            print(f"{'Battery' if battery else 'AC'}: {rate} Hz: {result.stdout.strip()}", flush=True)
        last_error = None
    except (OSError, ValueError, KeyError, subprocess.SubprocessError) as error:
        message = str(error)
        if message != last_error:
            print(message, flush=True)
            last_error = message
    time.sleep(10)
