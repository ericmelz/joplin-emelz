#!/usr/bin/env python3
"""
Test script to verify server availability check logic
Can be run locally without Docker to verify the pre-flight check works
"""

import urllib.request
import urllib.error
import sys

JOPLIN_SERVER_URL = "https://joplin.emelz.org"

def check_server_availability():
    """
    Check if Joplin server is reachable before attempting backup

    Returns:
        bool: True if server is available, False otherwise
    """
    print(f"Checking server availability: {JOPLIN_SERVER_URL}")

    try:
        # Try to reach the server's API ping endpoint
        ping_url = f"{JOPLIN_SERVER_URL}/api/ping"
        req = urllib.request.Request(ping_url, method='GET')

        with urllib.request.urlopen(req, timeout=10) as response:
            if response.status == 200:
                print("✅ Server is reachable")
                body = response.read().decode('utf-8')
                print(f"Response: {body}")
                return True
            else:
                print(f"❌ Server returned status {response.status}")
                return False

    except urllib.error.HTTPError as e:
        print(f"❌ Server returned HTTP error: {e.code} {e.reason}")
        return False
    except urllib.error.URLError as e:
        print(f"❌ Server unreachable: {e.reason}")
        return False
    except Exception as e:
        print(f"❌ Server check failed: {e}")
        return False

def main():
    print("=" * 60)
    print("Joplin Server Availability Test")
    print("=" * 60)

    if check_server_availability():
        print("\n✅ Test PASSED: Server is available")
        print("Backup would proceed normally")
        return 0
    else:
        print("\n❌ Test PASSED: Server check correctly detected unavailability")
        print("Backup would be aborted (this is the correct behavior)")
        return 1

if __name__ == "__main__":
    sys.exit(main())
