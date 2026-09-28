import importlib.util
import json
import os
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch

HELPER = Path(__file__).resolve().parents[2] / 'scripts/dashboard/data.py'
spec = importlib.util.spec_from_file_location('dashboard_data', HELPER)
data = importlib.util.module_from_spec(spec)
spec.loader.exec_module(data)


class DashboardDataTests(unittest.TestCase):
    def test_stats_guest_time_not_double_counted_and_loopback_excluded(self):
        with tempfile.TemporaryDirectory() as folder:
            proc = Path(folder)
            (proc / 'net').mkdir()
            (proc / 'stat').write_text('cpu 100 10 20 300 40 5 6 7 50 4\n')
            (proc / 'meminfo').write_text('MemTotal: 1000 kB\nMemAvailable: 400 kB\nSwapTotal: 100 kB\nSwapFree: 70 kB\n')
            (proc / 'uptime').write_text('1234.5 9876.0')
            (proc / 'net/dev').write_text('header\nheader\nlo: 500 0 0 0 0 0 0 0 500\neth0: 100 0 0 0 0 0 0 0 200\n')
            result = data.metrics(proc, proc / 'missing-sys')
            self.assertEqual(result['cpuTotal'], 488)
            self.assertEqual(result['cpuIdle'], 340)
            self.assertEqual(result['memoryUsed'], 600 * 1024)
            self.assertEqual(result['swapUsed'], 30 * 1024)
            self.assertEqual(result['network'], {'rx': 100, 'tx': 200})
            self.assertEqual(result['temperatures'], [])

    def test_unconfigured_weather_does_not_use_network(self):
        with tempfile.TemporaryDirectory() as folder, patch.dict(os.environ, {'XDG_CONFIG_HOME': folder}), patch.object(data, 'get_json') as request:
            self.assertEqual(data.weather(), {'configured': False})
            request.assert_not_called()

    def test_location_saved_privately_and_reused(self):
        location = {'latitude': 48.8, 'longitude': 2.3, 'name': 'Example city'}
        with tempfile.TemporaryDirectory() as folder, patch.dict(os.environ, {'XDG_CONFIG_HOME': folder}), patch.object(data, 'forecast', return_value={'current': {}, 'daily': {}}) as forecast:
            data.weather(location)
            self.assertEqual(json.loads(data.config_path().read_text()), location)
            self.assertEqual(data.config_path().stat().st_mode & 0o777, 0o600)
            data.weather()
            forecast.assert_called_with(location)

    def test_invalid_coordinates_rejected_before_network(self):
        with patch.object(data, 'get_json') as request:
            for lat, lon in [(91, 0), (0, 181), (float('nan'), 0), (0, float('inf'))]:
                with self.assertRaises(ValueError):
                    data.forecast({'latitude': lat, 'longitude': lon, 'name': 'Invalid'})
            request.assert_not_called()

    def test_search_disambiguates_city_and_handles_no_results(self):
        with patch.object(data, 'get_json', return_value={'results': [{'name': 'Paris', 'admin1': 'Texas', 'country': 'United States', 'latitude': 33.6, 'longitude': -95.5}]}):
            self.assertEqual(data.search('Paris')['locations'][0]['name'], 'Paris, Texas, United States')
        with patch.object(data, 'get_json', return_value={}):
            self.assertEqual(data.search('Nowhere'), {'locations': []})

    def test_corrupt_config_does_not_use_network(self):
        with tempfile.TemporaryDirectory() as folder, patch.dict(os.environ, {'XDG_CONFIG_HOME': folder}), patch.object(data, 'get_json') as request:
            path = data.config_path()
            path.parent.mkdir()
            path.write_text('not json')
            with self.assertRaises(ValueError):
                data.weather()
            request.assert_not_called()


if __name__ == '__main__':
    unittest.main()
