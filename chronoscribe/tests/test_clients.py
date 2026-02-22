import unittest
from unittest.mock import patch, MagicMock
from chronoscribe.src.llm_client import LLMClient
from chronoscribe.src.db_client import DBClient
import json

class TestLLMClient(unittest.TestCase):
    @patch('chronoscribe.src.llm_client.requests.get')
    def test_check_health(self, mock_get):
        mock_get.return_value.status_code = 200
        client = LLMClient()
        self.assertTrue(client.check_health())

        mock_get.return_value.status_code = 500
        self.assertFalse(client.check_health())

    @patch('chronoscribe.src.llm_client.requests.post')
    def test_generate(self, mock_post):
        mock_response = MagicMock()
        mock_response.json.return_value = {"content": "Generated text"}
        mock_post.return_value = mock_response

        client = LLMClient()
        result = client.generate("Test prompt")
        self.assertEqual(result, "Generated text")

class TestDBClient(unittest.TestCase):
    @patch('chronoscribe.src.db_client.redis.Redis')
    def test_check_health(self, mock_redis):
        mock_r = mock_redis.return_value
        mock_r.ping.return_value = True

        client = DBClient()
        self.assertTrue(client.check_health())

    @patch('chronoscribe.src.db_client.redis.Redis')
    def test_save_and_get_content(self, mock_redis):
        mock_r = mock_redis.return_value
        client = DBClient()

        metadata = {"id": "123", "content": "test"}
        client.save_content_metadata("123", metadata)
        mock_r.set.assert_called_with("content:123", json.dumps(metadata))

        mock_r.get.return_value = json.dumps(metadata)
        result = client.get_content_metadata("123")
        self.assertEqual(result, metadata)
