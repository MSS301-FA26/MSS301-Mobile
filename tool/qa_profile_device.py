"""Local Plan 02 UI driver; accepts JSON on stdin and never prints field values."""
import json
import os
import re
import shlex
import subprocess
import sys
import time
import xml.etree.ElementTree as ET
from pathlib import Path

ADB = Path(os.environ['LOCALAPPDATA']) / 'Android/Sdk/platform-tools/adb.exe'


def adb(*args):
    return subprocess.check_output([str(ADB), '-s', 'emulator-5554', *args])


def nodes():
    adb('shell', 'uiautomator', 'dump', '/sdcard/plan02-ui.xml')
    return list(ET.fromstring(adb('shell', 'cat', '/sdcard/plan02-ui.xml')).iter('node'))


def tap(node):
    x1, y1, x2, y2 = map(int, re.findall(r'\d+', node.attrib['bounds']))
    adb('shell', 'input', 'tap', str((x1 + x2) // 2), str((y1 + y2) // 2))


request = json.load(sys.stdin)
action = request['action']
if action == 'inspect':
    print(json.dumps([
        {'description': n.attrib.get('content-desc'), 'bounds': n.attrib.get('bounds'),
         'editable': n.attrib.get('class') == 'android.widget.EditText'}
        for n in nodes() if n.attrib.get('content-desc') or n.attrib.get('class') == 'android.widget.EditText'
    ], ensure_ascii=False))
elif action == 'tap':
    all_nodes = nodes()
    found = [n for n in all_nodes if request['description'] == n.attrib.get('content-desc', '')]
    if not found:
        found = [n for n in all_nodes if request['description'] in n.attrib.get('content-desc', '')]
    found.sort(key=lambda n: n.attrib.get('clickable') != 'true')
    if not found:
        raise RuntimeError('UI target not found')
    tap(found[request.get('index', 0)])
    print('Tapped UI target')
elif action == 'field':
    found = [n for n in nodes() if n.attrib.get('class') == 'android.widget.EditText']
    tap(found[request['index']])
    adb('shell', 'input', 'keyevent', 'KEYCODE_MOVE_END')
    adb('shell', 'input', 'keyevent', *(['67'] * 100))
    if request['value']:
        adb('shell', 'input text ' + shlex.quote(request['value'].replace(' ', '%s')))
    adb('shell', 'input', 'keyevent', 'KEYCODE_BACK')
    print('Edited field; value omitted')
elif action == 'screenshot':
    Path(request['path']).write_bytes(adb('exec-out', 'screencap', '-p'))
    print('Saved screenshot')
elif action == 'assert':
    actual = '\n'.join(n.attrib.get('content-desc', '') + '\n' + n.attrib.get('text', '') for n in nodes())
    assert request['expected'] in actual, 'Expected UI content not found'
    print('UI assertion PASS')
elif action == 'restart':
    adb('shell', 'am', 'force-stop', 'com.example.mss301_mobile')
    adb('shell', 'am', 'start', '-n', 'com.example.mss301_mobile/.MainActivity')
    time.sleep(2)
    print('Restarted app without clearing storage')
elif action == 'scroll':
    adb('shell', 'input', 'swipe', '540', '1850', '540', '900', '350')
    print('Scrolled page')
else:
    raise RuntimeError('Unsupported action')
