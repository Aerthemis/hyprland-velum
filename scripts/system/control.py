#!/usr/bin/env python3
"""Read status and make explicit system-control requests for Velum."""
import argparse
import json
import ipaddress
import math
from pathlib import Path
import shutil
import shlex
import subprocess
import sys
import urllib.request


def run(args, timeout=8, input_text=None):
    if not shutil.which(args[0]):
        return None
    try:
        return subprocess.run(args, capture_output=True, text=True, input=input_text, timeout=timeout, check=False)
    except (OSError, subprocess.TimeoutExpired):
        return None


def output(args, timeout=8):
    result = run(args, timeout)
    return result.stdout.strip() if result and result.returncode == 0 else ""


def operating_system():
    fields = {}
    try:
        for line in Path('/etc/os-release').read_text().splitlines():
            key, separator, value = line.partition('=')
            if separator and key in ('ID', 'ID_LIKE', 'NAME', 'PRETTY_NAME'):
                parsed = shlex.split(value, posix=True)
                fields[key] = parsed[0] if parsed else ''
    except (OSError, ValueError):
        pass
    return {'id': fields.get('ID', '').lower(),
            'idLike': fields.get('ID_LIKE', '').lower().split(),
            'name': fields.get('PRETTY_NAME') or fields.get('NAME') or 'Linux'}


def nmcli_fields(line):
    fields, value, escaped = [], [], False
    for character in line:
        if escaped:
            value.append(character)
            escaped = False
        elif character == '\\':
            escaped = True
        elif character == ':':
            fields.append(''.join(value))
            value = []
        else:
            value.append(character)
    if escaped:
        value.append('\\')
    fields.append(''.join(value))
    return fields


def snapshot():
    result = {'wifi': {'available': False}, 'bluetooth': {'available': False, 'reason': ''},
              'display': {'available': False}, 'power': {'available': False}}
    result['os'] = operating_system()
    wifi = output(['nmcli', '-t', '-f', 'WIFI,STATE', 'general'])
    if wifi:
        parts = nmcli_fields(wifi)
        profiles = []
        for row in output(['nmcli', '-t', '-f', 'NAME,TYPE', 'connection', 'show']).splitlines():
            profile = nmcli_fields(row)
            if len(profile) >= 2 and profile[1] in ('wifi', '802-11-wireless'):
                ssid = output(['nmcli', '-g', '802-11-wireless.ssid', 'connection', 'show', 'id', profile[0]])
                profiles.append({'name': profile[0], 'ssid': ssid})
        devices = [nmcli_fields(row) for row in output(
            ['nmcli', '-t', '-f', 'DEVICE,TYPE,STATE,CONNECTION', 'device', 'status']).splitlines()]
        ethernet = next(({'device': row[0], 'connection': row[3] if len(row) > 3 else ''}
                         for row in devices if len(row) >= 3 and row[1] == 'ethernet' and row[2].startswith('connected')), None)
        wifi_profile = next((row[3] for row in devices if len(row) >= 4 and row[1] == 'wifi' and row[2].startswith('connected')), '')
        wifi_ssid = next((profile['ssid'] for profile in profiles if profile['name'] == wifi_profile), '')
        result['wifi'] = {'available': True, 'enabled': parts[0] == 'enabled',
                          'state': parts[1] if len(parts) > 1 else 'unknown',
                          'connection': wifi_ssid,
                          'connected': bool(wifi_profile),
                          'ethernet': {'connected': bool(ethernet),
                                       'connection': ethernet['connection'] if ethernet else '',
                                       'device': ethernet['device'] if ethernet else ''},
                          'saved': [profile['name'] for profile in profiles], 'profiles': profiles,
                          'networks': []}
        if result['wifi']['enabled']:
            text = output(['nmcli', '-t', '-f', 'IN-USE,SSID,SIGNAL,SECURITY', 'device', 'wifi', 'list', '--rescan', 'no'])
            saved_ssids = {profile['ssid'] for profile in profiles if profile['ssid']}
            for row in text.splitlines():
                fields = nmcli_fields(row)
                if len(fields) < 4 or not fields[1]:
                    continue
                try:
                    signal = int(fields[2] or 0)
                except ValueError:
                    signal = 0
                result['wifi']['networks'].append({
                    'active': fields[0] == '*', 'ssid': fields[1], 'signal': signal,
                    'security': fields[3],
                    'canConnect': fields[1] in saved_ssids or fields[3] in ('', '--'),
                    'requiresPassword': fields[1] not in saved_ssids and fields[3] not in ('', '--') and '802.1x' not in fields[3].lower(),
                    'requiresEnterpriseProfile': '802.1x' in fields[3].lower() and fields[1] not in saved_ssids})
            if not result['wifi']['connection']:
                result['wifi']['connection'] = next((network['ssid'] for network in result['wifi']['networks'] if network['active']), '')
    bt = output(['bluetoothctl', 'show'])
    if bt and any(line.lstrip().startswith('Controller ') for line in bt.splitlines()):
        powered = next((line.split(':', 1)[1].strip() for line in bt.splitlines() if 'Powered:' in line), 'no') == 'yes'
        def devices(args):
            values = []
            for line in output(args).splitlines():
                fields = line.strip().removeprefix('Device ').split(' ', 1)
                if fields and len(fields[0]) == 17:
                    values.append({'address': fields[0], 'name': fields[1] if len(fields) > 1 else fields[0]})
            return values
        connected = devices(['bluetoothctl', 'devices', 'Connected'])
        paired = devices(['bluetoothctl', 'devices', 'Paired'])
        known = devices(['bluetoothctl', 'devices'])
        paired_ids = {device['address'] for device in paired}
        nearby = [device for device in known if device['address'] not in paired_ids]
        result['bluetooth'] = {'available': True, 'powered': powered,
                               'connected': connected, 'paired': paired, 'nearby': nearby}
    elif not shutil.which('bluetoothctl'):
        result['bluetooth']['reason'] = 'bluetoothctl is missing. Install the bluez-utils package.'
    else:
        result['bluetooth']['reason'] = 'No Bluetooth controller is available. Check the BlueZ service and adapter.'
    monitors = output(['hyprctl', '-j', 'monitors'])
    if monitors:
        try:
            result['display'] = {'available': True,
                                 'monitors': [{'name': monitor['name'], 'description': monitor.get('description', ''),
                                               'width': monitor.get('width', 0), 'height': monitor.get('height', 0),
                                               'refreshRate': monitor.get('refreshRate', 0),
                                               'focused': monitor.get('focused', False)}
                                              for monitor in json.loads(monitors)]}
        except (ValueError, KeyError, TypeError):
            pass
    brightness = output(['brightnessctl', '-m'])
    if brightness:
        rows = []
        for line in brightness.splitlines():
            fields = line.split(',')
            if len(fields) >= 7 and fields[3] == 'backlight':
                try: rows.append({'name': fields[0], 'brightness': int(fields[6].removesuffix('%')) / 100})
                except ValueError: pass
        result['display']['brightness'] = rows
    power_path = Path('/sys/class/power_supply')
    batteries = []
    for battery in power_path.glob('*'):
        try:
            if (battery / 'type').read_text().strip() == 'Battery':
                batteries.append({'name': battery.name, 'percentage': int((battery / 'capacity').read_text()),
                                  'state': (battery / 'status').read_text().strip()})
        except (OSError, ValueError): pass
    profile = output(['powerprofilesctl', 'get'])
    profiles = output(['powerprofilesctl', 'list'])
    if batteries or profile or profiles:
        result['power'] = {'available': bool(batteries), 'batteries': batteries,
                           'profile': profile, 'profiles': profiles}
    return result


def network_identity():
    """Identify the active NetworkManager connection and its route."""
    interface = ''
    gateway = ''
    try:
        routes = Path('/proc/net/route').read_text().splitlines()[1:]
        candidates = []
        for row in routes:
            fields = row.split()
            if len(fields) >= 8 and fields[1] == '00000000':
                flags, metric = int(fields[3], 16), int(fields[6])
                if flags & 1:
                    candidates.append((metric, fields[0], fields[2]))
        if candidates:
            _, interface, gateway = min(candidates)
    except (OSError, ValueError):
        pass
    if not interface:
        for row in output(['nmcli', '-t', '-f', 'DEVICE,TYPE,STATE,CONNECTION', 'device', 'status'], 2).splitlines():
            fields = nmcli_fields(row)
            if len(fields) >= 3 and fields[2].startswith('connected'):
                interface = fields[0]
                break
    connection = output(['nmcli', '-g', 'GENERAL.CON-UUID', 'device', 'show', interface], 2) if interface else ''
    return {'interface': interface, 'networkKey': '|'.join((interface, gateway, connection)) if interface else ''}


def network_stats():
    """Return counters and a cheap identity used to detect network changes."""
    result = {**network_identity(), 'rx': 0, 'tx': 0}
    interface = result['interface']
    if interface:
        try:
            base = Path('/sys/class/net') / interface
            result['rx'] = int((base / 'statistics/rx_bytes').read_text())
            result['tx'] = int((base / 'statistics/tx_bytes').read_text())
        except (OSError, ValueError):
            pass
    return result


def network_details():
    """Read local/public addresses once after a network identity changes."""
    result = {**network_identity(), 'lanIp': '', 'wanIp': '', 'wanError': ''}
    interface = result['interface']
    if not interface:
        result['wanError'] = 'No active network connection.'
    if interface:
        addresses = output(['ip', '-4', '-o', 'addr', 'show', 'dev', interface, 'scope', 'global'])
        for row in addresses.splitlines():
            fields = row.split()
            if 'inet' in fields:
                result['lanIp'] = fields[fields.index('inet') + 1].split('/')[0]
                break
    if interface:
        failures = []
        for endpoint in ('https://api.ipify.org', 'https://checkip.amazonaws.com'):
            try:
                request = urllib.request.Request(endpoint, headers={'User-Agent': 'Velum/1.0'})
                with urllib.request.urlopen(request, timeout=3) as response:
                    address = response.read(64).decode('ascii').strip()
                result['wanIp'] = str(ipaddress.ip_address(address))
                break
            except (OSError, UnicodeError, ValueError) as error:
                failures.append(str(error))
        if not result['wanIp']:
            result['wanError'] = 'Public IP lookup failed.'
    return result


def action(name, values, input_data=None):
    result = None
    if name == 'wifi-toggle':
        status = snapshot()['wifi']
        if status['available']:
            result = run(['nmcli', 'radio', 'wifi', 'off' if status['enabled'] else 'on'])
        else: raise RuntimeError('NetworkManager is unavailable.')
    elif name == 'wifi-scan':
        result = run(['nmcli', 'device', 'wifi', 'list', '--rescan', 'yes'], 30)
    elif name == 'bluetooth-toggle':
        status = snapshot()['bluetooth']
        if status['available']:
            result = run(['bluetoothctl', 'power', 'off' if status['powered'] else 'on'])
        else: raise RuntimeError('Bluetooth is unavailable.')
    elif name == 'bluetooth-scan':
        result = run(['bluetoothctl', '--timeout=10', 'scan', 'on'], 15)
    elif name == 'bluetooth-pair':
        mac = values[0] if values else ''
        if len(mac) != 17 or any(c not in '0123456789abcdefABCDEF:' for c in mac):
            raise ValueError('Invalid Bluetooth device address.')
        run(['bluetoothctl', 'agent', 'on'])
        result = run(['bluetoothctl', 'pair', mac], 35)
        if result and result.returncode == 0:
            run(['bluetoothctl', 'trust', mac])
    elif name == 'bluetooth-remove':
        mac = values[0] if values else ''
        if len(mac) != 17 or any(c not in '0123456789abcdefABCDEF:' for c in mac):
            raise ValueError('Invalid Bluetooth device address.')
        result = run(['bluetoothctl', 'remove', mac])
    elif name == 'wifi-connect':
        profile = ' '.join(values).strip()
        if not profile or len(profile) > 256 or any(c in profile for c in '\r\n\0'):
            raise ValueError('Invalid saved network profile.')
        if profile not in output(['nmcli', '-g', 'NAME', 'connection', 'show']).splitlines():
            raise ValueError('Only a previously saved network profile can be activated here.')
        result = run(['nmcli', 'connection', 'up', 'id', profile], 30)
    elif name == 'wifi-network-connect':
        ssid = ' '.join(values).strip()
        if not ssid or len(ssid) > 128 or any(character in ssid for character in '\r\n\0'):
            raise ValueError('Invalid Wi-Fi network name.')
        wifi = snapshot()['wifi']
        network = next((entry for entry in wifi.get('networks', []) if entry['ssid'] == ssid), None)
        if not network:
            raise ValueError('That Wi-Fi network is no longer visible. Scan again and retry.')
        profile = next((entry for entry in wifi.get('profiles', []) if entry['ssid'] == ssid), None)
        if profile:
            result = run(['nmcli', 'connection', 'up', 'id', profile['name']], 30)
        elif network['security'] in ('', '--'):
            result = run(['nmcli', 'device', 'wifi', 'connect', ssid], 30)
        else:
            if '802.1x' in network['security'].lower():
                raise ValueError('Enterprise Wi-Fi needs a configured NetworkManager profile.')
            password = (input_data or {}).get('password', '')
            if not isinstance(password, str) or not password or len(password) > 1024 or '\0' in password or '\n' in password or '\r' in password:
                raise ValueError('Enter a valid Wi-Fi password to connect.')
            result = run(['nmcli', '--ask', 'device', 'wifi', 'connect', ssid], 40, password + '\n')
    elif name in ('bluetooth-connect', 'bluetooth-disconnect'):
        mac = values[0] if values else ''
        if len(mac) != 17 or any(c not in '0123456789abcdefABCDEF:' for c in mac):
            raise ValueError('Invalid Bluetooth device address.')
        result = run(['bluetoothctl', 'connect' if name.endswith('connect') else 'disconnect', mac])
    elif name == 'brightness':
        percent = int(values[0]) if values else -1
        if not 0 <= percent <= 100: raise ValueError('Brightness must be between 0 and 100.')
        result = run(['brightnessctl', 'set', f'{percent}%'])
    elif name == 'focus-monitor':
        monitor = values[0] if values else ''
        if not monitor or len(monitor) > 128 or any(c not in 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_.-:' for c in monitor):
            raise ValueError('Invalid monitor name.')
        result = run(['hyprctl', 'dispatch', 'focusmonitor', monitor])
    elif name == 'power-profile':
        profile = values[0] if values else ''
        if profile not in ('power-saver', 'balanced', 'performance'):
            raise ValueError('Invalid power profile.')
        result = run(['powerprofilesctl', 'set', profile])
    elif name == 'session-power':
        operation = values[0] if values else ''
        commands = {
            'lock': ['hyprlock'],
            'suspend': ['systemctl', 'suspend'],
            'logout': ['hyprctl', 'dispatch', 'exit'],
            'reboot': ['systemctl', 'reboot'],
            'poweroff': ['systemctl', 'poweroff'],
        }
        if operation not in commands:
            raise ValueError('Unknown session power action.')
        result = run(commands[operation], 30)
    else:
        raise ValueError('Unknown system control.')
    if result is None:
        raise RuntimeError('Required system service or command is unavailable.')
    if result.returncode:
        raise RuntimeError(result.stderr.strip() or 'The system control failed.')
    return {'action': name, 'message': result.stdout.strip() or 'Updated.'}


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('command', choices=['snapshot', 'network', 'network-details', 'action'])
    parser.add_argument('name', nargs='?')
    parser.add_argument('values', nargs='*')
    args = parser.parse_args()
    try:
        input_data = None
        if args.command == 'action' and args.name == 'wifi-network-connect':
            try:
                input_data = json.loads(sys.stdin.read() or '{}')
            except json.JSONDecodeError:
                raise ValueError('Could not read the Wi-Fi password.')
        result = (snapshot() if args.command == 'snapshot' else
                  network_stats() if args.command == 'network' else
                  network_details() if args.command == 'network-details' else
                  action(args.name, args.values, input_data))
        print(json.dumps({'ok': True, **result}))
    except (OSError, ValueError, RuntimeError) as error:
        print(json.dumps({'ok': False, 'error': str(error)}))


if __name__ == '__main__':
    main()
