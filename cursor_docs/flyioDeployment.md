# Fly.io Deployment Guide

[Roadmap](projectRoadmap.md) | [Task](currentTask.md) | [Stack](techStack.md) | [Summary](codebaseSummary.md)

This guide outlines the steps needed to deploy the Voice Inbox App backend to Fly.io, including troubleshooting common issues.

## Prerequisites

1. Install Fly CLI
   ```bash
   brew install flyctl
   ```

2. Create a Fly.io account and login
   ```bash
   fly auth login
   ```

## Deployment Steps

### 1. Prepare Your Project

Navigate to the backend directory:
```bash
cd voice-inbox/backend
```

Make sure you have all necessary files:
- `fly.toml` - Configuration file
- `Dockerfile` - Container definition
- `.dockerignore` - Files to exclude from the build
- `.env` - Local environment variables (not deployed)

### 2. Create a New Fly App

```bash
fly launch --name voice-inbox-api
```

When prompted:
- Choose an organization (or create a new one)
- Select a region close to you (e.g., `fra` for Frankfurt)
- Answer "yes" to setting up a PostgreSQL database if you want to use PostgreSQL instead of SQLite
- Answer "no" to setting up an Upstash Redis database (not needed)

### 3. Create a Volume for Persistent Storage

This is critical for the SQLite database and audio files:

```bash
fly volumes create voice_inbox_data --size 1 --app voice-inbox-api
```

Note: You must create the app first (step 2) before creating a volume.

### 4. Deploy the Application

```bash
fly deploy
```

### 5. Set Environment Variables

Set the OpenAI API key:

```bash
fly secrets set OPENAI_API_KEY=your_openai_api_key_here
```

### 6. Access Your Deployed App

```bash
fly open
```

Or visit: https://voice-inbox-api.fly.dev

## Troubleshooting

### "App not found" when creating a volume

If you see this error:
```
Error: failed to create volume: app not found
```

Make sure you've created the app first with `fly launch --name voice-inbox-api`.

### Database connection issues

Check that the volume is properly mounted. In your `fly.toml` file, ensure you have:

```toml
[[mounts]]
  source = 'voice_inbox_data'
  destination = '/app/data'
```

And in your code, ensure the database path is set correctly:

```python
DB_PATH = os.environ.get("DB_PATH", "/app/data/inbox.db")
```

### Audio file storage issues

Make sure the audio directory is inside the mounted volume path:

```python
AUDIO_DIR = os.environ.get("AUDIO_DIR", "/app/data/audio")
```

### Whisper model loading issues

If you encounter out-of-memory errors with the Whisper model, try:
- Using a smaller model ("tiny" instead of "base" or larger)
- Increasing VM memory in `fly.toml`:
  ```toml
  [[vm]]
    memory = '1gb'
    cpu_kind = 'shared'
    cpus = 1
  ```

## Scaling and Monitoring

- Scale app: `fly scale count 2`
- View logs: `fly logs`
- SSH into instance: `fly ssh console`
- Restart app: `fly apps restart`

## Version History
- 2023-04-23 v1.0 Initial guide 