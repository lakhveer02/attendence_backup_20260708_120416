#!/bin/bash

# Start Redis using Docker
# This script will start Redis if not already running

echo "🚀 Starting Redis for HRMS..."

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo "❌ Docker is not running. Please start Docker Desktop first."
    exit 1
fi

# Check if Redis container exists
if [ "$(docker ps -a -q -f name=redis-hrms)" ]; then
    echo "📦 Redis container exists, checking status..."
    
    # Check if it's running
    if [ "$(docker ps -q -f name=redis-hrms)" ]; then
        echo "✅ Redis is already running"
    else
        echo "▶️  Starting existing Redis container..."
        docker start redis-hrms
        echo "✅ Redis started successfully"
    fi
else
    echo "📦 Creating new Redis container..."
    docker run -d \
        --name redis-hrms \
        -p 6379:6379 \
        -v redis-data:/data \
        redis:7-alpine redis-server --appendonly yes
    
    echo "✅ Redis created and started successfully"
fi

# Test Redis connection
echo ""
echo "🧪 Testing Redis connection..."
if docker exec redis-hrms redis-cli ping > /dev/null 2>&1; then
    echo "✅ Redis is responding: PONG"
    echo ""
    echo "📊 Redis Info:"
    docker exec redis-hrms redis-cli info server | grep "redis_version"
    echo ""
    echo "🎉 Redis is ready for use!"
    echo "   Connection string: redis://localhost:6379"
else
    echo "❌ Redis is not responding. Please check Docker logs:"
    echo "   docker logs redis-hrms"
fi
