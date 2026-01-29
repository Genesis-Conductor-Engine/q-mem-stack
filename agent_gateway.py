import os
import json
import logging
import redis
from flask import Flask, request, jsonify
from aether_qera import AetherQERA

# Configuration
REDIS_HOST = os.getenv('REDIS_HOST', 'localhost')
REDIS_PORT = int(os.getenv('REDIS_PORT', 6379))
PORT = int(os.getenv('PORT', 5000))

# Logging setup
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s [%(levelname)s] %(message)s'
)
logger = logging.getLogger(__name__)

app = Flask(__name__)
qera = AetherQERA()

# Redis connection
try:
    r = redis.Redis(host=REDIS_HOST, port=REDIS_PORT, decode_responses=True)
    r.ping()
    logger.info(f"Connected to Redis at {REDIS_HOST}:{REDIS_PORT}")
except Exception as e:
    logger.error(f"Failed to connect to Redis: {e}")
    r = None

@app.route('/health', methods=['GET'])
def health():
    return jsonify({"status": "ok", "service": "Genesis Agent API Gateway"})

@app.route('/submit_manifest', methods=['POST'])
def submit_manifest():
    """
    Receives an Agent Manifest and requests arbitration.
    """
    manifest = request.json
    if not manifest:
        return jsonify({"error": "Missing JSON body"}), 400

    agent_id = manifest.get('agent_id')
    if not agent_id:
        return jsonify({"error": "Missing agent_id in manifest"}), 400

    logger.info(f"Received manifest for Agent {agent_id}")

    # 1. Fetch Cluster Status
    cluster_status = {}
    if r:
        try:
            status_json = r.get('q-mem:status')
            if status_json:
                cluster_status = json.loads(status_json)
            else:
                logger.warning("No cluster status found in Redis (q-mem:status)")
        except Exception as e:
            logger.error(f"Error reading from Redis: {e}")
    else:
        logger.error("Redis not available")

    # 2. Arbitrate
    result = qera.optimize_placement(manifest, cluster_status)

    # 3. Respond
    # In a real system, this might trigger the 'GKE Scheduling Enforcer' webhook.
    # Here we return the decision to the caller.

    response_code = 200
    if result['decision'] in ['REJECTED', 'ERROR']:
        response_code = 400 # Or 409 Conflict, or 503 Service Unavailable depending on logic
    elif result['decision'] == 'QUEUED':
        response_code = 202 # Accepted (but processing/queued)

    return jsonify(result), response_code

if __name__ == '__main__':
    logger.info("Starting Genesis Agent API Gateway...")
    app.run(host='0.0.0.0', port=PORT)
