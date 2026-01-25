import unittest
from unittest.mock import MagicMock
import sys

# Mock pynvml before importing sync_orchestrator
sys.modules['pynvml'] = MagicMock()
import pynvml
from sync_orchestrator import get_gpu_stats

class TestGPUStats(unittest.TestCase):
    def test_get_gpu_stats_success(self):
        # Setup mocks
        pynvml.nvmlInit = MagicMock()
        pynvml.nvmlShutdown = MagicMock()

        handle = MagicMock()
        pynvml.nvmlDeviceGetHandleByIndex = MagicMock(return_value=handle)

        # Mock utilization
        util = MagicMock()
        util.gpu = 45
        pynvml.nvmlDeviceGetUtilizationRates = MagicMock(return_value=util)

        # Mock memory
        mem_info = MagicMock()
        mem_info.used = 4096 * 1024 * 1024  # 4096 MB
        mem_info.total = 8192 * 1024 * 1024 # 8192 MB
        pynvml.nvmlDeviceGetMemoryInfo = MagicMock(return_value=mem_info)

        # Mock temperature
        pynvml.nvmlDeviceGetTemperature = MagicMock(return_value=65)
        pynvml.NVML_TEMPERATURE_GPU = 0

        # Run function
        stats = get_gpu_stats()

        # Verify calls
        pynvml.nvmlInit.assert_called_once()
        pynvml.nvmlShutdown.assert_called_once()

        # Verify output format
        expected = {
            'gpu_util': '45%',
            'vram_used': '4096MB',
            'vram_total': '8192MB',
            'temp': '65C'
        }
        self.assertEqual(stats, expected)

    def test_get_gpu_stats_failure(self):
        # Setup mocks to raise exception
        pynvml.nvmlInit = MagicMock(side_effect=Exception("Driver not loaded"))

        # Run function
        stats = get_gpu_stats()

        # Verify result
        self.assertIsNone(stats)

if __name__ == '__main__':
    unittest.main()
