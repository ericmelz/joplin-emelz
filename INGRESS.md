# Ingress Configuration for joplin.emelz.org

This document explains the two-tier ingress architecture for exposing the Joplin server to the internet.

## Architecture Overview

```
Internet → AWS Security Groups → Nginx (EC2) → Traefik (K8s NodePort) → Joplin Service → Joplin Pods
```

### Components

1. **External Layer**: Nginx reverse proxy on AWS EC2 instance
2. **Internal Layer**: Traefik ingress controller inside Kubernetes cluster

## Traffic Flow

1. **Internet Request**: `https://joplin.emelz.org`
2. **DNS Resolution**: Points to AWS EC2 instance public IP
3. **AWS Security Groups**: Allow ports 80/443
4. **Nginx**: SSL termination, reverse proxy to traefik
5. **Traefik**: Kubernetes ingress controller (NodePort 30080)
6. **Joplin Service**: ClusterIP service on port 22300
7. **Joplin Pods**: Application containers

## Configuration Scripts

### 1. Traefik Configuration (K8s Cluster)

Configure traefik ingress inside the k3s cluster:

```bash
# Apply traefik ingress configuration
./scripts/configure-traefik.sh

# Options:
./scripts/configure-traefik.sh --context k3s-aws-prod --domain joplin.emelz.org --nodeport 30080
```

**What it does:**
- Creates Kubernetes Ingress resource for `joplin.emelz.org`
- Configures routing from traefik to Joplin service
- Verifies traefik NodePort service (30080)
- Tests ingress connectivity

### 2. Nginx Configuration (AWS Instance)

Configure nginx reverse proxy on the AWS instance:

```bash
# Run on AWS instance (requires sudo)
sudo ./scripts/configure-nginx.sh --domain joplin.emelz.org --ssl

# Options:
sudo ./scripts/configure-nginx.sh --domain joplin.emelz.org --traefik-port 30080 --ssl
```

**What it does:**
- Creates nginx virtual host configuration
- Sets up SSL with Let's Encrypt certificates
- Configures reverse proxy to traefik NodePort
- Enables security headers and optimizations

## Manual Setup Steps

### Prerequisites

1. **DNS Configuration**: Point `joplin.emelz.org` to AWS instance public IP
2. **AWS Security Groups**: Open ports 80, 443, and 30080
3. **Traefik Installed**: Already present in k3s cluster
4. **Nginx Installed**: Present on AWS instance

### Step 1: Configure Traefik (K8s)

```bash
# From local machine (with kubectl configured for k3s)
kubectl config use-context k3s-aws-prod
./scripts/configure-traefik.sh
```

**Verification:**
```bash
# Test traefik routing locally
kubectl port-forward -n traefik svc/traefik 8080:80
curl -H 'Host: joplin.emelz.org' http://localhost:8080/api/ping
# Should return: {"status":"ok","message":"Joplin Server is running"}
```

### Step 2: Configure Nginx (AWS Instance)

```bash
# SSH to AWS instance
ssh user@your-aws-instance

# Run nginx configuration script
sudo ./scripts/configure-nginx.sh --domain joplin.emelz.org --ssl
```

**Verification:**
```bash
# Test nginx to traefik connectivity
curl -H 'Host: joplin.emelz.org' http://127.0.0.1:30080/api/ping

# Test full HTTPS flow
curl https://joplin.emelz.org/api/ping
```

## Configuration Details

### Nginx Virtual Host

Created at: `/etc/nginx/sites-available/joplin-proxy`

Key features:
- HTTP to HTTPS redirect
- Let's Encrypt SSL certificates
- Security headers (HSTS, XSS protection)
- WebSocket support
- Proxy to traefik on NodePort 30080

### Traefik Ingress

Created in namespace: `joplin-prod`

Key features:
- Host-based routing for `joplin.emelz.org`
- Routes to Joplin service on port 22300
- Custom middleware for headers
- Integration with existing traefik deployment

## Troubleshooting

### Check Traefik Service

```bash
kubectl get svc -n traefik
kubectl get svc -n kube-system | grep traefik
```

Expected: NodePort service on port 30080

### Check Ingress Resource

```bash
kubectl get ingress -n joplin-prod
kubectl describe ingress joplin-emelz-traefik -n joplin-prod
```

### Check Nginx Configuration

```bash
# On AWS instance
sudo nginx -t
sudo systemctl status nginx
sudo tail -f /var/log/nginx/access.log
```

### Test Traffic Flow

1. **Direct to Joplin**: `kubectl port-forward -n joplin-prod svc/joplin-emelz 22300:22300`
2. **Through Traefik**: `kubectl port-forward -n traefik svc/traefik 8080:80`
3. **Through Nginx**: Test on AWS instance with curl
4. **Full Flow**: `curl https://joplin.emelz.org/api/ping`

### Common Issues

1. **Traefik Not Found**: Check namespace (traefik vs kube-system)
2. **NodePort Mismatch**: Verify traefik service NodePort matches nginx upstream
3. **SSL Certificate Issues**: Check certbot logs, verify domain ownership
4. **DNS Issues**: Verify joplin.emelz.org points to correct AWS IP
5. **Security Group**: Ensure AWS allows ports 80, 443, 30080

## SSL Certificate Management

### Automatic Renewal

Certificates are automatically renewed by certbot:

```bash
# Check renewal status
sudo certbot certificates

# Test renewal
sudo certbot renew --dry-run
```

### Manual Certificate Renewal

```bash
# On AWS instance
sudo certbot renew
sudo systemctl reload nginx
```

## Monitoring

### Nginx Logs

```bash
sudo tail -f /var/log/nginx/access.log
sudo tail -f /var/log/nginx/error.log
```

### Traefik Dashboard

Access traefik dashboard (if enabled):

```bash
kubectl port-forward -n traefik svc/traefik 8081:8080
# Visit http://localhost:8081
```

### Health Checks

```bash
# Nginx health check
curl http://your-aws-instance/nginx-health

# Joplin health check
curl https://joplin.emelz.org/api/ping
```

## Security Considerations

1. **SSL Termination**: Occurs at nginx (external layer)
2. **Internal Traffic**: HTTP between nginx and traefik (secure network)
3. **Security Headers**: Applied by nginx
4. **Rate Limiting**: Can be configured in nginx
5. **Firewall**: AWS security groups restrict access

## Performance Optimizations

1. **Nginx Buffering**: Configured for optimal performance
2. **HTTP/2**: Enabled for HTTPS connections
3. **Keep-Alive**: Configured between nginx and traefik
4. **Compression**: Available in nginx configuration
5. **Caching**: Can be added to nginx for static assets