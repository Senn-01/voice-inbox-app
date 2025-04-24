FROM python:3.11-slim

WORKDIR /app

# Install git and other dependencies
RUN apt-get update && apt-get install -y \
    git \
    ffmpeg \
    && rm -rf /var/lib/apt/lists/*

# Copy requirements first for better caching
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
# Install the OpenAI whisper package directly from GitHub
RUN pip uninstall -y whisper && pip install git+https://github.com/openai/whisper.git

# Copy the rest of the application
COPY . .

# Create necessary directories
RUN mkdir -p data/audio && chmod 777 data/audio

# Set environment variable for database path
ENV DB_PATH=/app/data/inbox.db

# Expose the port
EXPOSE 8000

# Command to run the application
CMD ["uvicorn", "api:app", "--host", "0.0.0.0", "--port", "8000"] 