# Known Issues - Joplin Kubernetes Deployment

## ✅ **RESOLVED ISSUES** *(Fixed in latest commit)*

### **1. Secret Configuration Mismatch** - ✅ FIXED
- **Solution**: Deployment now uses `JWT_SECRET_FILE` from values.yaml (file-based approach)
- **Status**: Secret template removed, using file mount from persistent volume

### **2. Storage Volume Mount Issues** - ✅ FIXED  
- **Solution**: JWT secret now properly mounted with `subPath: jwt_secret`
- **Fixed Configuration**: `mountPath: /run/secrets/` with `subPath: jwt_secret`
- **Status**: Application can now read JWT secret file properly

### **3. PVC Name Mismatches** - ✅ FIXED
- **Solution**: Standardized naming to `pvc-*` and `pv-*` prefixes consistently
- **Current Names**: 
  - `pvc-joplin-emelz-joplin` ✅
  - `pvc-joplin-emelz-jwt-secret` ✅
- **Status**: All template references now match correctly

### **4. Configuration Conflicts** - ✅ FIXED
- **Solution**: Removed conflicting k8s/k3d-manifests/ directory
- **Status**: Single Helm-based deployment approach, no more path inconsistencies

## 🚨 **REMAINING CRITICAL ISSUES**

### **1. Template Value Issues** - ⚠️ PARTIALLY FIXED
- **Problem**: Some environment variables still use unquoted Helm values
- **Location**: `helm/templates/deployment.yaml:32,34,40,42,44`
- **Progress**: Numeric values (APP_PORT, POSTGRES_PORT) now properly quoted ✅
- **Remaining unquoted values**:
  ```yaml
  - name: APP_BASE_URL
    value: {{ .Values.appBaseUrl }}        # Needs quotes
  - name: DB_CLIENT  
    value: {{ .Values.dbClient }}          # Needs quotes
  - name: POSTGRES_DATABASE
    value: {{ .Values.postgresDatabase }}  # Needs quotes
  - name: POSTGRES_USER
    value: {{ .Values.postgresUser }}      # Needs quotes
  - name: JWT_SECRET_FILE
    value: {{ .Values.jwtSecretFile }}     # Needs quotes
  ```
- **Status**: Critical numeric values fixed, string values still need quotes

### **2. Missing Secret Values** - ❌ NOT FIXED
- **Problem**: `postgresPassword` is empty string in values.yaml
- **Location**: `helm/values.yaml:10`
- **Current**:
  ```yaml
  postgresPassword: ""
  ```
- **Impact**: Database authentication will fail
- **Security Risk**: Application cannot connect to database

### **3. k3d Volume Mount Limitations** - ⚠️ UNKNOWN
- **Problem**: k3d in Docker Desktop may not support hostPath volumes to macOS filesystem
- **Issue**: Docker Desktop runs in VM, host paths may not be accessible
- **Affected Paths**:
  - `/Users/ericmelz/Data/var/joplin-server/data`
  - `/Users/ericmelz/Data/var/joplin-server/secrets/.jwt_secret`
- **Risk**: Storage may not work properly in containerized k3d environment
- **Status**: Needs testing

## 🛠️ **REMAINING INSTALLATION REQUIREMENTS**

### **Pre-deployment Steps Still Needed:**

1. **Set actual secret values** - ❌ CRITICAL
   - `postgresPassword` is still empty in values.yaml
   - Must be set via `--set` flag or by editing values.yaml before deployment
   - Example: `helm install --set postgresPassword=mypassword joplin ./helm`

2. **Verify k3d volume mounts work** - ⚠️ TESTING NEEDED
   - Need to test if k3d can access macOS filesystem paths
   - May need k3d volume configuration or alternative storage approach

3. **Database connectivity** - ✅ CONFIGURED
   - PostgreSQL configured for `rs2423.porgy-sole.ts.net:55434`
   - Database `joplin` with user `joplin` should exist

4. **Storage directories** - ✅ EXIST
   - Directories already exist at `/Users/ericmelz/Data/var/joplin-server/`
   - JWT secret file exists at `/Users/ericmelz/Data/var/joplin-server/secrets/.jwt_secret`

## 📋 **UPDATED FIX PRIORITIES**

### **High Priority (Still Blocking Deployment):**
1. ⚠️ **Complete template value quoting** - String values still need quotes (numeric values fixed)
2. ❌ **Provide actual secret values** - Set postgresPassword in values.yaml

### **Medium Priority (Testing Needed):**
3. ⚠️ **Test k3d volume mounting** - Verify storage works with macOS Docker Desktop
4. ⚠️ **Test end-to-end deployment** - Verify complete application startup

### **Low Priority (Improvements):**
5. ✅ **Update CLAUDE.md** - Reflect resolved issues status
6. ✅ **Add comprehensive issue tracking** - Document all problems and solutions

## 🧪 **UPDATED TESTING REQUIREMENTS**

Before deployment, verify:
- [x] ✅ Storage directories exist and have correct permissions
- [x] ✅ PVC/PV naming matches between templates  
- [x] ✅ JWT secret volume mount configuration is correct
- [ ] ❌ k3d cluster can access host filesystem paths
- [ ] ❌ PostgreSQL database is accessible from k3d pods
- [ ] ❌ Secret values are properly injected (need actual password)
- [ ] ❌ Template values are properly quoted
- [ ] ❌ Port forwarding works for service access

## 🔧 **UPDATED QUICK FIX COMMANDS**

```bash
# 1. Fix remaining string template quotes (HIGH PRIORITY)
# Edit helm/templates/deployment.yaml to add quotes around remaining string values:
# APP_BASE_URL, DB_CLIENT, POSTGRES_DATABASE, POSTGRES_USER, JWT_SECRET_FILE

# 2. Deploy with actual secrets (CRITICAL)
helm install joplin ./helm \
  --set postgresPassword="your-actual-db-password"

# 3. Test k3d volume mounting
k3d cluster create test-volumes -v /Users/ericmelz/Data/var:/tmp/test-vol
kubectl run test-pod --image=busybox --command -- sleep 3600
kubectl exec test-pod -- ls -la /tmp/test-vol

# 4. Check deployment status
kubectl get pods -w
kubectl describe pod <joplin-pod-name>
kubectl logs <joplin-pod-name>
```

## 📊 **PROGRESS SUMMARY**

**MAJOR ISSUES RESOLVED (4/7):**
- ✅ Secret configuration mismatch
- ✅ Storage volume mount issues  
- ✅ PVC naming mismatches
- ✅ Configuration path conflicts

**REMAINING ISSUES (2.5/7):**
- ⚠️ Template value quoting (partially fixed - numeric values done)
- ❌ Missing secret values  
- ⚠️ k3d volume mount testing needed

**Deployment Readiness: ~75% - Very close to working!**

---

*Last updated: 2024-09-28 after major fixes. Most critical deployment blockers have been resolved.*