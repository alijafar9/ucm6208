# 🚀 SIP Client Deployment Guide

## **Deployment Options**

### **Option 1: Traditional Web Server (Recommended)**

#### **Using Nginx (Linux/Ubuntu)**

1. **Install Nginx:**
   ```bash
   sudo apt update
   sudo apt install nginx
   ```

2. **Upload files to server:**
   ```bash
   # Create directory
   sudo mkdir -p /var/www/ucm6208
   
   # Upload web files (use scp, rsync, or FTP)
   sudo cp -r deployment/web/* /var/www/ucm6208/web/
   
   # Set permissions
   sudo chown -R www-data:www-data /var/www/ucm6208
   sudo chmod -R 755 /var/www/ucm6208
   ```

3. **Configure Nginx:**
   ```bash
   # Copy nginx config
   sudo cp deployment/nginx.conf /etc/nginx/sites-available/ucm6208
   
   # Enable site
   sudo ln -s /etc/nginx/sites-available/ucm6208 /etc/nginx/sites-enabled/
   
   # Test and restart
   sudo nginx -t
   sudo systemctl restart nginx
   ```

#### **Using Apache (Linux/Ubuntu)**

1. **Install Apache:**
   ```bash
   sudo apt update
   sudo apt install apache2
   ```

2. **Upload files:**
   ```bash
   sudo mkdir -p /var/www/ucm6208
   sudo cp -r deployment/web/* /var/www/ucm6208/web/
   sudo chown -R www-data:www-data /var/www/ucm6208
   ```

3. **Configure Apache:**
   ```bash
   sudo cp deployment/apache.conf /etc/apache2/sites-available/ucm6208.conf
   sudo a2ensite ucm6208
   sudo systemctl restart apache2
   ```

### **Option 2: Cloud Platforms**

#### **AWS S3 + CloudFront**

1. **Create S3 bucket:**
   ```bash
   aws s3 mb s3://your-sip-client-bucket
   ```

2. **Upload files:**
   ```bash
   aws s3 sync deployment/web/ s3://your-sip-client-bucket --delete
   ```

3. **Configure CloudFront distribution**

#### **Google Cloud Storage**

1. **Create bucket:**
   ```bash
   gsutil mb gs://your-sip-client-bucket
   ```

2. **Upload files:**
   ```bash
   gsutil -m rsync -r deployment/web/ gs://your-sip-client-bucket
   ```

#### **Azure Blob Storage**

1. **Create storage account and container**
2. **Upload files using Azure CLI**

### **Option 3: Container Deployment**

#### **Using Docker**

1. **Create Dockerfile:**
   ```dockerfile
   FROM nginx:alpine
   COPY deployment/web/ /usr/share/nginx/html/
   COPY deployment/nginx.conf /etc/nginx/conf.d/default.conf
   EXPOSE 80
   ```

2. **Build and run:**
   ```bash
   docker build -t sip-client .
   docker run -p 80:80 sip-client
   ```

#### **Using Docker Compose**

1. **Create docker-compose.yml:**
   ```yaml
   version: '3.8'
   services:
     sip-client:
       image: nginx:alpine
       ports:
         - "80:80"
       volumes:
         - ./deployment/web:/usr/share/nginx/html
         - ./deployment/nginx.conf:/etc/nginx/conf.d/default.conf
   ```

2. **Deploy:**
   ```bash
   docker-compose up -d
   ```

### **Option 4: CDN Deployment**

#### **Netlify**

1. **Connect your Git repository**
2. **Set build command:** `flutter build web`
3. **Set publish directory:** `build/web`

#### **Vercel**

1. **Connect your Git repository**
2. **Set framework preset:** Other
3. **Set build command:** `flutter build web`
4. **Set output directory:** `build/web`

## **SSL/HTTPS Setup**

### **Using Let's Encrypt (Free)**

```bash
# Install Certbot
sudo apt install certbot python3-certbot-nginx

# Get SSL certificate
sudo certbot --nginx -d your-domain.com

# Auto-renewal
sudo crontab -e
# Add: 0 12 * * * /usr/bin/certbot renew --quiet
```

### **Using Cloudflare**

1. **Add your domain to Cloudflare**
2. **Set DNS records**
3. **Enable SSL/TLS encryption**

## **Environment Configuration**

### **Update SIP Settings**

Edit `deployment/web/main.dart.js` or update the controller:

```dart
// Update these settings for your server
wsUri: 'ws://your-ucm6208-server:8088/ws'
domain: 'your-ucm6208-server'
username: '003'
password: 'tr123'
```

### **CORS Configuration**

If your UCM6208 is on a different domain, add CORS headers:

```nginx
# Add to nginx.conf
add_header Access-Control-Allow-Origin "*";
add_header Access-Control-Allow-Methods "GET, POST, OPTIONS";
add_header Access-Control-Allow-Headers "DNT,User-Agent,X-Requested-With,If-Modified-Since,Cache-Control,Content-Type,Range";
```

## **Monitoring & Maintenance**

### **Log Monitoring**

```bash
# Nginx logs
sudo tail -f /var/log/nginx/access.log
sudo tail -f /var/log/nginx/error.log

# Apache logs
sudo tail -f /var/log/apache2/access.log
sudo tail -f /var/log/apache2/error.log
```

### **Performance Optimization**

1. **Enable gzip compression** (already in configs)
2. **Set up caching** (already in configs)
3. **Use CDN for static assets**
4. **Monitor server resources**

## **Security Considerations**

1. **Use HTTPS** (required for WebRTC)
2. **Set up firewall rules**
3. **Regular security updates**
4. **Monitor access logs**
5. **Backup configuration files**

## **Troubleshooting**

### **Common Issues**

1. **WebRTC not working:**
   - Ensure HTTPS is enabled
   - Check browser console for errors
   - Verify UCM6208 connectivity

2. **CORS errors:**
   - Add CORS headers to server config
   - Check UCM6208 WebSocket settings

3. **Audio not working:**
   - Check microphone permissions
   - Verify browser supports WebRTC
   - Test with different browsers

### **Debug Commands**

```bash
# Check if server is running
sudo systemctl status nginx
sudo systemctl status apache2

# Check port usage
sudo netstat -tlnp | grep :80
sudo netstat -tlnp | grep :443

# Check SSL certificate
sudo certbot certificates
```

## **Backup & Recovery**

### **Backup Configuration**

```bash
# Backup nginx config
sudo cp /etc/nginx/sites-available/ucm6208 /backup/nginx-ucm6208.conf

# Backup web files
sudo tar -czf /backup/ucm6208-web-$(date +%Y%m%d).tar.gz /var/www/ucm6208
```

### **Restore Configuration**

```bash
# Restore nginx config
sudo cp /backup/nginx-ucm6208.conf /etc/nginx/sites-available/ucm6208

# Restore web files
sudo tar -xzf /backup/ucm6208-web-20231201.tar.gz -C /
```

---

## **Quick Deploy Script**

Create `deploy.sh`:

```bash
#!/bin/bash
echo "🚀 Deploying SIP Client..."

# Build Flutter app
flutter build web

# Copy to deployment
cp -r build/web/* deployment/web/

# Upload to server (replace with your server details)
rsync -avz deployment/web/ user@your-server:/var/www/ucm6208/web/

# Restart nginx
ssh user@your-server "sudo systemctl restart nginx"

echo "✅ Deployment complete!"
```

Make it executable: `chmod +x deploy.sh`
Run: `./deploy.sh` 