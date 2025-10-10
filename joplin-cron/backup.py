#!/usr/bin/env python3
"""
Joplin Backup Script

Reads account credentials from /config/accounts.json and performs daily backups
for each account. Retains 14 days of backup history.

Usage:
    python3 /app/backup.py
"""

import json
import os
import subprocess
import sys
from datetime import datetime, timedelta
from pathlib import Path
import shutil
import logging

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s [%(levelname)s] %(message)s',
    datefmt='%Y-%m-%d %H:%M:%S'
)
logger = logging.getLogger(__name__)

# Configuration
ACCOUNTS_FILE = "/config/accounts.json"
BACKUP_BASE_DIR = "/notes_data/backups"
JOPLIN_CONFIG_DIR = os.path.expanduser("~/.config/joplin")
JOPLIN_SERVER_URL = "https://joplin.emelz.org"
RETENTION_DAYS = 14
DATE_FORMAT = "%Y-%m-%d"


class JoplinBackupError(Exception):
    """Custom exception for backup errors"""
    pass


def run_command(cmd, check=True, capture_output=True):
    """
    Run a shell command and return the result

    Args:
        cmd: Command string or list of arguments
        check: Raise exception on non-zero exit code
        capture_output: Capture stdout/stderr

    Returns:
        subprocess.CompletedProcess object
    """
    if isinstance(cmd, str):
        cmd = cmd.split()

    logger.debug(f"Running command: {' '.join(cmd)}")

    try:
        result = subprocess.run(
            cmd,
            check=check,
            capture_output=capture_output,
            text=True
        )
        return result
    except subprocess.CalledProcessError as e:
        logger.error(f"Command failed: {' '.join(cmd)}")
        logger.error(f"Exit code: {e.returncode}")
        logger.error(f"Stdout: {e.stdout}")
        logger.error(f"Stderr: {e.stderr}")
        raise


def load_accounts():
    """
    Load account credentials from JSON file

    Returns:
        list: List of account dictionaries with username/password
    """
    logger.info(f"Loading accounts from {ACCOUNTS_FILE}")

    if not os.path.exists(ACCOUNTS_FILE):
        raise JoplinBackupError(f"Accounts file not found: {ACCOUNTS_FILE}")

    try:
        with open(ACCOUNTS_FILE, 'r') as f:
            accounts = json.load(f)

        if not isinstance(accounts, list):
            raise JoplinBackupError("Accounts file must contain a JSON array")

        logger.info(f"Loaded {len(accounts)} accounts")
        return accounts

    except json.JSONDecodeError as e:
        raise JoplinBackupError(f"Invalid JSON in accounts file: {e}")


def configure_joplin(username, password):
    """
    Configure Joplin CLI for a specific account

    Args:
        username: Joplin account username
        password: Joplin account password
    """
    logger.info(f"Configuring Joplin for {username}")

    # Set sync target to Joplin Server (type 9)
    run_command("joplin config sync.target 9")

    # Configure Joplin Server connection
    run_command(f"joplin config sync.9.path {JOPLIN_SERVER_URL}")
    run_command(f"joplin config sync.9.username {username}")
    run_command(f"joplin config sync.9.password {password}")

    # Set date format
    run_command("joplin config dateFormat YYYY.MM.DD")

    logger.info(f"Joplin configured for {username}")


def verify_notes_exist(username):
    """
    Verify that notes were actually downloaded

    Args:
        username: Account username (for logging)

    Returns:
        bool: True if notes exist, False otherwise
    """
    try:
        # Try to get status which shows note count
        status_result = run_command("joplin status", check=False)
        logger.debug(f"Joplin status output: {status_result.stdout}")

        # Also try listing notes
        ls_result = run_command("joplin ls", check=False)
        logger.debug(f"Joplin ls output: {ls_result.stdout}")

        # Check if status shows any notes
        if status_result.stdout:
            # Look for "Notes:" line in status
            for line in status_result.stdout.split('\n'):
                if 'notes:' in line.lower() or 'items:' in line.lower():
                    logger.info(f"Status: {line.strip()}")

        # If there are notes, ls output won't be empty
        has_notes = bool(ls_result.stdout and ls_result.stdout.strip())

        if has_notes:
            logger.info(f"Verified notes exist for {username}")
            # Show first few notes
            lines = ls_result.stdout.strip().split('\n')[:5]
            for line in lines:
                logger.info(f"  - {line}")
        else:
            logger.warning(f"No notes found in 'joplin ls' for {username}")

        return has_notes
    except Exception as e:
        logger.warning(f"Could not verify notes for {username}: {e}")
        return False


def sync_notes(username):
    """
    Sync notes from Joplin Server and wait for completion

    Args:
        username: Account username (for logging)
    """
    import time

    logger.info(f"Syncing notes for {username}")

    try:
        # Run multiple syncs to ensure everything is downloaded
        # Joplin sync is async and may need multiple passes
        for i in range(1, 4):
            logger.info(f"Running sync pass {i}/3...")
            result = run_command("joplin sync")

            # Log sync output
            if result.stdout:
                logger.debug(f"Sync pass {i} output: {result.stdout}")

            logger.info(f"Sync pass {i} completed")

            # Wait between syncs
            if i < 3:
                time.sleep(3)

        # Final wait for database writes
        logger.info("Waiting for database to flush...")
        time.sleep(3)

        # Verify notes were actually downloaded (informational only)
        verify_notes_exist(username)

    except subprocess.CalledProcessError as e:
        raise JoplinBackupError(f"Sync failed for {username}: {e}")


def export_backup(username, backup_dir):
    """
    Export notes to JEX backup file

    Args:
        username: Account username
        backup_dir: Directory to store backup

    Returns:
        Path to created backup file or None if no data to export
    """
    today = datetime.now().strftime(DATE_FORMAT)
    backup_file = backup_dir / f"{today}.jex"

    logger.info(f"Exporting backup for {username} to {backup_file}")

    try:
        result = run_command(f"joplin export {backup_file} --format jex", check=False)

        # Check if export failed due to no data
        if result.returncode != 0:
            if "no data to export" in result.stdout.lower():
                logger.warning(f"No data to export for {username} - account may be empty")
                return None
            else:
                # Real error
                logger.error(f"Export command failed with exit code {result.returncode}")
                logger.error(f"Stdout: {result.stdout}")
                logger.error(f"Stderr: {result.stderr}")
                raise JoplinBackupError(f"Export failed for {username}")

        if not backup_file.exists():
            raise JoplinBackupError(f"Backup file not created: {backup_file}")

        file_size = backup_file.stat().st_size
        logger.info(f"Backup created: {backup_file} ({file_size:,} bytes)")

        return backup_file

    except subprocess.CalledProcessError as e:
        raise JoplinBackupError(f"Export failed for {username}: {e}")


def cleanup_old_backups(backup_dir, retention_days=RETENTION_DAYS):
    """
    Remove backup files older than retention period

    Args:
        backup_dir: Directory containing backups
        retention_days: Number of days to retain backups
    """
    logger.info(f"Cleaning up backups older than {retention_days} days in {backup_dir}")

    cutoff_date = datetime.now() - timedelta(days=retention_days)
    removed_count = 0

    for backup_file in backup_dir.glob("*.jex"):
        try:
            # Parse date from filename (YYYY-MM-DD.jex)
            file_date_str = backup_file.stem  # Remove .jex extension
            file_date = datetime.strptime(file_date_str, DATE_FORMAT)

            if file_date < cutoff_date:
                logger.info(f"Removing old backup: {backup_file}")
                backup_file.unlink()
                removed_count += 1

        except ValueError:
            logger.warning(f"Skipping file with invalid date format: {backup_file}")
            continue

    if removed_count > 0:
        logger.info(f"Removed {removed_count} old backup(s)")
    else:
        logger.info("No old backups to remove")


def cleanup_joplin_config():
    """
    Remove Joplin configuration and data to prepare for next account
    """
    logger.info("Cleaning up Joplin configuration")

    config_dir = Path(JOPLIN_CONFIG_DIR)

    if config_dir.exists():
        try:
            shutil.rmtree(config_dir)
            logger.info(f"Removed Joplin config directory: {config_dir}")
        except Exception as e:
            logger.warning(f"Failed to remove config directory: {e}")


def backup_account(account):
    """
    Perform backup for a single account

    Args:
        account: Dictionary with 'username' and 'password' keys

    Returns:
        bool: True if backup successful, False otherwise
    """
    username = account.get('username')
    password = account.get('password')

    if not username or not password:
        logger.error(f"Invalid account: missing username or password: {account}")
        return False

    logger.info(f"Starting backup for {username}")

    try:
        # Create backup directory for this account
        backup_dir = Path(BACKUP_BASE_DIR) / username
        backup_dir.mkdir(parents=True, exist_ok=True)

        # Configure Joplin for this account
        configure_joplin(username, password)

        # Sync notes from server
        sync_notes(username)

        # Export backup
        export_backup(username, backup_dir)

        # Clean up old backups
        cleanup_old_backups(backup_dir)

        logger.info(f"✅ Backup completed successfully for {username}")
        return True

    except Exception as e:
        logger.error(f"❌ Backup failed for {username}: {e}")
        return False

    finally:
        # Always clean up Joplin config for next account
        cleanup_joplin_config()


def main():
    """Main backup routine"""
    logger.info("=" * 60)
    logger.info("Joplin Backup Script Starting")
    logger.info("=" * 60)

    try:
        # Load accounts
        accounts = load_accounts()

        if not accounts:
            logger.warning("No accounts to backup")
            return 0

        # Track results
        success_count = 0
        failed_count = 0

        # Backup each account
        for i, account in enumerate(accounts, 1):
            username = account.get('username', 'unknown')
            logger.info(f"\nProcessing account {i}/{len(accounts)}: {username}")
            logger.info("-" * 60)

            if backup_account(account):
                success_count += 1
            else:
                failed_count += 1

        # Summary
        logger.info("\n" + "=" * 60)
        logger.info("Backup Summary")
        logger.info("=" * 60)
        logger.info(f"Total accounts: {len(accounts)}")
        logger.info(f"Successful: {success_count}")
        logger.info(f"Failed: {failed_count}")

        if failed_count > 0:
            logger.warning(f"⚠️  {failed_count} backup(s) failed")
            return 1
        else:
            logger.info("✅ All backups completed successfully")
            return 0

    except Exception as e:
        logger.error(f"Fatal error: {e}", exc_info=True)
        return 1


if __name__ == "__main__":
    sys.exit(main())
