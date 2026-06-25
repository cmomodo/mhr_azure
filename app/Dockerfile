# syntax=docker/dockerfile:1.4

FROM python:3.10-slim AS builder
WORKDIR /code
COPY requirements.txt .
RUN --mount=type=cache,target=/root/.cache/pip \
    pip install --no-cache-dir -r requirements.txt

FROM python:3.10-slim AS production
WORKDIR /code

RUN addgroup --system app && adduser --system --ingroup app --home /home/app app

ENV HOME=/home/app

COPY --from=builder /usr/local/lib/python3.10/site-packages /usr/local/lib/python3.10/site-packages
COPY --from=builder /usr/local/bin /usr/local/bin
COPY app.py ./
COPY cosmos_store.py ./
COPY templates/ ./templates/
COPY static/ ./static/

USER app
EXPOSE 3000
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s \
  CMD python -c "import urllib.request; urllib.request.urlopen('http://127.0.0.1:3000/health')"

CMD ["gunicorn", "--bind", "0.0.0.0:3000", "--workers", "1", "app:app"]
