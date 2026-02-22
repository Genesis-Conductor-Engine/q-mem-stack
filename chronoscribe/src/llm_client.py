import requests
import json
import logging
import os

logger = logging.getLogger(__name__)

class LLMClient:
    def __init__(self, host="localhost", port=8082):
        self.base_url = f"http://{host}:{port}"

    def check_health(self):
        try:
            resp = requests.get(f"{self.base_url}/health", timeout=5)
            return resp.status_code == 200
        except Exception as e:
            logger.error(f"LLM health check failed: {e}")
            return False

    def generate(self, prompt, max_tokens=256, temperature=0.7):
        """
        Generates text using the LLM server.
        Assumes llama.cpp server API compatibility.
        """
        url = f"{self.base_url}/completion"
        payload = {
            "prompt": prompt,
            "n_predict": max_tokens,
            "temperature": temperature,
            "stop": ["User:", "\n\n"]
        }

        try:
            response = requests.post(url, json=payload, timeout=60)
            response.raise_for_status()
            result = response.json()
            # llama.cpp server usually returns 'content' in the response json
            return result.get("content", "")
        except Exception as e:
            logger.error(f"Generation failed: {e}")
            raise
