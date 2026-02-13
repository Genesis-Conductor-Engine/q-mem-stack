import unittest
from unittest.mock import patch, MagicMock
import sys

# Mock pynvml module before importing sync_orchestrator
mock_pynvml = MagicMock()
sys.modules['pynvml'] = mock_pynvml

import sync_orchestrator

class TestSyncOrchestrator(unittest.TestCase):

    def setUp(self):
        # Reset the mock pynvml completely
        mock_pynvml.reset_mock()
        mock_pynvml.nvmlInit.side_effect = None
        mock_pynvml.nvmlDeviceGetHandleByIndex.side_effect = None
        # Reset return values if necessary, though new tests usually set them

        # Ensure pynvml is "installed" in the module
        sync_orchestrator.pynvml = mock_pynvml

    @patch('sync_orchestrator.subprocess.run')
    def test_get_gpu_stats_pynvml_success(self, mock_subprocess):
        """Test successful stats retrieval via pynvml"""
        # Setup mock return values
        handle = MagicMock()
        mock_pynvml.nvmlDeviceGetHandleByIndex.return_value = handle

        util_rate = MagicMock()
        util_rate.gpu = 60
        mock_pynvml.nvmlDeviceGetUtilizationRates.return_value = util_rate

        mem_info = MagicMock()
        mem_info.used = 4096 * 1024 * 1024
        mem_info.total = 8192 * 1024 * 1024
        mock_pynvml.nvmlDeviceGetMemoryInfo.return_value = mem_info

        mock_pynvml.nvmlDeviceGetTemperature.return_value = 75

        # Execute
        stats = sync_orchestrator.get_gpu_stats()

        # Verify
        self.assertIsNotNone(stats)
        self.assertEqual(stats['gpu_util'], "60%")
        self.assertEqual(stats['vram_used'], "4096MB")
        self.assertEqual(stats['vram_total'], "8192MB")
        self.assertEqual(stats['temp'], "75C")

        # Verify pynvml calls
        mock_pynvml.nvmlInit.assert_called_once()
        mock_pynvml.nvmlDeviceGetHandleByIndex.assert_called_with(0)
        mock_pynvml.nvmlShutdown.assert_called_once()

        # Ensure subprocess was NOT called
        mock_subprocess.assert_not_called()

    @patch('sync_orchestrator.subprocess.run')
    def test_get_gpu_stats_pynvml_failure_fallback(self, mock_subprocess):
        """Test fallback to subprocess if pynvml fails or is missing"""
        # Case 1: pynvml is None (import failed)
        sync_orchestrator.pynvml = None

        mock_subprocess.return_value.returncode = 0
        mock_subprocess.return_value.stdout = "30, 1024, 4096, 55"

        stats = sync_orchestrator.get_gpu_stats()

        self.assertEqual(stats['gpu_util'], "30%")
        self.assertEqual(stats['vram_used'], "1024MB")
        mock_subprocess.assert_called_once() # Should fall back

        # Reset for next check
        mock_subprocess.reset_mock()
        sync_orchestrator.pynvml = mock_pynvml

        # Case 2: pynvml raises exception
        mock_pynvml.nvmlInit.side_effect = Exception("NVML Error")

        mock_subprocess.return_value.stdout = "30, 1024, 4096, 55"

        stats = sync_orchestrator.get_gpu_stats()

        self.assertEqual(stats['gpu_util'], "30%")
        mock_subprocess.assert_called_once()

if __name__ == '__main__':
    unittest.main()
