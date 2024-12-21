import os
import json
import requests
import tempfile
import subprocess
import time
from typing import List, Optional
from pydantic import BaseModel, field_validator

class File(BaseModel):
    filename: str
    contents: str

    @field_validator('filename')
    @classmethod
    def validate_filename(cls, v: str) -> str:
        valid_extensions = ['.scm', '.md']
        if not any(v.strip().endswith(ext) for ext in valid_extensions):
            raise ValueError(f"Filename must end with one of {valid_extensions}")
        return v.strip()

    @field_validator('contents')
    @classmethod
    def validate_contents(cls, v: str, info) -> str:
        filename = info.data.get('filename', '')
        if filename.endswith('.scm'):
            required_elements = {
                '(define fib-tail': "Must implement fib-tail function",
                'define': "Scheme file must contain definitions",
                'if': "Must include conditional logic",
                'accumulator': "Must use accumulator for tail recursion",
            }
            for element, message in required_elements.items():
                if element not in v:
                    raise ValueError(message)
        return v

class DirectoryListing(BaseModel):
    overview: str
    files: List[File]

    @field_validator('overview')
    @classmethod
    def validate_overview(cls, v: str) -> str:
        if len(v.strip()) < 10:
            raise ValueError("Overview must be at least 10 characters")
        required_terms = ['fibonacci', 'tail recursion', 'scheme']
        found_terms = [term for term in required_terms if term in v.lower()]
        if not found_terms:
            raise ValueError(f"Overview must mention: {', '.join(required_terms)}")
        return v

def test_scheme_implementation(contents: str) -> tuple[bool, str]:
    """Test the Scheme implementation using Guile."""
    test_wrapper = """
    (define (test-fib-tail)
      (and 
        (= (fib-tail 0) 0)
        (= (fib-tail 1) 1)
        (= (fib-tail 5) 5)
        (= (fib-tail 10) 55)
        (= (fib-tail 20) 6765)))
    
    ;; Run tests
    (display "Running tests...\n")
    (display (if (test-fib-tail)
               "All tests passed!\n"
               "Tests failed!\n"))
    """
    
    try:
        with tempfile.NamedTemporaryFile(mode='w', suffix='.scm') as f:
            f.write(contents + "\n" + test_wrapper)
            f.flush()
            result = subprocess.run(
                ['guile', f.name],
                capture_output=True,
                text=True,
                timeout=5
            )
            return result.returncode == 0, result.stdout
    except subprocess.TimeoutExpired:
        return False, "Timeout while executing Scheme code"
    except Exception as e:
        return False, str(e)

def test_model_structured(host: str, model: str, proxy_settings: Optional[dict] = None) -> None:
    """Test a model's ability to generate a Scheme implementation."""
    print(f"\n=== Testing Model: {model} ===")
    
    format_schema = {
        "type": "object",
        "properties": {
            "overview": {"type": "string"},
            "files": {
                "type": "array",
                "items": {
                    "type": "object",
                    "properties": {
                        "filename": {"type": "string"},
                        "contents": {"type": "string"}
                    },
                    "required": ["filename", "contents"]
                }
            }
        },
        "required": ["overview", "files"]
    }
    
    prompt = """Create a Scheme implementation of the Fibonacci sequence using tail recursion with an accumulator parameter.
The implementation should be in a file named 'fib.scm' and must:
1. Define a function named 'fib-tail' that uses proper tail recursion
2. Use an accumulator parameter to maintain state
3. Handle edge cases (0 and 1) correctly
4. Include comments explaining the algorithm

Also create a README.md that explains:
1. The implementation approach
2. Why tail recursion is more efficient
3. Example usage

Return these in a structured format with a clear overview."""

    data = {
        "model": model,
        "messages": [{"role": "user", "content": prompt}],
        "stream": False,
        "format": format_schema
    }
    
    try:
        start = time.time()
        response = requests.post(
            f"{host}/api/chat",
            json=data,
            proxies=proxy_settings,
            timeout=30
        )
        duration = time.time() - start
        
        if response.status_code == 200:
            result = response.json()
            print(f"✅ Response received! Time: {duration:.2f}s")
            
            try:
                content = result.get('message', {}).get('content', '{}')
                if isinstance(content, str):
                    content = json.loads(content)
                
                listing = DirectoryListing(**content)
                print("\nValidation successful!")
                print(f"Overview: {listing.overview}")
                
                for file in listing.files:
                    print(f"\n- {file.filename}:")
                    preview = file.contents[:200] + "..." if len(file.contents) > 200 else file.contents
                    print(f"  {preview}")
                    
                    if file.filename.endswith('.scm'):
                        print("\nTesting Scheme implementation...")
                        success, output = test_scheme_implementation(file.contents)
                        if success:
                            print("✅ Scheme tests passed!")
                            print(f"Output: {output}")
                        else:
                            print("❌ Scheme tests failed!")
                            print(f"Error: {output}")
                
            except Exception as e:
                print(f"❌ Validation error: {str(e)}")
                
        else:
            print(f"❌ Failed with status code: {response.status_code}")
            print(f"Response: {response.text}")
            
    except Exception as e:
        print(f"❌ Error: {str(e)}")

def main():
    host = "http://127.0.0.1:11434"
    proxy_settings = {
        "http": "http://host.docker.internal:8080",
        "https": "http://host.docker.internal:8080"
    }
    
    models = [
        "codellama:latest",  # Specialized for code generation
        "phi3:latest",       # Fast and efficient
        "llama3.2:latest",   # Good structured output
        "llama3.1:latest",   # Good structured output
        "zephyr:latest",     # Backup option
        "hf.co/MaziyarPanahi/Qwen2.5-7B-Instruct-abliterated-v2-GGUF:Q5_K_M",
        "jwalsh:latest"      # Personal model
    ]
    
    for model in models:
        test_model_structured(host, model, proxy_settings)

if __name__ == "__main__":
    main()
