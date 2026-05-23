FROM python:3.12-slim

WORKDIR /app

# Install dependencies first (layer-cached unless requirements.txt changes)
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application source
COPY . .

ENV PYTHONUNBUFFERED=1
ENV PORT=8080

# Cloud Run sends requests to $PORT; keep-alive must exceed the pipeline timeout (~5 min)
CMD ["uvicorn", "api_server:app", "--host", "0.0.0.0", "--port", "8080", "--timeout-keep-alive", "660"]
