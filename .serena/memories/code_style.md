# Code Style for ai-micro-celery

## File Size Limits
- Maximum 500 lines per file

## Task Design Principles
- All tasks should be idempotent
- Implement retry logic for transient failures
- Use proper error handling and logging

## Adding New Tasks
1. Define task in `app/core/celery_app.py`
2. Add task registration
3. Implement retry logic
4. Add tests
5. Update documentation
