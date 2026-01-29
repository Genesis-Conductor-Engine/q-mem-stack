FROM python:3.11-slim

WORKDIR /app

RUN pip install --no-cache-dir redis requests nvidia-ml-py flask

COPY sync_orchestrator.py .
COPY agent_gateway.py .
COPY aether_qera.py .

CMD ["python", "-u", "sync_orchestrator.py"]
