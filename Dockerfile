# ---- Build stage ----
FROM python:3.12-slim-bookworm as build

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# ---- Runtime stage ----
FROM python:3.12-slim-bookworm

WORKDIR /app/src

COPY --from=build /usr/local/lib/python3.12/site-packages /usr/local/lib/python3.12/site-packages
COPY --from=build /usr/local/bin /usr/local/bin
COPY entrypoint.sh /app/entrypoint.sh

COPY . /app

RUN sed -i 's/\r$//' /app/entrypoint.sh && chmod +x /app/entrypoint.sh

EXPOSE 8020

ENTRYPOINT ["/app/entrypoint.sh"]