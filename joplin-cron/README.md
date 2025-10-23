# Joplin Backup CronJob

Automated daily backups for Joplin accounts using Kubernetes CronJob.

## Overview

This project provides a containerized backup solution that:
- Reads account credentials from a ConfigMap
- Syncs and exports Joplin notes for each account
- Retains 14 days of backup history
- Runs on a daily schedule via Kubernetes CronJob

## Components

- **Docker Image**: `ericmelz/joplin-cron:latest`
- **Backup Script**: `/app/backup.py`
- **Accounts Config**: `/config/accounts.json` (mounted from ConfigMap)
- **Backup Storage**: `/notes_data/backups/` (mounted PVC)
- **Schedule**: Daily at 12:20 PM America/Los_Angeles (PST/PDT)

## CronJob Configuration

The backup runs automatically as a Kubernetes CronJob:

- **Schedule**: `20 12 * * *` (12:20 PM)
- **Timezone**: `America/Los_Angeles` (handles PST/PDT automatically)
- **Concurrency**: `Forbid` (won't start if previous job still running)
- **History**: Keeps last 3 successful jobs, 1 failed job
- **Cleanup**: Completed jobs removed after 1 hour

### Check CronJob Status

```bash
# View CronJob
kubectl get cronjob joplin-backup -n joplin-prod

# View recent jobs
kubectl get jobs -n joplin-prod

# View job logs
kubectl logs job/joplin-backup-<timestamp> -n joplin-prod
```

### Manually Trigger Backup

```bash
# Create a one-time job from the CronJob
kubectl create job --from=cronjob/joplin-backup joplin-backup-manual -n joplin-prod

# Watch job progress
kubectl get jobs -n joplin-prod -w

# View logs
kubectl logs job/joplin-backup-manual -n joplin-prod
```

## Running the Backup Script

### Manual Testing (without CronJob)

**1. Get a shell in a running job pod:**
```bash
# Find the pod name
kubectl get pods -n joplin-prod | grep joplin-backup

# Exec into it
kubectl exec -it joplin-backup-<timestamp>-<hash> -n joplin-prod -- /bin/bash
```

**2. Verify the script is present:**
```bash
ls -l /app/backup.py
```

**3. Run the backup script:**
```bash
python3 /app/backup.py
```

**4. Check backup output:**
```bash
ls -lh /notes_data/backups/
ls -lh /notes_data/backups/eric@emelz.org/
```

### View Logs

```bash
# Watch logs in real-time
kubectl logs -f joplin-cron

# View recent logs
kubectl logs joplin-cron --tail=100
```

## Backup Script Features

### Configuration
- **Accounts File**: `/config/accounts.json`
- **Backup Directory**: `/notes_data/backups/`
- **Joplin Server**: `https://joplin.emelz.org`
- **Retention Period**: 14 days
- **Date Format**: `YYYY-MM-DD`
- **Max Sync Retries**: 3 attempts with 10-second delay
- **Backup Size Tolerance**: Alert if backup shrinks by >15%

### Enhanced Features (v2.0)

✅ **Server Availability Check**
- Pre-flight check before starting backup
- Verifies Joplin server is reachable via `/api/ping`
- Aborts backup if server is down to prevent corruption

✅ **Resource Validation**
- Scans backup `.jex` files for corrupted resources
- Detects 404 error pages disguised as resource files
- Reports count and details of corrupted files
- Fails backup if corruption detected

✅ **Backup Integrity Comparison**
- Compares current backup size with previous backup
- Alerts if backup size decreases by >15%
- Warns if backup size decreases by >5%
- Helps detect incomplete or corrupted backups

✅ **Retry Logic**
- Up to 3 retry attempts for failed syncs
- 10-second delay between retries
- Exponential backoff for transient failures
- Enhanced error logging for debugging

✅ **Enhanced Error Detection**
- Parses sync output for error patterns (404, error, failed, timeout)
- Verifies notes were downloaded after sync
- Checks for empty accounts vs. sync failures
- Detailed error reporting in logs

### Backup Process (Per Account)

1. **Pre-flight Check**
   - Verify Joplin server is reachable
   - Abort if server is unavailable

2. **Configure Joplin CLI**
   - Set sync target to Joplin Server (type 9)
   - Configure server URL, username, password
   - Set date format

3. **Sync Notes (with retries)**
   - Pull latest notes from Joplin Server
   - Run 3 sync passes to ensure complete download
   - Monitor for error patterns in sync output
   - Retry up to 3 times on failure
   - Verify notes exist after sync

4. **Export Backup**
   - Export to `.jex` format
   - Filename: `YYYY-MM-DD.jex`
   - Location: `/notes_data/backups/<username>/YYYY-MM-DD.jex`

5. **Validate Backup**
   - Scan for corrupted resource files
   - Detect 404 error pages in resources
   - Fail if corruption detected

6. **Compare with Previous**
   - Compare backup size with previous day
   - Alert if significant size decrease
   - Log size change percentage

7. **Cleanup**
   - Remove backups older than 14 days
   - Clear Joplin config for next account

### Backup File Structure

```
/notes_data/backups/
├── eric@emelz.org/
│   ├── 2025-10-01.jex
│   ├── 2025-10-02.jex
│   ├── ...
│   └── 2025-10-10.jex
└── randi@emelz.org/
    ├── 2025-10-01.jex
    ├── 2025-10-02.jex
    ├── ...
    └── 2025-10-10.jex
```

## Accounts Configuration

Edit the ConfigMap to add/update accounts:

```bash
kubectl edit configmap joplin-backup-accounts -n joplin-prod
```

Format:
```json
[
    {
        "username": "user1@example.com",
        "password": "secret123"
    },
    {
        "username": "user2@example.com",
        "password": "secret456"
    }
]
```

**Note**: After updating, delete the pod to reload the ConfigMap:
```bash
kubectl delete pod joplin-cron -n joplin-prod
```

## Troubleshooting

### Check if accounts config is mounted
```bash
kubectl exec joplin-cron -- cat /config/accounts.json
```

### Check backup directory permissions
```bash
kubectl exec joplin-cron -- ls -la /notes_data/
kubectl exec joplin-cron -- mkdir -p /notes_data/backups
```

### Test Joplin CLI connection
```bash
kubectl exec -it joplin-cron -- /bin/bash
joplin config sync.target 9
joplin config sync.9.path https://joplin.emelz.org
joplin config sync.9.username your@email.com
joplin config sync.9.password yourpassword
joplin sync
```

### Check backup script logs
```bash
# Run with verbose output
kubectl exec joplin-cron -- python3 /app/backup.py
```

### Verify backups were created
```bash
kubectl exec joplin-cron -- find /notes_data/backups -name "*.jex" -ls
```

## Building the Docker Image

```bash
cd joplin-cron

# Build and push
./build-and-push.sh --platform linux/amd64

# Or manually
docker build -t ericmelz/joplin-cron:latest .
docker push ericmelz/joplin-cron:latest
```

## Deployment

```bash
# Deploy to production
ez k8s deploy --project joplin-cron --environment prod

# Check deployment status
kubectl get pods -n joplin-prod
kubectl describe pod joplin-cron -n joplin-prod
```

## Backup Corruption Prevention

### Issue: Corrupted Backups During Server Downtime

**Problem**: If the Joplin server is shut down or becomes unavailable during a backup, the Joplin CLI will download 404 error pages instead of actual resource files. This results in corrupted backups with 19-byte "404 page not found" files instead of images, PDFs, and other attachments.

**Example Symptoms**:
- Backup size significantly smaller than previous day (e.g., 2.82 GB vs 3.94 GB)
- Many resource files are exactly 19 bytes
- Resource files contain "404 page not found" instead of actual content
- Thousands of resources affected (e.g., 1,909 corrupted files)

**Solution (Implemented in v2.0)**:

1. **Pre-flight Server Check**: Verifies server is reachable before starting backup
2. **Resource Validation**: Scans backup files for corrupted resources and fails backup if detected
3. **Size Comparison**: Alerts if backup shrinks significantly compared to previous day
4. **Retry Logic**: Retries failed syncs with exponential backoff for transient failures
5. **Enhanced Logging**: Detailed error messages help identify issues quickly

**Best Practices**:
- Never shut down Joplin server during backup window (13:03-13:20 UTC / 12:03-12:20 PM PST)
- If server must be shut down, suspend the CronJob first: `kubectl patch cronjob joplin-backup -n joplin-prod -p '{"spec":{"suspend":true}}'`
- Monitor backup logs for warnings about size decreases or corrupted resources
- Keep at least 14 days of backups to have multiple recovery points

**Manual Recovery**:
If a corrupted backup is detected:
```bash
# 1. Delete the corrupted backup
kubectl exec -n joplin-prod deployment/joplin-backup -- rm /notes_data/backups/eric@emelz.org/2025-10-23.jex

# 2. Ensure Joplin server is running
kubectl get pods -n joplin-prod -l app=joplin-emelz

# 3. Manually trigger a new backup
kubectl create job --from=cronjob/joplin-backup joplin-backup-manual-$(date +%s) -n joplin-prod

# 4. Monitor the job
kubectl logs -f -n joplin-prod job/joplin-backup-manual-<timestamp>
```

## Future Enhancements

- [x] Convert Pod to CronJob for scheduled execution
- [x] Server availability check before backup
- [x] Backup validation and corruption detection
- [x] Retry logic for transient failures
- [x] Backup size comparison and alerting
- [ ] Add retention policy configuration via environment variables
- [ ] Add backup verification (restore test)
- [ ] Add metrics/monitoring (backup success/failure counts)
- [ ] Add notifications (email/Slack on failure)
- [ ] Support multiple Joplin servers
