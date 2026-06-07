FROM python:3.11-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY backend backend
COPY frontend frontend
COPY config.py config.py

EXPOSE 5000 5001

CMD ["./start.sh"]
