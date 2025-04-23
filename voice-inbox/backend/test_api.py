import pytest
from fastapi.testclient import TestClient
import os
import uuid
from io import BytesIO

from api import app
import database

client = TestClient(app)

@pytest.fixture(autouse=True)
def setup_test_database():
    # Use an in-memory SQLite database for testing
    database.DB_PATH = ":memory:"
    database.init_db()
    yield
    # No cleanup needed for in-memory database

def test_index_route():
    response = client.get("/")
    assert response.status_code == 200
    assert "Voice Inbox" in response.text

def test_items_route_empty():
    response = client.get("/items")
    assert response.status_code == 200
    assert "Your inbox is empty" in response.text

def test_add_inbox_item():
    # Test adding a new item without audio
    test_text = "Test note from pytest"
    response = client.post("/inbox", data={"text": test_text})
    
    assert response.status_code == 200
    json_response = response.json()
    assert "id" in json_response
    
    # Verify it appears in the items list
    response = client.get("/items")
    assert response.status_code == 200
    assert test_text in response.text
    assert "Your inbox is empty" not in response.text

def test_add_inbox_item_with_audio():
    # Create a test audio file
    test_audio = BytesIO(b"fake audio data")
    test_audio.name = "test.m4a"
    
    test_text = "Test note with audio"
    response = client.post(
        "/inbox",
        data={"text": test_text},
        files={"audio": ("test.m4a", test_audio, "audio/m4a")}
    )
    
    assert response.status_code == 200
    json_response = response.json()
    assert "id" in json_response
    
    # Verify it appears in the items list
    response = client.get("/items")
    assert response.status_code == 200
    assert test_text in response.text
    assert "Show Audio" in response.text

def test_update_item():
    # First add an item
    test_text = "Test note for updating"
    response = client.post("/inbox", data={"text": test_text})
    assert response.status_code == 200
    item_id = response.json()["id"]
    
    # Update the item
    response = client.put(
        f"/items/{item_id}",
        json={"tag": "test-tag", "pending": False}
    )
    
    assert response.status_code == 200
    updated_item = response.json()
    assert updated_item["tag"] == "test-tag"
    assert updated_item["pending"] == False
    
    # Verify the tag appears in the items list
    response = client.get("/items")
    assert response.status_code == 200
    assert "test-tag" in response.text

def test_item_not_found():
    # Try to update a non-existent item
    fake_id = str(uuid.uuid4())
    response = client.put(
        f"/items/{fake_id}",
        json={"tag": "test-tag"}
    )
    
    assert response.status_code == 404
    assert "not found" in response.json()["detail"]

# Skip the OpenAI dependent test unless an API key is provided
@pytest.mark.skipif(not os.environ.get("OPENAI_API_KEY"), reason="OpenAI API key not set")
def test_classify_item():
    # First add an item
    test_text = "Remember to buy groceries tomorrow"
    response = client.post("/inbox", data={"text": test_text})
    assert response.status_code == 200
    item_id = response.json()["id"]
    
    # Classify the item
    response = client.post(f"/classify/{item_id}")
    
    assert response.status_code == 200
    classification = response.json()
    assert "category" in classification
    assert "tag" in classification 