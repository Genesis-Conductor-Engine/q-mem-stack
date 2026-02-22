import unittest
from unittest.mock import patch, MagicMock
from chronoscribe.src.content_engine import ContentEngine

class TestContentEngine(unittest.TestCase):
    @patch('chronoscribe.src.content_engine.LLMClient')
    @patch('chronoscribe.src.content_engine.DBClient')
    def test_draft_content(self, MockDBClient, MockLLMClient):
        # Setup mocks
        mock_llm = MockLLMClient.return_value
        mock_llm.generate.return_value = "Drafted Article Content"

        mock_db = MockDBClient.return_value

        engine = ContentEngine()
        result = engine.draft_content("Test brief", "article")

        # Verify result
        self.assertEqual(result['content'], "Drafted Article Content")
        self.assertEqual(result['brief'], "Test brief")
        self.assertEqual(result['type'], "article")
        self.assertEqual(result['status'], "draft")

        # Verify interactions
        mock_llm.generate.assert_called_once()
        mock_db.save_content_metadata.assert_called_once()
