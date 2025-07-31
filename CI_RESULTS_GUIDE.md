# CI/CD Results Collection Guide

## Overview

The CI/CD pipeline now collects comprehensive test results in multiple formats for analysis and trending. This guide explains how to access and use these results.

## What's Collected

### 1. Per-Job Results
Each CI job collects:
- **JSON files**: Detailed metadata and results (`test-run-TIMESTAMP.json`)
- **CSV files**: Simple format for trending (`history.csv`)
- **XML files**: Standard test output formats (JUnit/GoogleTest XML)
- **Markdown summaries**: Human-readable test summaries

### 2. Aggregated Results
The `ci-summary` job combines all results into:
- `run-report.md`: Complete run summary
- `all-results.csv`: Combined CSV from all jobs
- GitHub Step Summary: Visible in the workflow run UI

### 3. Historical Data (Main Branch Only)
- `.ci-results/test-history.md`: Last 50 test runs on main branch
- Automatically committed to the repository

## Accessing Results

### From GitHub UI

1. **During/After a Run**:
   - Go to Actions tab → Select workflow run
   - Scroll to "Artifacts" section
   - Download any artifact ZIP file

2. **Step Summary**:
   - Click on "CI Summary" job
   - View the summary table directly in the UI

### From Command Line

```bash
# Using GitHub CLI
gh run download <run-id>

# List available artifacts
gh run view <run-id>

# Download specific artifact
gh run download <run-id> -n "test-results-ubuntu-latest-g++-11"
```

### From the Repository

Historical results (main branch only):
```bash
git pull
cat .ci-results/test-history.md
```

## Result Formats

### JSON Format
```json
{
  "metadata": {
    "timestamp": "2025-07-31_12-34-56",
    "commit": "abc123...",
    "branch": "main",
    "run_id": "123456789",
    "run_number": "42"
  },
  "environment": {
    "os": "ubuntu-latest",
    "compiler": "g++-11",
    "cmake_version": "cmake version 3.22.1"
  },
  "results": {
    "build_status": "success",
    "build_time_seconds": "45",
    "test_status": "success",
    "test_summary": "All tests passed (25 tests)"
  }
}
```

### CSV Format
```csv
timestamp,commit,os,compiler,build_status,test_status
2025-07-31_12-34-56,abc123,ubuntu-latest,g++-11,success,success
```

## Analyzing Results

### Quick Status Check
Look at the workflow badges in README.md or the Actions tab for overall status.

### Trending Analysis
1. Download the aggregated CSV file
2. Import into spreadsheet software
3. Create charts for:
   - Build times over commits
   - Test success rates by compiler
   - Platform-specific issues

### Debugging Failures
1. Check the Step Summary for quick overview
2. Download the specific job's artifact
3. Review the JSON file for detailed environment info
4. Check test output in the summary field

## Retention Policy

- **Artifacts**: 90 days (configurable)
- **Repository history**: Last 50 runs
- **GitHub UI logs**: 90 days (GitHub default)

## Tips

1. **Filter by OS/Compiler**: Artifact names include platform info
2. **Compare Runs**: Download multiple run artifacts to compare
3. **Automation**: Use the JSON files for automated analysis scripts
4. **Notifications**: Set up GitHub notifications for failed runs

## Example: Analyzing Build Times

```python
import json
import glob
import matplotlib.pyplot as plt

# Load all JSON files
build_times = []
for file in glob.glob("ci-results/test-run-*.json"):
    with open(file) as f:
        data = json.load(f)
        if data["results"]["build_time_seconds"]:
            build_times.append({
                "time": data["metadata"]["timestamp"],
                "seconds": int(data["results"]["build_time_seconds"]),
                "compiler": data["environment"]["compiler"]
            })

# Plot build times by compiler
# ... plotting code ...
```

## Troubleshooting

### Missing Results
- Check if the job completed (even failed jobs upload results)
- Verify artifact upload didn't fail
- For Python tests, ensure pytest-json is installed

### Large Artifacts
- Results are compressed automatically
- Old artifacts expire after 90 days
- Download only needed artifacts, not all

### Permission Issues
- Repository history updates require write permissions
- Fork PRs won't update repository history
- Use artifact downloads for PR analysis