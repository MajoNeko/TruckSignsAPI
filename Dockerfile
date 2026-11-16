# ---- Build stage ----
FROM python:3.12-alpine as build

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# ---- Runtime stage ----
FROM python:3.12-alpine

WORKDIR /app

COPY --from=build /usr/local/lib/python3.6/site-packages /usr/local/lib/python3.6/site-packages
COPY --from=build /usr/local/bin /usr/local/bin
COPY entrypoint.sh /app/entrypoint.sh

COPY . /app

RUN chmod +x /app/entrypoint.sh

EXPOSE 8020

ENTRYPOINT ["/app/entrypoint.sh"]

CMD ["gunicorn", "trucksigns.wsgi:application", "--bind", "0.0.0.0:8020", "--workers", "2"]
