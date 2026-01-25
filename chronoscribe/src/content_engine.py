import uuid
import datetime
import logging
from .llm_client import LLMClient
from .db_client import DBClient

logger = logging.getLogger(__name__)

class ContentEngine:
    def __init__(self, llm_host="localhost", llm_port=8082, redis_host="localhost", redis_port=6379):
        self.llm = LLMClient(host=llm_host, port=llm_port)
        self.db = DBClient(host=redis_host, port=redis_port)

    def draft_content(self, brief, content_type="article"):
        """
        Drafts content based on a brief.
        """
        prompt = f"Write a {content_type} based on the following brief:\n\n{brief}\n\nContent:"

        try:
            generated_text = self.llm.generate(prompt)

            content_id = str(uuid.uuid4())
            metadata = {
                "id": content_id,
                "type": content_type,
                "brief": brief,
                "content": generated_text,
                "created_at": datetime.datetime.now().isoformat(),
                "status": "draft"
            }

            self.db.save_content_metadata(content_id, metadata)
            return metadata

        except Exception as e:
            logger.error(f"Failed to draft content: {e}")
            raise
