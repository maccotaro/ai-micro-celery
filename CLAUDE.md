# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is the **Celery Worker Service** that handles asynchronous document processing tasks for the microservices architecture. It performs CPU/GPU-intensive operations like OCR, document parsing, and vector embedding generation.

## Key Features

- **Asynchronous Task Processing**: Celery-based distributed task queue
- **Document Processing**: OCR, PDF parsing, image extraction using Docling
- **Vector Embedding**: Generate embeddings for RAG pipeline
- **Multi-format Support**: PDF, DOCX, images, and more
- **GPU Acceleration**: Optional NVIDIA GPU support for faster processing

## Technology Stack

- **Framework**: Celery 5.3.4
- **Language**: Python 3.11+
- **Document Processing**:
  - Docling 1.20.0 (document parsing)
  - EasyOCR 1.7.1 (optical character recognition)
  - Tesseract (OCR engine)
- **Database**: PostgreSQL via SQLAlchemy
- **Message Broker**: Redis
- **Container**: Docker

## Project Structure

```
ai-micro-celery/
├── app/                         # Shared from ai-micro-api-admin
│   └── core/
│       ├── celery_app.py        # Celery application
│       └── document_processing/ # Document processing logic
├── celeryconfig.py              # Celery configuration
├── healthcheck.sh               # Health check script
├── Dockerfile                   # WSL2 + NVIDIA GPU
├── Dockerfile.mac               # M3 Mac (CPU only)
├── docker-compose.yml           # WSL2 + NVIDIA GPU
├── docker-compose.mac.yml       # M3 Mac (CPU only)
├── requirements.txt
└── CLAUDE.md                    # This file
```

## Multiplatform Support

This service supports both **WSL2 + NVIDIA GPU** and **M3 Mac** environments with optimized configurations.

### WSL2 + NVIDIA GPU環境

**Dockerfile**: `Dockerfile` (default)
- Base Image: `python:3.11-slim`
- GPU Support: Via host NVIDIA drivers
- PyTorch: CPU version (GPU acceleration via host)
- Thread Count: 8 (optimized for multi-core)

**docker-compose.yml**:
```bash
cd ai-micro-celery
docker compose up -d
```

**Environment Variables**:
- `NVIDIA_VISIBLE_DEVICES=all`
- `NVIDIA_DRIVER_CAPABILITIES=compute,utility`
- `CUDA_HOME=/usr/local/cuda`
- `LD_LIBRARY_PATH` includes WSL2 driver paths

**GPU Resources**:
- Memory Limit: 12GB
- GPU Reservation: All available GPUs
- Capabilities: `[gpu]`

### M3 Mac環境（CPU版）

**Dockerfile**: `Dockerfile.mac`
- Base Image: `python:3.11-slim`
- ARM64 Optimized: Thread count = 2
- PyTorch: CPU version auto-selected
- TORCH_COMPILE: Disabled (0)

**docker-compose.mac.yml**:
```bash
cd ai-micro-celery
docker compose -f docker-compose.mac.yml up -d
```

**Environment Variables**:
- `TORCH_COMPILE=0` (GPU optimization disabled)
- `MKL_NUM_THREADS=2` (ARM64 optimization)
- `OMP_NUM_THREADS=2`
- `OPENBLAS_NUM_THREADS=2`

**Memory Limit**: 8GB (vs 12GB for GPU version)

## Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `DATABASE_URL` | PostgreSQL connection string | `postgresql://...` |
| `CELERY_BROKER_URL` | Redis broker URL | `redis://:password@host.docker.internal:6379/1` |
| `CELERY_RESULT_BACKEND` | Redis result backend | `redis://:password@host.docker.internal:6379/2` |
| `OLLAMA_BASE_URL` | Ollama API URL | `http://host.docker.internal:11434` |
| `EMBEDDING_MODEL` | Embedding model name | `bge-m3:567m` |
| `PYTHONPATH` | Python module path | `/app` |

## Commands

### Development

```bash
# Install dependencies
pip install -r requirements.txt

# Run worker (development)
celery -A app.core.celery_app worker --loglevel=info --pool=threads --concurrency=4

# Run beat scheduler (development)
celery -A app.core.celery_app beat --loglevel=info
```

### Docker Commands

**WSL2 + NVIDIA GPU**:
```bash
# Start worker and beat
docker compose up -d

# View logs
docker compose logs -f celery-worker

# Restart
docker compose restart

# Stop
docker compose down
```

**M3 Mac**:
```bash
# Start with Mac-specific configuration
docker compose -f docker-compose.mac.yml up -d

# View logs
docker compose -f docker-compose.mac.yml logs -f celery-worker

# Restart
docker compose -f docker-compose.mac.yml restart

# Stop
docker compose -f docker-compose.mac.yml down
```

## Task Types

### 1. Document Processing Tasks

- **OCR Processing**: Extract text from images and PDFs
- **Document Parsing**: Parse structured documents (DOCX, PDF, etc.)
- **Image Extraction**: Extract images from documents
- **Metadata Extraction**: Extract document metadata

### 2. Vector Embedding Tasks

- **Chunk Embedding**: Generate embeddings for text chunks
- **Batch Embedding**: Process multiple chunks in parallel
- **Embedding Storage**: Store embeddings in PGVector

## Architecture

### Service Communication Flow

```
Admin API (ai-micro-api-admin)
        ↓ (enqueue task)
Celery Worker (ai-micro-celery) ← This service
        ↓
[Document Processing | Embedding Generation]
        ↓
PostgreSQL (admindb) + Redis (cache)
```

### Shared Code Architecture

The Celery worker shares code with `ai-micro-api-admin` via Docker volumes:

```yaml
volumes:
  - ../ai-micro-api-admin/app:/app/app:ro
  - ../ai-micro-api-admin/uploads:/app/uploads:ro
```

This allows:
- Reusing document processing logic
- Accessing uploaded files
- Maintaining consistent business logic

## Performance Characteristics

| Environment | OCR Speed | Embedding Speed | Memory Usage |
|-------------|-----------|-----------------|--------------|
| **WSL2 + GPU** | 3-5x faster | 10-20x faster | ~8-12GB |
| **M3 Mac CPU** | Baseline | Baseline | ~4-8GB |

**Optimization Tips**:
- GPU: Best for batch processing (10+ documents)
- CPU: Sufficient for single-document processing
- Concurrency: Adjust `--concurrency` based on CPU cores

## Dependencies

### Core Processing Libraries

- `docling==1.20.0`: Document processing framework
- `easyocr==1.7.1`: OCR engine (PyTorch-based)
- `pytesseract==0.3.10`: Tesseract wrapper
- `opencv-python==4.8.1.78`: Image processing

### Vector & AI

- `torch>=2.0.0`: PyTorch (CPU/GPU auto-selection)
- `langchain==0.1.4`: LLM framework
- `pgvector==0.2.4`: Vector storage

### Japanese Text Processing

- `mecab-python3==1.0.6`: Japanese morphological analyzer

## Troubleshooting

### Task Queue Issues

**Symptoms**: Tasks stuck in PENDING state

**Solutions**:
```bash
# Check worker status
docker exec ai-micro-celery-worker celery -A app.core.celery_app inspect active

# Check Redis connection
docker exec ai-micro-celery-worker redis-cli -h host.docker.internal -p 6379 -a <password> ping

# Restart worker
docker compose restart celery-worker
```

### OCR Errors

**Symptoms**: "Tesseract not found" or OCR failures

**Solutions**:
```bash
# Check Tesseract installation
docker exec ai-micro-celery-worker tesseract --version

# Check Japanese language data
docker exec ai-micro-celery-worker ls /usr/share/tesseract-ocr/5/tessdata/jpn*

# Rebuild container
docker compose build --no-cache
```

### Memory Issues

**Symptoms**: Container crashes or OOM errors

**Solutions**:
```bash
# Increase memory limit in docker-compose.yml
deploy:
  resources:
    limits:
      memory: 16G  # Increase from 12G

# Reduce concurrency
command: celery -A app.core.celery_app worker --loglevel=info --pool=threads --concurrency=2
```

### GPU Not Detected (WSL2)

**Symptoms**: CUDA not available or GPU not used

**Solutions**:
```bash
# Check NVIDIA driver in WSL2
nvidia-smi

# Check GPU visibility in container
docker exec ai-micro-celery-worker python -c "import torch; print(torch.cuda.is_available())"

# Verify GPU reservation in docker-compose.yml
deploy:
  resources:
    reservations:
      devices:
        - driver: nvidia
          count: all
          capabilities: [gpu]
```

## Health Check

The service includes a health check script:

```bash
# Manual health check
docker exec ai-micro-celery-worker /app/healthcheck.sh

# Check health status
docker inspect --format='{{json .State.Health}}' ai-micro-celery-worker
```

## Integration with Other Services

### Admin API Service
- **Task Submission**: Enqueues document processing tasks
- **Result Retrieval**: Polls task status and results

### PostgreSQL
- **Documents**: Stores processed document metadata
- **Embeddings**: Stores vector embeddings via PGVector

### Redis
- **Broker**: Message queue for task distribution
- **Backend**: Stores task results and status

### Ollama
- **Embeddings**: Generates vector embeddings via API

## Development Guidelines

### Code Quality Standards
- **File Size Limit**: 500 lines per file (excluding docs)
- **Type Hints**: Use Python type annotations
- **Error Handling**: Comprehensive logging and retry logic
- **Async Tasks**: All tasks should be idempotent

### Adding New Tasks

1. Define task in `app/core/celery_app.py` or appropriate module
2. Add task registration to Celery app
3. Implement retry logic and error handling
4. Add integration tests
5. Update this documentation

## Recent Updates

### 2025-11-27: Multiplatform Support

**Added**:
- ✅ `Dockerfile.mac` for M3 Mac support
- ✅ `docker-compose.mac.yml` for Mac-specific configuration
- ✅ `torch>=2.0.0` to requirements.txt (explicit PyTorch dependency)

**Changes**:
- ARM64 optimization with reduced thread count (2 vs 8)
- TORCH_COMPILE disabled for CPU environments
- Memory limit reduced to 8GB for Mac (vs 12GB for GPU)

**Benefits**:
- Consistent behavior across WSL2 and M3 Mac
- Optimized resource usage per environment
- Explicit PyTorch version control

## Related Documentation

- [Root CLAUDE.md](../CLAUDE.md) - System-wide architecture
- [Admin API CLAUDE.md](../ai-micro-api-admin/CLAUDE.md) - Document processing implementation
- [ai-micro-docs/](../ai-micro-docs/) - Detailed API documentation
