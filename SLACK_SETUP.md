# Slack Notifications Setup Guide

This guide explains how to set up Slack notifications for the CI/CD pipeline.

## Prerequisites

- Admin access to your Slack workspace
- Admin/write access to the GitHub repository

## Step 1: Create Slack Webhook

1. Go to https://api.slack.com/apps
2. Click **"Create New App"** → **"From scratch"**
3. Name your app (e.g., "EAE Firmware CI/CD")
4. Select your workspace

### Configure Incoming Webhooks

1. In your app settings, go to **"Incoming Webhooks"**
2. Toggle **"Activate Incoming Webhooks"** to ON
3. Click **"Add New Webhook to Workspace"**
4. Select the channel where notifications should be posted
5. Copy the webhook URL (looks like: `https://hooks.slack.com/services/T00000000/B00000000/XXXXXXXXXXXXXXXXXXXXXXXX`)

## Step 2: Add Webhook to GitHub Secrets

1. Go to your GitHub repository
2. Navigate to **Settings** → **Secrets and variables** → **Actions**
3. Click **"New repository secret"**
4. Name: `SLACK_WEBHOOK_URL`
5. Value: Paste the webhook URL from Step 1
6. Click **"Add secret"**

## Step 3: Test the Integration

The Slack notification will trigger automatically on:
- Every push to any branch
- Every pull request

You can test it by:
```bash
git commit --allow-empty -m "test: slack notification"
git push
```

## Notification Format

The notification includes:

### Success (✅)
- Green color
- All jobs passed
- Links to view run and commit

### Failure (❌)
- Red color
- One or more jobs failed
- Shows which jobs failed

### Partial Success (⚠️)
- Yellow color
- Some jobs skipped or cancelled
- Mixed results

## Customization

### Change Notification Conditions

Edit `.github/workflows/ci.yml` line 570:
```yaml
if: always() && (github.event_name == 'push' || github.event_name == 'pull_request')
```

Options:
- `if: failure()` - Only notify on failures
- `if: success()` - Only notify on success
- `if: always()` - Always notify

### Change Notification Channel

You need to create a new webhook URL for each channel.

### Disable Notifications

Remove or comment out the "Send Slack Notification" step in the workflow.

## Troubleshooting

### No Notifications Received

1. Check the workflow run logs for the "Send Slack Notification" step
2. Verify the `SLACK_WEBHOOK_URL` secret is set correctly
3. Ensure the webhook URL is still valid in Slack

### Rate Limiting

Slack webhooks have rate limits. If you're hitting limits:
- Consider filtering to only important branches
- Only notify on failures
- Use GitHub's built-in Slack integration instead

## Alternative: GitHub Slack App

Instead of webhooks, you can use the official GitHub Slack integration:

1. Install from: https://slack.github.com/
2. In Slack, run:
   ```
   /github subscribe murr2k/EAE_Firmware workflows
   ```

Benefits:
- No webhook setup required
- More features (issues, PRs, etc.)
- Better formatting

## Security Notes

- The webhook URL is sensitive - treat it like a password
- Use GitHub Secrets, never commit the URL
- Rotate the webhook if compromised
- Webhooks are write-only (can't read your Slack)