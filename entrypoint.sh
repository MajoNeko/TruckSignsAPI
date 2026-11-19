#!/usr/bin/env bash
set -e

echo "Waiting for postgres to connect ..."

# Wait for the database to be up and ready, if not ready, then sleep for 5 seconds
until python -c "
import os, sys, psycopg2
try:
    psycopg2.connect(
        dbname=os.environ['DB_NAME'], 
        user=os.environ['DB_USER'],
        password=os.environ['DB_PASSWORD'],
        host=os.environ['DB_HOST'],
        port=os.environ.get('DB_PORT', '5432'),
    )
except psycopg2.OperationalError:
    sys.exit(1)
"; do
  echo "Postgres unavailable, retrying in 5s..."
  sleep 5
done

echo "PostgreSQL is active"

echo "Collecting static files:"
python manage.py collectstatic --noinput

echo "Applying migrations:"
python manage.py migrate --noinput

echo "Postgresql migrations finished"

echo "Ensuring superuser exists..."
python manage.py createsuperuser --noinput 2>/dev/null || echo "Superuser already exists."

echo "Starting gunicorn..."
gunicorn tsa_app.wsgi:application --bind 0.0.0.0:8020 --workers 2 
