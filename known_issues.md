# Known Issues - Joplin Kubernetes Deployment

## 🚨 **Critical Issues Found**

### **1. Secret Configuration Mismatch**
- **Problem**: The deployment expects `JWT_SECRET_FILE` but the secret template creates `JWT_SECRET`
- **Location**: `helm/templates/deployment.yaml:48-52` vs `helm/templates/secret.yaml:9`
- **Impact**: Container will fail to find the JWT secret environment variable
- **Current Code**:
  ```yaml
  # deployment.yaml
  - name: JWT_SECRET_FILE
    valueFrom:
      secretKeyRef:
        name: joplin-emelz-secret
        key: JWT_SECRET_FILE
  
  # secret.yaml
  stringData:
    JWT_SECRET: {{ .Values.jwtSecret | quote }}
  ```
- **Fix**: Either change deployment to use `JWT_SECRET` or change secret to create `JWT_SECRET_FILE`

### **2. Storage Volume Mount Issues**
- **Problem**: JWT secret is mounted as a directory volume instead of a file
- **Location**: `helm/templates/deployment.yaml:57-59`
- **Issue**: Mounting PVC to `/run/secrets/jwt_secret` creates a directory, but Joplin expects a file
- **Current**: `mountPath: /run/secrets/jwt_secret` (directory)
- **Should be**: `mountPath: /run/secrets/` with `subPath: jwt_secret` (file)
- **Impact**: Application cannot read JWT secret file properly

### **3. PVC Name Mismatches**
- **Problem**: PVC names don't match between templates
- **Deployment expects**: 
  - `pvc-joplin-emelz-joplin`
  - `pvc-joplin-emelz-jwt-secret`
- **PVC templates create**: 
  - `joplin-emelz-pvc-joplin`
  - `joplin-emelz-pvc-jwt-secret`
- **Impact**: Deployment will fail to find PVCs, pods will remain in Pending state

### **4. Template Value Issues**
- **Problem**: Environment variables in deployment use unquoted Helm values
- **Location**: `helm/templates/deployment.yaml:30-42`
- **Risk**: Numeric values (ports) will fail without quotes
- **Current Code**:
  ```yaml
  - name: APP_PORT
    value: {{ .Values.appPort }}  # Should be: value: "{{ .Values.appPort }}"
  ```

### **5. Storage Path Inconsistencies**
- **Helm chart points to**: `/Users/ericmelz/Data/var/joplin-server/`
- **Direct manifests point to**: `/Users/ericmelz/bin/joplin-server/` 
- **CLAUDE.md documents**: `/Users/ericmelz/Data/var/joplin-server/`
- **Impact**: Confusion about which storage location is correct, potential data loss

### **6. Missing Secret Values**
- **Problem**: `postgresPassword` and `jwtSecret` are empty strings in values.yaml
- **Location**: `helm/values.yaml:10,12`
- **Current**:
  ```yaml
  postgresPassword: ""
  jwtSecret: ""
  ```
- **Impact**: Secrets will be created but contain no actual secret data
- **Security Risk**: Application may fail to authenticate or use default/empty credentials

### **7. k3d Volume Mount Limitations**
- **Problem**: k3d in Docker Desktop may not support hostPath volumes to macOS filesystem
- **Issue**: Docker Desktop runs in VM, host paths may not be accessible
- **Affected Paths**:
  - `/Users/ericmelz/Data/var/joplin-server/data`
  - `/Users/ericmelz/Data/var/joplin-server/secrets/.jwt_secret`
- **Risk**: Storage may not work properly in containerized k3d environment

## 🛠️ **Missing Installation Requirements**

### **Pre-deployment Steps Missing:**

1. **Create storage directories** 
   - Script doesn't automatically create required directories
   - Manual creation required: `mkdir -p /Users/ericmelz/Data/var/joplin-server/{data,secrets}`

2. **Set actual secret values** 
   - values.yaml contains empty secrets
   - Must be set via `--set` flags or by editing values.yaml before deployment
   - Example: `helm install --set postgresPassword=mypassword --set jwtSecret=mysecret`

3. **Verify k3d volume mounts work** 
   - Need to test if k3d can access macOS filesystem paths
   - May need to use k3d volume mounts or alternative storage approach

4. **Database setup** 
   - PostgreSQL must be running and accessible at `rs2423.porgy-sole.ts.net:55434`
   - Database `joplin` must exist with user `joplin` configured

## 📋 **Recommended Fixes Priority**

### **High Priority (Deployment Blockers):**
1. **Fix PVC name mismatches** - Standardize naming between deployment and PVC templates
2. **Fix JWT secret configuration** - Decide on file vs environment variable approach
3. **Add quotes to template values** - Ensure all Helm values are properly quoted
4. **Provide actual secret values** - Add mechanism to inject real credentials

### **Medium Priority (Operational Issues):**
5. **Standardize storage paths** - Use consistent paths across all configurations
6. **Add directory creation to k3d setup script** - Automate storage directory setup
7. **Add validation for k3d volume mounting** - Test and document volume mount requirements

### **Low Priority (Documentation/Cleanup):**
8. **Remove conflicting manifest files** - Decide between Helm chart and direct manifests
9. **Update CLAUDE.md** - Reflect actual working configuration
10. **Add troubleshooting guide** - Document common deployment issues and solutions

## 🧪 **Testing Requirements**

Before deployment, verify:
- [ ] k3d cluster can access host filesystem paths
- [ ] PostgreSQL database is accessible from k3d pods
- [ ] Secret values are properly injected
- [ ] Storage directories exist and have correct permissions
- [ ] Port forwarding works for service access

## 🔧 **Quick Fix Commands**

```bash
# Create storage directories
mkdir -p /Users/ericmelz/Data/var/joplin-server/{data,secrets}

# Test k3d volume mounting
k3d cluster create test-volumes -v /Users/ericmelz/Data/var:/tmp/test-vol

# Deploy with secrets
helm install joplin ./helm \
  --set postgresPassword="your-db-password" \
  --set jwtSecret="your-jwt-secret-key"

# Check pod status
kubectl get pods -w
kubectl describe pod <pod-name>
```

---

*This file documents issues found during analysis on 2024-09-28. Issues should be verified and tested before implementing fixes.*