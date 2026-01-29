import unittest
import json
from unittest.mock import MagicMock, patch
import sys
import fakeredis

# Mock pynvml globally to avoid import errors if AetherQERA or SyncOrchestrator touches it
sys.modules['pynvml'] = MagicMock()

# Import the app (which initializes everything)
# We need to mock Redis connection in agent_gateway before importing
with patch('redis.Redis', return_value=MagicMock()):
    from agent_gateway import app, submit_manifest

class TestAgentGateway(unittest.TestCase):
    def setUp(self):
        self.app = app.test_client()
        self.app.testing = True

        # Setup FakeRedis
        self.fake_redis = fakeredis.FakeRedis(decode_responses=True)
        # Patch the 'r' object in agent_gateway module
        patcher = patch('agent_gateway.r', self.fake_redis)
        self.mock_redis = patcher.start()
        self.addCleanup(patcher.stop)

    def test_health(self):
        response = self.app.get('/health')
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.json['status'], 'ok')

    def test_submit_manifest_success(self):
        # 1. Seed Redis with Cluster Status
        status = {
            'gpu': {
                'gpu_util': '45%',
                'vram_used': '4096MB',
                'vram_total': '8192MB',
                'temp': '65C'
            }
        }
        self.fake_redis.set('q-mem:status', json.dumps(status))

        # 2. Submit Manifest
        manifest = {
            "agent_id": "agent-007",
            "priority": "standard",
            "constraints": {
                "min_vram_mb": 2048
            }
        }

        response = self.app.post('/submit_manifest',
                                 data=json.dumps(manifest),
                                 content_type='application/json')

        # 3. Verify
        self.assertEqual(response.status_code, 200)
        data = response.json
        self.assertEqual(data['decision'], 'APPROVED')
        self.assertIn('placement', data)

    def test_submit_manifest_rejected_resources(self):
        # 1. Seed Redis (High Usage)
        status = {
            'gpu': {
                'gpu_util': '95%', # High util
                'vram_used': '7000MB',
                'vram_total': '8192MB',
                'temp': '80C'
            }
        }
        self.fake_redis.set('q-mem:status', json.dumps(status))

        # 2. Submit Manifest (Standard Priority)
        manifest = {
            "agent_id": "agent-std",
            "priority": "standard", # Should fail > 70%
            "constraints": {
                "min_vram_mb": 500
            }
        }

        response = self.app.post('/submit_manifest',
                                 data=json.dumps(manifest),
                                 content_type='application/json')

        self.assertEqual(response.status_code, 202) # Queued/Deferred (since it's not a hard VRAM fail, just util)

        data = response.json
        self.assertEqual(data['decision'], 'QUEUED')

    def test_submit_manifest_rejected_vram(self):
        status = {
            'gpu': {
                'gpu_util': '10%',
                'vram_used': '8000MB',
                'vram_total': '8192MB', # Only 192MB free
                'temp': '40C'
            }
        }
        self.fake_redis.set('q-mem:status', json.dumps(status))

        manifest = {
            "agent_id": "agent-fat",
            "priority": "critical",
            "constraints": {
                "min_vram_mb": 1000 # Needs 1000MB
            }
        }

        response = self.app.post('/submit_manifest',
                                 data=json.dumps(manifest),
                                 content_type='application/json')

        self.assertEqual(response.status_code, 400)
        data = response.json
        self.assertEqual(data['decision'], 'REJECTED')
        self.assertIn('Insufficient VRAM', data['reason'])

if __name__ == '__main__':
    unittest.main()
