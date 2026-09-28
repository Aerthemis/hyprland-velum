#!/usr/bin/env python3
"""Read-only Linux metrics and opt-in Open-Meteo weather. No shell commands."""
import argparse
import json
import math
import os
from pathlib import Path
import shutil
import time
import urllib.parse
import urllib.request


def metrics(proc=Path('/proc'), sys=Path('/sys')):
    # Linux guest time is already included in user/nice; do not count it twice.
    cpu = list(map(int, (proc / 'stat').read_text().splitlines()[0].split()[1:9]))
    memory = {}
    for line in (proc / 'meminfo').read_text().splitlines():
        key, value = line.split(':', 1)
        memory[key] = int(value.split()[0]) * 1024
    disks = []
    for path in dict.fromkeys(['/', str(Path.home())]):
        usage = shutil.disk_usage(path)
        disks.append(dict(path=path, total=usage.total, used=usage.used))
    network = {'rx': 0, 'tx': 0}
    for line in (proc / 'net/dev').read_text().splitlines()[2:]:
        name, values = line.split(':', 1)
        if name.strip() != 'lo':
            fields = values.split()
            network['rx'] += int(fields[0])
            network['tx'] += int(fields[8])
    temperatures = []
    for sensor in (sys / 'class/thermal').glob('thermal_zone*'):
        try:
            value = int((sensor / 'temp').read_text()) / 1000
            if -20 <= value <= 150:
                temperatures.append({'name': (sensor / 'type').read_text().strip(), 'value': value})
        except (OSError, ValueError):
            pass
    return dict(time=time.monotonic(), cpuTotal=sum(cpu), cpuIdle=cpu[3] + cpu[4],
                memoryTotal=memory['MemTotal'], memoryUsed=memory['MemTotal'] - memory['MemAvailable'],
                swapTotal=memory.get('SwapTotal', 0),
                swapUsed=memory.get('SwapTotal', 0) - memory.get('SwapFree', 0),
                uptime=float((proc / 'uptime').read_text().split()[0]),
                load=os.getloadavg(), disks=disks, network=network, temperatures=temperatures)


def get_json(url, params):
    request = urllib.request.Request(url + '?' + urllib.parse.urlencode(params),
                                     headers={'User-Agent': 'Velum/0.1'})
    with urllib.request.urlopen(request, timeout=12) as response:
        return json.load(response)


def search(city):
    if len(city.strip()) < 2:
        raise ValueError('Enter at least two letters of a city name.')
    data = get_json('https://geocoding-api.open-meteo.com/v1/search',
                    {'name': city.strip(), 'count': 5, 'language': 'en', 'format': 'json'})
    return {'locations': [dict(latitude=x['latitude'], longitude=x['longitude'],
                               name=', '.join(filter(None, [x['name'], x.get('admin1'), x.get('country')])))
                           for x in data.get('results', [])]}


def validate_location(location):
    lat, lon = float(location['latitude']), float(location['longitude'])
    if not math.isfinite(lat) or not math.isfinite(lon) or not -90 <= lat <= 90 or not -180 <= lon <= 180:
        raise ValueError('Invalid weather coordinates.')
    name = str(location['name']).strip()
    if not name or len(name) > 300:
        raise ValueError('Invalid location name.')
    return dict(latitude=lat, longitude=lon, name=name)


def config_path():
    return Path(os.environ.get('XDG_CONFIG_HOME', Path.home() / '.config')) / 'velum/weather.json'


def forecast(location):
    location = validate_location(location)
    data = get_json('https://api.open-meteo.com/v1/forecast', {
        'latitude': location['latitude'], 'longitude': location['longitude'],
        'current': 'temperature_2m,apparent_temperature,relative_humidity_2m,weather_code,wind_speed_10m',
        'daily': 'weather_code,temperature_2m_max,temperature_2m_min,precipitation_probability_max',
        'timezone': 'auto', 'forecast_days': 5})
    return dict(location=location, current=data['current'], daily=data['daily'], fetched=time.time())


def weather(location=None):
    path = config_path()
    if location is None:
        if not path.exists():
            return {'configured': False}
        location = validate_location(json.loads(path.read_text()))
    else:
        location = validate_location(location)
        path.parent.mkdir(parents=True, exist_ok=True)
        temporary = path.with_name('weather.json.' + str(os.getpid()) + '.tmp')
        try:
            temporary.write_text(json.dumps(location) + '\n')
            temporary.chmod(0o600)
            temporary.replace(path)
        finally:
            temporary.unlink(missing_ok=True)
    return {'configured': True, **forecast(location)}


def main():
    parser = argparse.ArgumentParser()
    group = parser.add_mutually_exclusive_group(required=True)
    group.add_argument('--stats', action='store_true')
    group.add_argument('--weather', action='store_true')
    group.add_argument('--search')
    group.add_argument('--location', nargs=3, metavar=('LAT', 'LON', 'NAME'))
    args = parser.parse_args()
    try:
        if args.stats:
            result = metrics()
        elif args.search is not None:
            result = search(args.search)
        elif args.location:
            lat, lon, name = args.location
            result = weather(dict(latitude=lat, longitude=lon, name=name))
        else:
            result = weather()
        print(json.dumps({'ok': True, **result}), flush=True)
    except (OSError, ValueError, KeyError, TypeError) as error:
        print(json.dumps({'ok': False, 'error': str(error)}), flush=True)


if __name__ == '__main__':
    main()
