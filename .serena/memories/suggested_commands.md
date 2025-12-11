# Suggested Commands for ai-micro-celery

## Development

```bash
# Install dependencies
pip install -r requirements.txt

# Run worker (development)
celery -A app.core.celery_app worker --loglevel=info --pool=threads --concurrency=4

# Run beat scheduler
celery -A app.core.celery_app beat --loglevel=info
```

## Docker Commands (WSL2 + GPU)

```bash
# Start
docker compose up -d

# View logs
docker compose logs -f celery-worker

# Restart
docker compose restart

# Stop
docker compose down
```

## Docker Commands (M3 Mac)

```bash
# Start
docker compose -f docker-compose.mac.yml up -d

# View logs
docker compose -f docker-compose.mac.yml logs -f celery-worker

# Restart
docker compose -f docker-compose.mac.yml restart
```

## Troubleshooting

```bash
# Check worker status
docker exec ai-micro-celery-worker celery -A app.core.celery_app inspect active

# Manual health check
docker exec ai-micro-celery-worker /app/healthcheck.sh

# Check GPU (WSL2)
docker exec ai-micro-celery-worker python -c "import torch; print(torch.cuda.is_available())"

# Check Tesseract
docker exec ai-micro-celery-worker tesseract --version
```
