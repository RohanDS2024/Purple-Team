#!/usr/bin/env python3
"""
validate_detections.py — Automated detection validation framework

For each test case:
  1. Trigger the attack
  2. Wait for log ingestion
  3. Query Wazuh API for the expected rule ID
  4. Record pass/fail
  5. Print summary + write markdown report

Usage:
  python3 validate_detections.py \\
      --wazuh-host 10.10.10.5 \\
      --user wazuh-wui \\
      --password 'xxx' \\
      --tests test-cases.yaml \\
      --output coverage-report.md

Lab use only — verify=False on TLS, hardcoded sleep, etc.
"""

import argparse
import datetime
import json
import subprocess
import sys
import time
import urllib3
from pathlib import Path

import requests
import yaml

urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)


def get_token(host, user, password):
    """Get a JWT from the Wazuh API."""
    url = f"https://{host}:55000/security/user/authenticate"
    r = requests.post(url, auth=(user, password), verify=False, timeout=10)
    r.raise_for_status()
    return r.json()["data"]["token"]


def query_alerts(host, token, rule_id, since_iso, until_iso):
    """
    Query Wazuh for alerts matching rule_id between two timestamps.
    Note: Wazuh's API doesn't directly serve alerts; this hits the indexer.
    For lab simplicity we use the manager's alerts.json directly via SSH or
    via the indexer search API.
    """
    # Indexer (OpenSearch) search
    url = f"https://{host}:9200/wazuh-alerts-*/_search"
    headers = {"Authorization": f"Bearer {token}", "Content-Type": "application/json"}
    body = {
        "size": 100,
        "query": {
            "bool": {
                "must": [
                    {"term": {"rule.id": str(rule_id)}},
                    {"range": {"@timestamp": {"gte": since_iso, "lte": until_iso}}},
                ]
            }
        },
    }
    # Note: indexer often uses basic auth, not JWT. Adjust per your setup.
    r = requests.post(url, json=body, verify=False, timeout=10,
                      auth=("admin", "<INDEXER_PASSWORD>"))  # change me
    if r.status_code != 200:
        return None
    return r.json().get("hits", {}).get("total", {}).get("value", 0)


def run_attack(test_case):
    """Execute the attack runner script for a test case."""
    runner = test_case.get("runner")
    if not runner:
        return False, "No runner defined"
    
    runner_path = Path(__file__).parent / "attack_runners" / runner
    if not runner_path.exists():
        return False, f"Runner not found: {runner_path}"
    
    try:
        result = subprocess.run(
            ["bash", str(runner_path)],
            capture_output=True,
            text=True,
            timeout=120,
        )
        return result.returncode == 0, result.stdout + result.stderr
    except subprocess.TimeoutExpired:
        return False, "Runner timed out"


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--wazuh-host", required=True)
    parser.add_argument("--user", default="wazuh-wui")
    parser.add_argument("--password", required=True)
    parser.add_argument("--tests", required=True)
    parser.add_argument("--output", default="coverage-report.md")
    parser.add_argument("--wait", type=int, default=60,
                        help="Seconds to wait between attack and query")
    args = parser.parse_args()
    
    # Load test cases
    with open(args.tests) as f:
        config = yaml.safe_load(f)
    tests = config["tests"]
    
    # Auth
    print(f"Authenticating to Wazuh API at {args.wazuh_host}...")
    token = get_token(args.wazuh_host, args.user, args.password)
    print("Got token.\n")
    
    results = []
    
    for i, t in enumerate(tests, 1):
        name = t["name"]
        attack_id = t["attack_id"]
        rule_id = t["rule_id"]
        
        print(f"[{i}/{len(tests)}] {attack_id} {name}")
        
        # Mark start time
        since = datetime.datetime.utcnow() - datetime.timedelta(seconds=10)
        since_iso = since.isoformat() + "Z"
        
        # Run attack
        if t.get("skip_run"):
            print("    (skipping attack execution — assuming already ran)")
            ok, msg = True, ""
        else:
            print(f"    Running: {t.get('runner', 'no runner')}")
            ok, msg = run_attack(t)
            if not ok:
                results.append({"name": name, "id": attack_id, "rule": rule_id,
                                "status": "ERROR", "detail": msg.strip()[:200]})
                print(f"    ✗ ERROR: {msg.strip()[:100]}")
                continue
        
        # Wait for ingestion
        print(f"    Waiting {args.wait}s for log ingestion...")
        time.sleep(args.wait)
        
        # Query
        until = datetime.datetime.utcnow()
        until_iso = until.isoformat() + "Z"
        count = query_alerts(args.wazuh_host, token, rule_id, since_iso, until_iso)
        
        if count is None:
            status, detail = "ERROR", "API query failed"
        elif count == 0:
            status, detail = "FAIL", "No alerts fired"
        else:
            status, detail = "PASS", f"{count} alerts"
        
        results.append({"name": name, "id": attack_id, "rule": rule_id,
                        "status": status, "detail": detail})
        
        symbol = {"PASS": "✓", "FAIL": "✗", "ERROR": "!"}.get(status, "?")
        print(f"    {symbol} {status} (rule {rule_id}, {detail})")
    
    # Summary
    passed = sum(1 for r in results if r["status"] == "PASS")
    print(f"\nSummary: {passed}/{len(tests)} PASS")
    print(f"Coverage: {passed/len(tests)*100:.0f}%")
    
    # Write markdown report
    with open(args.output, "w") as f:
        f.write(f"# Detection Coverage Report\n\n")
        f.write(f"Generated: {datetime.datetime.utcnow().isoformat()}Z\n\n")
        f.write(f"**Coverage: {passed}/{len(tests)} ({passed/len(tests)*100:.0f}%)**\n\n")
        f.write("| # | ATT&CK | Technique | Rule | Status | Detail |\n")
        f.write("|---|--------|-----------|------|--------|--------|\n")
        for i, r in enumerate(results, 1):
            f.write(f"| {i} | {r['id']} | {r['name']} | {r['rule']} | "
                    f"{r['status']} | {r['detail']} |\n")
    
    print(f"\nReport written to {args.output}")
    
    # Exit nonzero if any failures (for CI integration later)
    if any(r["status"] != "PASS" for r in results):
        sys.exit(1)


if __name__ == "__main__":
    main()
