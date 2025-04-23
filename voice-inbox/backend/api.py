from fastapi import FastAPI, UploadFile, Form, HTTPException, Depends, Request
from fastapi.responses import HTMLResponse, JSONResponse
from fastapi.staticfiles import StaticFiles
from fastapi.templating import Jinja2Templates
import uuid
import os
import shutil
import json
from typing import Optional
from pathlib import Path
import datetime
from openai import OpenAI, OpenAIError
from dotenv import load_dotenv

# Import database functions
from database import get_db_connection, get_all_items, get_item_by_id, insert_item, update_item

# Load environment variables
load_dotenv()

# Initialize OpenAI client
client = OpenAI()

# Create FastAPI app
app = FastAPI(title="Voice Inbox API")

# Audio directory - check environment variables or use default
AUDIO_DIR = os.environ.get("AUDIO_DIR", "data/audio")
os.makedirs(AUDIO_DIR, exist_ok=True)

# Set up Jinja2 templates
templates = Jinja2Templates(directory="templates")

# Mount static files (if needed later)
# app.mount("/static", StaticFiles(directory="static"), name="static")

# Mount audio directory for direct file access
app.mount("/audio", StaticFiles(directory=AUDIO_DIR), name="audio")

@app.get("/", response_class=HTMLResponse)
async def index(request: Request):
    """Render the main index page with HTMX."""
    return templates.TemplateResponse("index.html", {"request": request})

@app.get("/items", response_class=HTMLResponse)
async def get_items(request: Request):
    """Get all items and render them with HTMX."""
    items = get_all_items()
    return templates.TemplateResponse("items.html", {"request": request, "items": items})

@app.post("/inbox")
async def add_inbox_item(
    text: str = Form(...),
    audio: Optional[UploadFile] = None
):
    """Add a new item to the inbox with optional audio file."""
    try:
        # Generate a unique ID
        item_id = str(uuid.uuid4())
        
        # Save audio file if provided
        audio_path = None
        if audio:
            audio_filename = f"{item_id}.m4a"
            audio_filepath = os.path.join(AUDIO_DIR, audio_filename)
            
            with open(audio_filepath, "wb") as f:
                shutil.copyfileobj(audio.file, f)
            
            # Store the relative path for web access
            audio_path = f"audio/{audio_filename}"
        
        # Insert into database
        result = insert_item(item_id, text, audio_path)
        return result
    
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error adding item: {str(e)}")

@app.post("/classify/{item_id}")
async def classify_item(item_id: str):
    """Classify an item using GPT-4.1-mini."""
    try:
        # Get the item from the database
        item = get_item_by_id(item_id)
        if not item:
            raise HTTPException(status_code=404, detail="Item not found")
        
        # Prepare the prompt for GPT-4.1-mini
        prompt = f"Classify the note as task, idea, or note and suggest one tag. Respond as JSON {{\"category\": \"...\", \"tag\": \"...\"}}.\n\n{item['text']}"
        
        # Call OpenAI API
        response = client.chat.completions.create(
            model="gpt-4.1-mini",
            messages=[{"role": "user", "content": prompt}],
            response_format={"type": "json_object"}
        )
        
        # Parse the response
        content = response.choices[0].message.content
        data = json.loads(content)
        
        # Update the item with the tag
        update_item(item_id, tag=data["tag"], pending=0)
        
        return data
    
    except OpenAIError as e:
        raise HTTPException(status_code=500, detail=f"OpenAI API error: {str(e)}")
    
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error classifying item: {str(e)}")

@app.put("/items/{item_id}")
async def update_inbox_item(
    item_id: str,
    tag: Optional[str] = None,
    pending: Optional[int] = None
):
    """Update an existing inbox item."""
    try:
        # Check if item exists
        item = get_item_by_id(item_id)
        if not item:
            raise HTTPException(status_code=404, detail="Item not found")
        
        # Update the item
        updated_item = update_item(item_id, tag, pending)
        if not updated_item:
            raise HTTPException(status_code=400, detail="No fields to update")
        
        return updated_item
    
    except HTTPException:
        raise
    
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error updating item: {str(e)}")

if __name__ == "__main__":
    import uvicorn
    uvicorn.run("api:app", host="0.0.0.0", port=8000, reload=True) 