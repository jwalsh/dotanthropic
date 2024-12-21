import os
import socket
import requests
import time
from typing import Optional, Dict, Any, List
from dataclasses import dataclass
from pydantic import BaseModel

class Country(BaseModel):
    name: str
    capital: str
    languages: List[str]

def test_structured_output(host: str, proxy_settings: Optional[Dict[str, str]] = None) -> None:
    """Test structured output functionality with Ollama."""
    print("\n=== Testing Structured Output ===")
    print(f"Host: {host}")
    
    # Define the format schema
    format_schema = {
        "type": "object",
        "properties": {
            "name": {"type": "string"},
            "capital": {"type": "string"},
            "languages": {
                "type": "array",
                "items": {"type": "string"}
            }
        },
        "required": ["name", "capital", "languages"]
    }
    
    # Prepare the chat request
    data = {
        "model": "llama3.1",
        "messages": [{"role": "user", "content": "Tell me about Canada."}],
        "stream": False,
        "format": format_schema
    }
    
    try:
        start = time.time()
        response = requests.post(
            f"{host}/api/chat",
            json=data,
            proxies=proxy_settings,
            timeout=30  # Longer timeout for model inference
        )
        duration = time.time() - start
        
        if response.status_code == 200:
            result = response.json()
            print(f"✅ Success! Response time: {duration:.2f}s")
            
            # Parse the response using Pydantic
            content = result.get('message', {}).get('content', '{}')
            if isinstance(content, str):
                import json
                content = json.loads(content)
            
            country = Country(**content)
            print("\nStructured Response:")
            print(f"Name: {country.name}")
            print(f"Capital: {country.capital}")
            print(f"Languages: {', '.join(country.languages)}")
        else:
            print(f"❌ Failed with status code: {response.status_code}")
            print(f"Response: {response.text}")
            
    except Exception as e:
        print(f"❌ Error: {str(e)}")

def test_connection(name: str, host: str, proxy_settings: Optional[Dict[str, str]] = None) -> None:
    """Test connection to Ollama server with optional proxy settings."""
    print(f"\n=== Running {name} ===")
    print(f"Host: {host}")
    print(f"Proxy settings: {proxy_settings or 'None'}")
    
    hostname = host.split("://")[-1].split(":")[0]
    ip = resolve_host(hostname)
    print(f"DNS resolution for {hostname}: {ip}")
    
    try:
        start = time.time()
        response = requests.get(
            f"{host}/api/tags",
            proxies=proxy_settings,
            timeout=5,
            headers={'Host': 'localhost:11434'}
        )
        duration = time.time() - start
        
        if response.status_code == 200:
            models = response.json().get('models', [])
            print(f"✅ Success! Response time: {duration:.2f}s")
            print(f"Found {len(models)} models:")
            for model in models[:3]:
                print(f"  - {model.get('name')}")
            if len(models) > 3:
                print(f"  ... and {len(models)-3} more")
        else:
            print(f"❌ Failed with status code: {response.status_code}")
            print(f"Response: {response.text}")
            
    except requests.exceptions.RequestException as e:
        print(f"❌ Error: {str(e)}")

def resolve_host(hostname: str) -> str:
    """Attempt to resolve hostname to IP address."""
    try:
        return socket.gethostbyname(hostname)
    except socket.gaierror:
        return "Unable to resolve"

def main():
    proxy_settings = {
        "http": "http://host.docker.internal:8080",
        "https": "http://host.docker.internal:8080"
    }
    
    # Use the host that we know works from previous tests
    working_host = "http://127.0.0.1:11434"
    
    # Basic connectivity test
    test_connection("Basic Connectivity", working_host, proxy_settings)
    
    # Test structured output
    test_structured_output(working_host, proxy_settings)
    
    # Print environment information
    print("\n=== Environment Information ===")
    for key in ['HTTP_PROXY', 'HTTPS_PROXY', 'no_proxy', 'OLLAMA_HOST']:
        print(f"{key}: {os.environ.get(key, 'Not set')}")

if __name__ == "__main__":
    main()
