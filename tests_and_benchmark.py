import unittest
import unittest.mock
import time
from sync_orchestrator import check_redis_health

class TestRedisHealth(unittest.TestCase):
    def test_functional_success(self):
        """Test that check_redis_health returns correct dict when redis is healthy"""
        mock_redis = unittest.mock.Mock()
        mock_redis.info.return_value = {
            'used_memory_human': '1.2M',
            'maxmemory_human': '100M'
        }
        mock_redis.dbsize.return_value = 42

        result = check_redis_health(mock_redis)

        self.assertTrue(result['healthy'])
        self.assertEqual(result['used_memory'], '1.2M')
        self.assertEqual(result['keys'], 42)

    def test_functional_failure(self):
        """Test that check_redis_health returns healthy: False on exception"""
        mock_redis = unittest.mock.Mock()
        mock_redis.info.side_effect = Exception("Connection Error")

        # If ping is still there, it might fail first, which is also fine.
        mock_redis.ping.side_effect = Exception("Connection Error")

        result = check_redis_health(mock_redis)
        self.assertFalse(result['healthy'])

    def test_benchmark_performance(self):
        """Benchmark the execution time of check_redis_health"""
        mock_redis = unittest.mock.Mock()

        # Simulate 10ms latency per call
        def network_delay(*args, **kwargs):
            time.sleep(0.01)
            return True

        def info_delay(*args, **kwargs):
            time.sleep(0.01)
            return {
                'used_memory_human': '1.2M',
                'maxmemory_human': '100M'
            }

        def dbsize_delay(*args, **kwargs):
            time.sleep(0.01)
            return 100

        mock_redis.ping.side_effect = network_delay
        mock_redis.info.side_effect = info_delay
        mock_redis.dbsize.side_effect = dbsize_delay

        iterations = 50
        start_time = time.time()
        for _ in range(iterations):
            check_redis_health(mock_redis)
        end_time = time.time()

        avg_time = (end_time - start_time) / iterations
        print(f"\n[Benchmark] Average time per call: {avg_time:.4f}s")

if __name__ == '__main__':
    unittest.main()
