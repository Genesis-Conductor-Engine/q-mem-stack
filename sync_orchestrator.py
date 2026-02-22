#!/usr/bin/env python3
"""
Q-Mem Sync Orchestrator
Monitors LLM server and Redis cache health, logs system status
"""

import os
import time
import json
import logging
from datetime import datetime

import redis
import requests
import subprocess

logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s [%(levelname)s] %(message)s',
    datefmt='%Y-%m-%d %H:%M:%S'
)
logger = logging.getLogger(__name__)

LLM_HOST = os.getenv('LLM_HOST', 'localhost')
LLM_PORT = int(os.getenv('LLM_PORT', 8080))
REDIS_HOST = os.getenv('REDIS_HOST', 'localhost')
REDIS_PORT = int(os.getenv('REDIS_PORT', 6379))

CHECK_INTERVAL = 30  # seconds

# Use a session for connection pooling
llm_session = requests.Session()


def check_llm_health():
    """Check LLM server health"""
    try:
        resp = llm_session.get(f'http://{LLM_HOST}:{LLM_PORT}/health', timeout=5)
        return resp.status_code == 200
    except Exception as e:
        logger.error(f"LLM health check failed: {e}")
        return False


def check_redis_health(r):
    """Check Redis health and return memory info"""
    try:
        r.ping()
        info = r.info('memory')
        return {
            'healthy': True,
            'used_memory': info.get('used_memory_human', 'unknown'),
            'maxmemory': info.get('maxmemory_human', 'unknown'),
            'keys': r.dbsize()
        }
    except Exception as e:
        logger.error(f"Redis health check failed: {e}")
        return {'healthy': False}


def get_gpu_stats():
    """Get GPU stats via nvidia-smi (if available)"""
    try:
        result = subprocess.run(
            ['nvidia-smi', '--query-gpu=utilization.gpu,memory.used,memory.total,temperature.gpu',
             '--format=csv,noheader,nounits'],
            capture_output=True, text=True, timeout=5
        )
        if result.returncode == 0:
            parts = result.stdout.strip().split(', ')
            return {
                'gpu_util': f"{parts[0]}%",
                'vram_used': f"{parts[1]}MB",
                'vram_total': f"{parts[2]}MB",
                'temp': f"{parts[3]}C"
            }
    except Exception:
        pass
    return None


def main():
    logger.info("Q-Mem Sync Orchestrator starting...")
    logger.info(f"LLM Server: {LLM_HOST}:{LLM_PORT}")
    logger.info(f"Redis Cache: {REDIS_HOST}:{REDIS_PORT}")
    
    # Wait for services to start
    time.sleep(10)
    
    r = redis.Redis(host=REDIS_HOST, port=REDIS_PORT, decode_responses=True)
    
    while True:
        status = {
            'timestamp': datetime.now().isoformat(),
            'llm': {'healthy': check_llm_health()},
            'redis': check_redis_health(r),
            'gpu': get_gpu_stats()
        }
        
        # Log status
        llm_status = "UP" if status['llm']['healthy'] else "DOWN"
        redis_status = "UP" if status['redis']['healthy'] else "DOWN"
        
        log_msg = f"LLM: {llm_status} | Redis: {redis_status}"
        
        if status['redis']['healthy']:
            log_msg += f" (mem: {status['redis']['used_memory']}, keys: {status['redis']['keys']})"
        
        if status['gpu']:
            log_msg += f" | GPU: {status['gpu']['gpu_util']} util, {status['gpu']['vram_used']}/{status['gpu']['vram_total']} VRAM, {status['gpu']['temp']}"
        
        if status['llm']['healthy'] and status['redis']['healthy']:
            logger.info(log_msg)
        else:
            logger.warning(log_msg)
        
        # Store status in Redis for external access
        try:
            r.set('q-mem:status', json.dumps(status), ex=60)
        except Exception:
            pass
        
        time.sleep(CHECK_INTERVAL)


if __name__ == '__main__':
    main()
