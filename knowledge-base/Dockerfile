FROM python:3.14
ENV PYTHONUNBUFFERED=x

WORKDIR /app
COPY requirements.txt .
RUN set -eux \
  ; pip install --break-system-packages --no-cache-dir \
    -r requirements.txt \
  ;

CMD ["fastapi","run","main.py"]
