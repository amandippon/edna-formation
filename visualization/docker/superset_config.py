import os

SECRET_KEY = os.environ.get("SUPERSET_SECRET_KEY", "supersetsecretkey123")

SQLALCHEMY_DATABASE_URI = os.environ.get(
    "DATABASE_URI",
    "postgresql+psycopg2://superset:superset@db:5432/superset",
)

CACHE_CONFIG = {
    "CACHE_TYPE": "RedisCache",
    "CACHE_DEFAULT_TIMEOUT": 300,
    "CACHE_KEY_PREFIX": "superset_",
    "CACHE_REDIS_URL": "redis://redis:6379/0",
}
DATA_CACHE_CONFIG = CACHE_CONFIG

TALISMAN_ENABLED = False
WTF_CSRF_ENABLED = False

FEATURE_FLAGS = {"ENABLE_TEMPLATE_PROCESSING": True}

SQLALCHEMY_POOL_SIZE = 5
SQLALCHEMY_MAX_OVERFLOW = 10
GUNICORN_TIMEOUT = 300
