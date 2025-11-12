FROM python:3.11-slim

WORKDIR /app

# システム依存関係
RUN apt-get update && apt-get install -y \
    postgresql-client \
    gcc \
    build-essential \
    libpq-dev \
    curl \
    tesseract-ocr \
    tesseract-ocr-eng \
    tesseract-ocr-jpn \
    libtesseract-dev \
    libgl1-mesa-dev \
    libglib2.0-0 \
    libsm6 \
    libxext6 \
    libxrender-dev \
    libgomp1 \
    libgcc-s1 \
    poppler-utils \
    libpoppler-cpp-dev \
    qpdf \
    ghostscript \
    fonts-noto-cjk \
    fonts-ipafont \
    fonts-ipaexfont \
    fonts-takao \
    fonts-vlgothic \
    libmecab-dev \
    mecab \
    mecab-ipadic-utf8 \
    && fc-cache -fv \
    && rm -rf /var/lib/apt/lists/*

# MeCabの設定（mecabrcへのシンボリックリンク作成）
RUN mkdir -p /usr/local/etc \
    && ln -s /etc/mecabrc /usr/local/etc/mecabrc

# Tesseract設定
ENV TESSDATA_PREFIX=/usr/share/tesseract-ocr/5/tessdata
RUN mkdir -p /usr/share/tesseract-ocr/5/tessdata

# Python依存関係
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# ai-micro-api-admin のコードをマウント（共有）
# docker-compose.ymlでvolume設定

# Celery設定ファイル
COPY celeryconfig.py /app/celeryconfig.py

# ヘルスチェックスクリプト
COPY healthcheck.sh /app/healthcheck.sh
RUN chmod +x /app/healthcheck.sh

# Docling/EasyOCRキャッシュディレクトリ
RUN mkdir -p /tmp/.docling_cache/huggingface \
    && mkdir -p /tmp/.docling_cache/transformers \
    && mkdir -p /tmp/.docling_cache/torch \
    && mkdir -p /tmp/.easyocr_models \
    && mkdir -p /tmp/document_processing \
    && chmod -R 777 /tmp/.docling_cache /tmp/.easyocr_models /tmp/document_processing

CMD ["celery", "-A", "app.core.celery_app", "worker", "--loglevel=info"]
