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
echo "Checking if all superuser values are set..."
if [ -z "$DJANGO_SUPERUSER_USERNAME" ] || [ -z "$DJANGO_SUPERUSER_EMAIL" ] || [ -z "$DJANGO_SUPERUSER_PASSWORD" ]; then
    echo "ERROR: DJANGO_SUPERUSER_USERNAME, DJANGO_SUPERUSER_EMAIL and DJANGO_SUPERUSER_PASSWORD must all be set." >&2
    exit 1
fi

echo "Attempting to craete superuser..."
set +e
output=$(python manage.py createsuperuser --noinput 2>&1)
status=$?
set -e

if [ $status -eq 0 ]; then
    echo "Superuser created successfully."
elif echo "$output" | grep -qi "already exists"; then
    echo "Superuser already exists."
else
    echo "ERROR: failed to create superuser (exit $status):" >&2
    echo "$output" >&2
    exit 1
fi

echo "Starting gunicorn..."
gunicorn tsa_app.wsgi:application --bind 0.0.0.0:8020 --workers 2 
