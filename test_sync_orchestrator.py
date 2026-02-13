import unittest
from unittest.mock import MagicMock
from sync_orchestrator import check_redis_health

class TestCheckRedisHealth(unittest.TestCase):
    def test_check_redis_health_success(self):
        # Mock Redis
        mock_redis = MagicMock()
        mock_pipeline = MagicMock()
        mock_redis.pipeline.return_value = mock_pipeline

        # Setup pipeline execution results
        # pipe.execute() returns [ping_result, info_dict, dbsize_int]
        mock_pipeline.execute.return_value = [
            True,
            {'used_memory_human': '1.2G', 'maxmemory_human': '2.0G'},
            1000
        ]

        # Call function
        result = check_redis_health(mock_redis)

        # Assertions
        self.assertTrue(result['healthy'])
        self.assertEqual(result['used_memory'], '1.2G')
        self.assertEqual(result['maxmemory'], '2.0G')
        self.assertEqual(result['keys'], 1000)

        # Verify pipeline calls
        mock_redis.pipeline.assert_called_once()
        mock_pipeline.ping.assert_called_once()
        mock_pipeline.info.assert_called_once_with('memory')
        mock_pipeline.dbsize.assert_called_once()
        mock_pipeline.execute.assert_called_once()

    def test_check_redis_health_failure(self):
        # Mock Redis failure
        mock_redis = MagicMock()
        mock_pipeline = MagicMock()
        mock_redis.pipeline.return_value = mock_pipeline

        # Simulate exception during execution
        mock_pipeline.execute.side_effect = Exception("Connection Error")

        # Call function
        result = check_redis_health(mock_redis)

        # Assertions
        self.assertFalse(result['healthy'])

if __name__ == '__main__':
    unittest.main()
