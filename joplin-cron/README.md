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

## Running the Backup Script

### Inside the Container (Manual Testing)

**1. Get a shell in the pod:**
```bash
kubectl exec -it joplin-cron -- /bin/bash
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

### Backup Process (Per Account)

1. **Configure Joplin CLI**
   - Set sync target to Joplin Server (type 9)
   - Configure server URL, username, password
   - Set date format

2. **Sync Notes**
   - Pull latest notes from Joplin Server

3. **Export Backup**
   - Export to `.jex` format
   - Filename: `YYYY-MM-DD.jex`
   - Location: `/notes_data/backups/<username>/YYYY-MM-DD.jex`

4. **Cleanup**
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

## Future Enhancements

- [ ] Convert Pod to CronJob for scheduled execution
- [ ] Add retention policy configuration via environment variables
- [ ] Add backup verification (restore test)
- [ ] Add metrics/monitoring (backup success/failure counts)
- [ ] Add notifications (email/Slack on failure)
- [ ] Support multiple Joplin servers
