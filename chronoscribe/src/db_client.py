import redis
import logging
import json
import os

logger = logging.getLogger(__name__)

class DBClient:
    def __init__(self, host="localhost", port=6379, db=0):
        self.r = redis.Redis(host=host, port=port, db=db, decode_responses=True)

    def check_health(self):
        try:
            return self.r.ping()
        except Exception as e:
            logger.error(f"Redis health check failed: {e}")
            return False

    def save_content_metadata(self, content_id, metadata):
        """
        Saves content metadata to Redis.
        """
        key = f"content:{content_id}"
        try:
            self.r.set(key, json.dumps(metadata))
            return True
        except Exception as e:
            logger.error(f"Failed to save content metadata: {e}")
            raise

    def get_content_metadata(self, content_id):
        """
        Retrieves content metadata from Redis.
        """
        key = f"content:{content_id}"
        try:
            data = self.r.get(key)
            if data:
                return json.loads(data)
            return None
        except Exception as e:
            logger.error(f"Failed to get content metadata: {e}")
            raise
