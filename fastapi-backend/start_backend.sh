#!/bin/bash

# FastAPI Backend Startup Script
# Production-grade Workforce Management System

echo "🚀 Starting FastAPI Backend..."
echo ""

# Check if virtual environment exists
if [ ! -d "venv" ]; then
    echo "📦 Creating virtual environment..."
    python3 -m venv venv
fi

# Activate virtual environment
echo "🔧 Activating virtual environment..."
source venv/bin/activate

# Install/Update dependencies
echo "📥 Installing dependencies..."
pip install --upgrade pip -q
pip install -r requirements.txt -q

echo ""
echo "✅ Dependencies installed"
echo ""

# Set environment variables (if .env doesn't exist, use defaults)
if [ ! -f ".env" ]; then
    echo "⚠️  No .env file found. Using default configuration."
    echo "   Create a .env file for production settings."
    echo ""
fi

# Start the server
echo "🌐 Starting server on http://localhost:8000"
echo "📚 API Documentation: http://localhost:8000/docs"
echo "📊 Alternative docs: http://localhost:8000/redoc"
echo ""
echo "Press CTRL+C to stop the server"
echo ""

# Run with uvicorn
python -m uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
