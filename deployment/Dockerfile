# Use nginx alpine for smaller image size
FROM nginx:alpine

# Copy web files
COPY deployment/web/ /usr/share/nginx/html/

# Copy nginx configuration
COPY deployment/nginx.conf /etc/nginx/conf.d/default.conf

# Expose port 80
EXPOSE 80

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD curl -f http://localhost/ || exit 1

# Start nginx
CMD ["nginx", "-g", "daemon off;"] 