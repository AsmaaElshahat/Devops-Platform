#!/bin/bash
set -e

echo "Starting backend..."
python backend/api.py &

echo "Starting frontend..."
python frontend/app.py
