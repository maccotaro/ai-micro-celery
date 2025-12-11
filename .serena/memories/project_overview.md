# ai-micro-celery - Project Overview

## Purpose
Celery Worker Service handling asynchronous document processing tasks. Performs CPU/GPU-intensive operations like OCR, document parsing, and vector embedding generation.

## Tech Stack
- **Framework**: Celery 5.3.4
- **Language**: Python 3.11+
- **Document Processing**: Docling, EasyOCR, Tesseract
- **Message Broker**: Redis
- **Database**: PostgreSQL + PGVector
- **Container**: Docker with optional GPU support

## Project Structure
```
ai-micro-celery/
├── app/                         # Shared from ai-micro-api-admin
│   └── core/
│       ├── celery_app.py        # Celery application
│       └── document_processing/ # Processing logic
├── celeryconfig.py              # Celery configuration
├── healthcheck.sh               # Health check script
├── Dockerfile                   # WSL2 + NVIDIA GPU
├── Dockerfile.mac               # M3 Mac (CPU)
├── docker-compose.yml           # NVIDIA GPU
├── docker-compose.mac.yml       # M3 Mac
└── requirements.txt
```

## Task Types
1. **Document Processing**: OCR, PDF parsing, image extraction
2. **Vector Embedding**: Generate/store embeddings

## Multiplatform Support
- WSL2 + NVIDIA GPU: 12GB memory, GPU acceleration
- M3 Mac: 8GB memory, CPU optimized

## Shared Code Architecture
Shares code with ai-micro-api-admin via Docker volumes:
- `/app/app` - Application code (read-only)
- `/app/uploads` - Upload files (read-only)
