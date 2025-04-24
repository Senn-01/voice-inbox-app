#!/bin/bash
# Deploy script for Voice Inbox App to Fly.io
set -e  # Exit on any error

# Text colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${GREEN}Voice Inbox App - Fly.io Deployment Script${NC}"
echo "-------------------------------------------"

# Check if flyctl is installed
if ! command -v flyctl &> /dev/null; then
    echo -e "${RED}Error: flyctl is not installed.${NC}"
    echo "Please install the Fly CLI first:"
    echo "  brew install flyctl"
    exit 1
fi

# Check if logged in
echo -e "${YELLOW}Checking login status...${NC}"
if ! flyctl auth whoami &> /dev/null; then
    echo -e "${YELLOW}Not logged in. Please login to Fly.io:${NC}"
    flyctl auth login
else
    echo -e "${GREEN}Already logged in.${NC}"
fi

# Create new Fly.io app if needed
echo -e "${YELLOW}Checking if app exists...${NC}"
APP_NAME="voice-inbox-api"
if ! flyctl apps list | grep -q "$APP_NAME"; then
    echo -e "${YELLOW}App '$APP_NAME' does not exist. Creating...${NC}"
    flyctl launch --name "$APP_NAME" --no-deploy --copy-config
    echo -e "${GREEN}App created.${NC}"
else
    echo -e "${GREEN}App '$APP_NAME' already exists.${NC}"
fi

# Check if volume exists
echo -e "${YELLOW}Checking if volume exists...${NC}"
VOLUME_NAME="voice_inbox_data"
if ! flyctl volumes list --app "$APP_NAME" | grep -q "$VOLUME_NAME"; then
    echo -e "${YELLOW}Volume '$VOLUME_NAME' does not exist. Creating (1GB)...${NC}"
    flyctl volumes create "$VOLUME_NAME" --size 1 --app "$APP_NAME"
    echo -e "${GREEN}Volume created.${NC}"
else
    echo -e "${GREEN}Volume '$VOLUME_NAME' already exists.${NC}"
fi

# Check OpenAI API key
echo -e "${YELLOW}Checking if OpenAI API key is set...${NC}"
if ! flyctl secrets list --app "$APP_NAME" | grep -q "OPENAI_API_KEY"; then
    echo -e "${YELLOW}OPENAI_API_KEY not set.${NC}"
    read -p "Enter your OpenAI API key (or leave empty to skip): " API_KEY
    if [ ! -z "$API_KEY" ]; then
        echo -e "${YELLOW}Setting OPENAI_API_KEY...${NC}"
        flyctl secrets set OPENAI_API_KEY="$API_KEY" --app "$APP_NAME"
        echo -e "${GREEN}API key set.${NC}"
    else
        echo -e "${YELLOW}Skipping API key setup.${NC}"
    fi
else
    echo -e "${GREEN}OPENAI_API_KEY already set.${NC}"
fi

# Deploy the app
echo -e "${YELLOW}Deploying application...${NC}"
flyctl deploy

# Open the app
echo -e "${GREEN}Deployment complete!${NC}"
echo "Opening your app in the browser..."
flyctl open --app "$APP_NAME"

echo -e "${GREEN}Done!${NC}"
echo "Your app is now available at: https://$APP_NAME.fly.dev/"
echo "To check logs: flyctl logs --app $APP_NAME"
echo "To SSH into the VM: flyctl ssh console --app $APP_NAME" 