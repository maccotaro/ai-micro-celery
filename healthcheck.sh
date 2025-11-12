#!/bin/bash

# Celery Worker のヘルスチェック
celery -A app.core.celery_app inspect ping --timeout 10

if [ $? -eq 0 ]; then
  echo "Celery worker is healthy"
  exit 0
else
  echo "Celery worker is unhealthy"
  exit 1
fi
