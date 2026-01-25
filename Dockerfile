FROM python:3.11-slim

WORKDIR /app

RUN pip install --no-cache-dir redis requests nvidia-ml-py

COPY sync_orchestrator.py .

CMD ["python", "-u", "sync_orchestrator.py"]
