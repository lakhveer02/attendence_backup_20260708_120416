#!/bin/bash

# ============================================================================
# Enterprise HRMS - Service Startup Script
# Checks dependencies and starts all required services
# ============================================================================

set -e  # Exit on error

echo "🚀 Enterprise HRMS - Starting Services..."
echo "=========================================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# ============================================================================
# STEP 1: Check Docker
# ============================================================================

echo "📦 Checking Docker..."
if ! command -v docker &> /dev/null; then
    echo -e "${RED}❌ Docker not found${NC}"
    echo ""
    echo "Please install Docker Desktop:"
    echo "  https://www.docker.com/products/docker-desktop"
    echo ""
    exit 1
fi

if ! docker info &> /dev/null; then
    echo -e "${RED}❌ Docker daemon not running${NC}"
    echo ""
    echo "Please start Docker Desktop and try again"
    exit 1
fi

echo -e "${GREEN}✓ Docker is running${NC}"
echo ""

# ============================================================================
# STEP 2: Check Redis Container
# ============================================================================

echo "🔄 Checking Redis..."
REDIS_CONTAINER="hrms-redis"

if docker ps | grep -q $REDIS_CONTAINER; then
    echo -e "${GREEN}✓ Redis is already running${NC}"
else
    echo "Starting Redis container..."
    
    # Check if container exists but stopped
    if docker ps -a | grep -q $REDIS_CONTAINER; then
        echo "Starting existing Redis container..."
        docker start $REDIS_CONTAINER
    else
        echo "Creating new Redis container..."
        docker run -d \
            --name $REDIS_CONTAINER \
            -p 6379:6379 \
            redis:7-alpine \
            redis-server --appendonly yes
    fi
    
    # Wait for Redis to be ready
    echo "Waiting for Redis to be ready..."
    sleep 2
    
    if docker ps | grep -q $REDIS_CONTAINER; then
        echo -e "${GREEN}✓ Redis started successfully${NC}"
    else
        echo -e "${RED}❌ Failed to start Redis${NC}"
        exit 1
    fi
fi

echo ""

# ============================================================================
# STEP 3: Test Redis Connection
# ============================================================================

echo "🔌 Testing Redis connection..."
if docker exec $REDIS_CONTAINER redis-cli ping | grep -q "PONG"; then
    echo -e "${GREEN}✓ Redis connection successful${NC}"
else
    echo -e "${RED}❌ Redis connection failed${NC}"
    exit 1
fi

echo ""

# ============================================================================
# STEP 4: Check Python Virtual Environment
# ============================================================================

echo "🐍 Checking Python environment..."

if [ ! -d "venv" ]; then
    echo -e "${YELLOW}⚠ Virtual environment not found. Creating...${NC}"
    python3 -m venv venv
fi

# Activate virtual environment
source venv/bin/activate

echo -e "${GREEN}✓ Virtual environment activated${NC}"
echo ""

# ============================================================================
# STEP 5: Install/Update Python Dependencies
# ============================================================================

echo "📚 Checking Python dependencies..."

# Check if requirements have changed
REQUIREMENTS_FILE="requirements.txt"
INSTALLED_MARKER=".requirements_installed"

if [ ! -f "$INSTALLED_MARKER" ] || [ "$REQUIREMENTS_FILE" -nt "$INSTALLED_MARKER" ]; then
    echo "Installing/updating dependencies..."
    pip3 install -r requirements.txt
    touch $INSTALLED_MARKER
    echo -e "${GREEN}✓ Dependencies installed${NC}"
else
    echo -e "${GREEN}✓ Dependencies up to date${NC}"
fi

echo ""

# ============================================================================
# STEP 6: Check Environment Variables
# ============================================================================

echo "🔐 Checking environment variables..."

if [ ! -f ".env" ]; then
    echo -e "${RED}❌ .env file not found${NC}"
    echo ""
    echo "Please create a .env file with:"
    echo "  SUPABASE_URL=your_supabase_url"
    echo "  SUPABASE_KEY=your_supabase_key"
    echo "  JWT_SECRET_KEY=your_secret_key"
    echo ""
    exit 1
fi

# Check required variables
REQUIRED_VARS=("SUPABASE_URL" "SUPABASE_KEY" "JWT_SECRET_KEY")
MISSING_VARS=()

while IFS='=' read -r key value; do
    # Skip comments and empty lines
    [[ $key =~ ^#.*$ ]] && continue
    [[ -z $key ]] && continue
    
    # Export variable
    export "$key"="$value"
done < .env

for var in "${REQUIRED_VARS[@]}"; do
    if [ -z "${!var}" ]; then
        MISSING_VARS+=("$var")
    fi
done

if [ ${#MISSING_VARS[@]} -gt 0 ]; then
    echo -e "${RED}❌ Missing required environment variables:${NC}"
    printf '%s\n' "${MISSING_VARS[@]}"
    exit 1
fi

echo -e "${GREEN}✓ Environment variables configured${NC}"
echo ""

# ============================================================================
# STEP 7: Display Service Status
# ============================================================================

echo "=========================================="
echo "✅ All services are ready!"
echo "=========================================="
echo ""
echo "📊 Service Status:"
echo "  • Redis:     Running on localhost:6379"
echo "  • Python:    Virtual environment activated"
echo "  • FastAPI:   Ready to start"
echo ""
echo "🚀 Starting FastAPI server..."
echo ""
echo "Available endpoints:"
echo "  • API:               http://localhost:8000"
echo "  • Docs:              http://localhost:8000/docs"
echo "  • Health Check:      http://localhost:8000/monitoring/health"
echo "  • Metrics:           http://localhost:8000/monitoring/metrics"
echo ""
echo "=========================================="
echo ""

# ============================================================================
# STEP 8: Start FastAPI
# ============================================================================

# Start FastAPI with auto-reload for development
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
