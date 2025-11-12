import os
from kombu import Queue

# Broker設定
broker_url = os.getenv("CELERY_BROKER_URL", "redis://localhost:6379/1")
result_backend = os.getenv("CELERY_RESULT_BACKEND", "redis://localhost:6379/2")

# タイムゾーン
timezone = "Asia/Tokyo"
enable_utc = True

# タスク設定
task_serializer = "json"
result_serializer = "json"
accept_content = ["json"]

# タスク結果の有効期限（24時間）
result_expires = 86400

# タスクの実行時間制限
task_time_limit = 3600  # 1時間（長時間処理対応）
task_soft_time_limit = 3300  # 55分（ソフトリミット）

# Worker設定
worker_prefetch_multiplier = 1  # タスクを1つずつ取得（公平性）
worker_max_tasks_per_child = 100  # 100タスクごとにWorkerを再起動（メモリリーク対策）

# キュー設定
task_queues = (
    Queue("default", routing_key="task.default"),
    Queue("high_priority", routing_key="task.high"),
    Queue("low_priority", routing_key="task.low"),
)

task_default_queue = "default"
task_default_exchange_type = "direct"
task_default_routing_key = "task.default"

# タスクルーティング
task_routes = {
    "app.tasks.document_tasks.task_generate_embeddings": {"queue": "high_priority"},
    "app.tasks.atlas_tasks.task_generate_kb_summary": {"queue": "high_priority"},
    "app.tasks.atlas_tasks.task_generate_collection_summary": {"queue": "default"},
}

# Beatスケジュール（定期実行タスク）
beat_schedule = {
    # 毎日深夜2時にKB要約を再生成（将来実装）
    # "regenerate-all-kb-summaries": {
    #     "task": "app.tasks.atlas_tasks.task_regenerate_all_kb_summaries",
    #     "schedule": crontab(hour=2, minute=0),
    # },
}

# ログ設定
worker_log_format = "[%(asctime)s: %(levelname)s/%(processName)s] %(message)s"
worker_task_log_format = "[%(asctime)s: %(levelname)s/%(processName)s][%(task_name)s(%(task_id)s)] %(message)s"
