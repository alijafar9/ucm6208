#!/bin/bash

# 🚀 SIP Client Deployment Script
# Usage: ./deploy.sh [server-ip] [username]

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default values
SERVER_IP=${1:-"your-server-ip"}
USERNAME=${2:-"ubuntu"}
REMOTE_PATH="/var/www/ucm6208"

echo -e "${BLUE}🚀 Starting SIP Client Deployment...${NC}"

# Check if Flutter is installed
if ! command -v flutter &> /dev/null; then
    echo -e "${RED}❌ Flutter is not installed. Please install Flutter first.${NC}"
    exit 1
fi

# Build the Flutter web app
echo -e "${YELLOW}📦 Building Flutter web app...${NC}"
flutter build web

# Copy files to deployment directory
echo -e "${YELLOW}📁 Copying files to deployment directory...${NC}"
cp -r build/web/* deployment/web/

# Check if server IP is provided
if [ "$SERVER_IP" = "your-server-ip" ]; then
    echo -e "${RED}❌ Please provide server IP address${NC}"
    echo -e "${YELLOW}Usage: ./deploy.sh [server-ip] [username]${NC}"
    echo -e "${YELLOW}Example: ./deploy.sh 192.168.1.100 ubuntu${NC}"
    exit 1
fi

# Test SSH connection
echo -e "${YELLOW}🔐 Testing SSH connection to $SERVER_IP...${NC}"
if ! ssh -o ConnectTimeout=10 -o BatchMode=yes $USERNAME@$SERVER_IP exit 2>/dev/null; then
    echo -e "${RED}❌ Cannot connect to server. Please check:${NC}"
    echo -e "${YELLOW}  1. Server IP is correct${NC}"
    echo -e "${YELLOW}  2. SSH key is set up${NC}"
    echo -e "${YELLOW}  3. Server is accessible${NC}"
    exit 1
fi

# Create remote directory
echo -e "${YELLOW}📁 Creating remote directory...${NC}"
ssh $USERNAME@$SERVER_IP "sudo mkdir -p $REMOTE_PATH/web"

# Upload files
echo -e "${YELLOW}📤 Uploading files to server...${NC}"
rsync -avz --delete deployment/web/ $USERNAME@$SERVER_IP:$REMOTE_PATH/web/

# Set permissions
echo -e "${YELLOW}🔐 Setting permissions...${NC}"
ssh $USERNAME@$SERVER_IP "sudo chown -R www-data:www-data $REMOTE_PATH && sudo chmod -R 755 $REMOTE_PATH"

# Check if nginx is installed
if ssh $USERNAME@$SERVER_IP "command -v nginx" 2>/dev/null; then
    echo -e "${YELLOW}🌐 Configuring Nginx...${NC}"
    
    # Upload nginx config
    scp deployment/nginx.conf $USERNAME@$SERVER_IP:/tmp/ucm6208.conf
    
    # Install nginx config
    ssh $USERNAME@$SERVER_IP "sudo cp /tmp/ucm6208.conf /etc/nginx/sites-available/ucm6208 && sudo ln -sf /etc/nginx/sites-available/ucm6208 /etc/nginx/sites-enabled/ && sudo nginx -t && sudo systemctl restart nginx"
    
    echo -e "${GREEN}✅ Nginx configured and restarted${NC}"
elif ssh $USERNAME@$SERVER_IP "command -v apache2" 2>/dev/null; then
    echo -e "${YELLOW}🌐 Configuring Apache...${NC}"
    
    # Upload apache config
    scp deployment/apache.conf $USERNAME@$SERVER_IP:/tmp/ucm6208.conf
    
    # Install apache config
    ssh $USERNAME@$SERVER_IP "sudo cp /tmp/ucm6208.conf /etc/apache2/sites-available/ucm6208.conf && sudo a2ensite ucm6208 && sudo systemctl restart apache2"
    
    echo -e "${GREEN}✅ Apache configured and restarted${NC}"
else
    echo -e "${YELLOW}⚠️  No web server found. Installing Nginx...${NC}"
    ssh $USERNAME@$SERVER_IP "sudo apt update && sudo apt install -y nginx"
    
    # Upload and configure nginx
    scp deployment/nginx.conf $USERNAME@$SERVER_IP:/tmp/ucm6208.conf
    ssh $USERNAME@$SERVER_IP "sudo cp /tmp/ucm6208.conf /etc/nginx/sites-available/ucm6208 && sudo ln -sf /etc/nginx/sites-available/ucm6208 /etc/nginx/sites-enabled/ && sudo nginx -t && sudo systemctl restart nginx"
    
    echo -e "${GREEN}✅ Nginx installed and configured${NC}"
fi

# Test the deployment
echo -e "${YELLOW}🧪 Testing deployment...${NC}"
if curl -s -o /dev/null -w "%{http_code}" http://$SERVER_IP | grep -q "200"; then
    echo -e "${GREEN}✅ Deployment successful!${NC}"
    echo -e "${BLUE}🌐 Your SIP Client is now available at: http://$SERVER_IP${NC}"
else
    echo -e "${YELLOW}⚠️  Deployment completed but test failed. Please check manually.${NC}"
    echo -e "${BLUE}🌐 Try accessing: http://$SERVER_IP${NC}"
fi

echo -e "${GREEN}🎉 Deployment complete!${NC}"
echo -e "${BLUE}📋 Next steps:${NC}"
echo -e "${YELLOW}  1. Configure your domain name (optional)${NC}"
echo -e "${YELLOW}  2. Set up SSL certificate with Let's Encrypt${NC}"
echo -e "${YELLOW}  3. Update SIP settings in the app${NC}"
echo -e "${YELLOW}  4. Test incoming and outgoing calls${NC}" 