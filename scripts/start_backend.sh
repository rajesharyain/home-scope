#!/bin/bash
set -e

echo "🚀 Starting HomeScope Backend..."

# Check for .env
if [ ! -f .env ]; then
  echo "📋 Creating .env from .env.example..."
  cp .env.example .env
  echo "⚠️  Edit .env to add your API keys (optional)"
fi

# Start services
echo "🐳 Starting Docker services..."
docker compose up -d db redis

echo "⏳ Waiting for database to be ready..."
sleep 5

echo "🔧 Starting API server..."
docker compose up api

echo "✅ Backend running at http://localhost:8000"
echo "📚 API docs at http://localhost:8000/docs"
