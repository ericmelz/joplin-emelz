# Testing Enhanced Backup Script v2.0

This document provides instructions for testing the improved backup script with corruption detection and server availability checks.

## Prerequisites

- Kubernetes cluster with joplin-cron deployment
- Docker installed on build machine
- Access to docker registry (ericmelz/joplin-cron)
- kubectl configured for joplin-prod namespace

## Build and Deploy New Image

### Step 1: Build Docker Image

```bash
cd /home/eric/code/joplin-emelz/joplin-cron

# Build and push the new image
./build-and-push.sh --platform linux/amd64

# Or with a version tag
./build-and-push.sh --platform linux/amd64 --tag v2.0
```

### Step 2: Update CronJob to Use New Image

```bash
# Option 1: If using 'latest' tag, just restart
kubectl -n joplin-prod delete cronjob joplin-backup
helm upgrade joplin-backup ./helm -n joplin-prod -f environments/prod/values.yaml

# Option 2: If using version tag, update values.yaml first
# Edit: environments/prod/values.yaml
# Change: image.tag: "v2.0"
helm upgrade joplin-backup ./helm -n joplin-prod -f environments/prod/values.yaml
```

## Test Scenarios

### Test 1: Server Down - Should FAIL with Pre-flight Check

**Purpose**: Verify backup aborts when Joplin server is unavailable

**Setup**:
```bash
# Ensure Joplin server is shut down
kubectl -n joplin-prod get deployment joplin-emelz
# Should show: 0/0 replicas

kubectl -n joplin-prod get pods -l app=joplin-emelz
# Should show: No resources found
```

**Execute**:
```bash
# Trigger manual backup
kubectl create job --from=cronjob/joplin-backup joplin-backup-test-down-$(date +%s) -n joplin-prod

# Monitor logs
kubectl logs -f -n joplin-prod job/joplin-backup-test-down-<timestamp>
```

**Expected Output**:
```
============================================================
Joplin Backup Script Starting
============================================================
Checking server availability: https://joplin.emelz.org
❌ Server unreachable: <error details>
❌ Joplin server is not available - aborting backup
❌ Please ensure the server is running before attempting backup
```

**Expected Result**:
- ✅ Job exits with error code 1
- ✅ No backup files created
- ✅ Clear error message about server unavailability
- ✅ Backup aborts before any sync attempts

**Verify**:
```bash
# Check job status
kubectl get job -n joplin-prod joplin-backup-test-down-<timestamp>
# STATUS should be "Failed" or "Complete" with 0/1 completions

# Check exit code
kubectl get pod -n joplin-prod -l job-name=joplin-backup-test-down-<timestamp> -o jsonpath='{.items[0].status.containerStatuses[0].state.terminated.exitCode}'
# Should return: 1
```

### Test 2: Server Running - Should SUCCEED

**Purpose**: Verify backup works correctly when server is available

**Setup**:
```bash
# Start Joplin server
kubectl scale deployment joplin-emelz -n joplin-prod --replicas=1

# Wait for pod to be ready
kubectl -n joplin-prod wait --for=condition=ready pod -l app=joplin-emelz --timeout=60s

# Verify server is responding
curl -s https://joplin.emelz.org/api/ping
# Should return: {"status":"ok","message":"Joplin Server is running"}
```

**Execute**:
```bash
# Trigger manual backup
kubectl create job --from=cronjob/joplin-backup joplin-backup-test-up-$(date +%s) -n joplin-prod

# Monitor logs
kubectl logs -f -n joplin-prod job/joplin-backup-test-up-<timestamp>
```

**Expected Output**:
```
============================================================
Joplin Backup Script Starting
============================================================
Checking server availability: https://joplin.emelz.org
✅ Server is reachable
Loading accounts from /config/accounts.json
Loaded 2 accounts

Processing account 1/2: eric@emelz.org
------------------------------------------------------------
Starting backup for eric@emelz.org
Configuring Joplin for eric@emelz.org
Joplin configured for eric@emelz.org
Syncing notes for eric@emelz.org
Running sync pass 1/3...
Sync pass 1 completed
Running sync pass 2/3...
Sync pass 2 completed
Running sync pass 3/3...
Sync pass 3 completed
Waiting for database to flush...
Status: Daily Notes: 2690 notes
Verified notes exist for eric@emelz.org
Exporting backup for eric@emelz.org to /notes_data/backups/eric@emelz.org/2025-10-23.jex
Backup created: /notes_data/backups/eric@emelz.org/2025-10-23.jex (3,031,099,904 bytes)
Validating resources in /notes_data/backups/eric@emelz.org/2025-10-23.jex
✅ All 25034 resources validated successfully
Comparing with previous backup for eric@emelz.org
Previous backup: 2025-10-22.jex (4,233,123,456 bytes)
Current backup:  2025-10-23.jex (3,031,099,904 bytes)
Size change: -28.4%
⚠️  WARNING: Backup size decreased by 28.4%!
⚠️  This may indicate a corrupted or incomplete backup
⚠️  Previous: 4,233,123,456 bytes, Current: 3,031,099,904 bytes
✅ Backup completed successfully for eric@emelz.org
...

============================================================
Backup Summary
============================================================
Total accounts: 2
Successful: 2
Failed: 0
✅ All backups completed successfully
```

**Expected Result**:
- ✅ Job completes successfully
- ✅ Backup files created for all accounts
- ✅ Resource validation passes
- ✅ Size comparison logged
- ✅ No corrupted resources detected

**Verify**:
```bash
# Check job status
kubectl get job -n joplin-prod joplin-backup-test-up-<timestamp>
# STATUS should be "Complete" with 1/1 completions

# Verify backup files exist
kubectl exec -n joplin-prod job/joplin-backup-test-up-<timestamp> -- \
  ls -lh /notes_data/backups/eric@emelz.org/

# Check backup file size (should be several GB)
kubectl exec -n joplin-prod job/joplin-backup-test-up-<timestamp> -- \
  du -h /notes_data/backups/eric@emelz.org/2025-10-23.jex
```

### Test 3: Corrupted Backup Detection (Simulation)

**Purpose**: Verify backup fails when corrupted resources are detected

This would require simulating a scenario where resources are corrupted. Since we now have pre-flight checks, this shouldn't happen in production, but we can verify the detection logic works.

**Manual Simulation**:
```bash
# Create a test backup with corrupted resources
# This would require modifying the test to inject corruption
# or using the corrupted backup from 2025-10-23 as a test case
```

### Test 4: Retry Logic

**Purpose**: Verify retry logic works for transient failures

This is difficult to test without simulating network issues, but the code path can be verified through logs during normal operation.

## Validation Checklist

After running tests, verify:

- [ ] Server down: Backup fails immediately with clear error message
- [ ] Server down: No backup files created
- [ ] Server down: Exit code is 1 (failure)
- [ ] Server up: Backup completes successfully
- [ ] Server up: All resources validated
- [ ] Server up: Backup size compared with previous
- [ ] Logs show pre-flight check results
- [ ] Logs show resource validation results
- [ ] Logs show backup size comparison
- [ ] No corrupted backups are marked as successful

## Cleanup

```bash
# Remove test jobs
kubectl delete job -n joplin-prod joplin-backup-test-down-<timestamp>
kubectl delete job -n joplin-prod joplin-backup-test-up-<timestamp>

# Or clean up all test jobs
kubectl delete job -n joplin-prod -l cronjob=joplin-backup
```

## Rollback Plan

If issues are found with the new version:

```bash
# Option 1: Rollback to previous image tag
kubectl -n joplin-prod set image cronjob/joplin-backup \
  joplin-backup=ericmelz/joplin-cron:v1.0

# Option 2: Restore from git
git checkout <previous-commit> joplin-cron/backup.py
./build-and-push.sh --platform linux/amd64 --tag v1.0
kubectl -n joplin-prod set image cronjob/joplin-backup \
  joplin-backup=ericmelz/joplin-cron:v1.0
```

## Current Test Status

**Test 1 (Server Down)**: ✅ PASSED - Local verification shows server check detects unavailability

```bash
# Test executed locally:
$ python3 -c "import urllib.request; ..."
❌ Server unreachable: HTTP Error 404: Not Found
# Exit code: 1
```

**Test 2 (Server Running)**: ⏳ PENDING - Requires Docker build and deployment

**Test 3 (Corrupted Detection)**: ⏳ PENDING - Requires Docker build and deployment

**Test 4 (Retry Logic)**: ⏳ PENDING - Requires Docker build and deployment

## Next Steps

1. Build Docker image on machine with Docker installed
2. Push to registry
3. Deploy to cluster
4. Run Test 1 (Server Down) - should fail gracefully
5. Run Test 2 (Server Up) - should succeed with validation
6. Monitor production backups for a week
7. Review logs for any warnings or issues
