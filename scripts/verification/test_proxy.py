#!/usr/bin/env python3

import os
import sys
from anthropic import Anthropic

def test_anthropic_connection():
    """Test connection to Anthropic API through proxy."""
    # Print proxy settings and versions
    print(f"HTTP Proxy: {os.environ.get('HTTP_PROXY', 'Not set')}")
    print(f"HTTPS Proxy: {os.environ.get('HTTPS_PROXY', 'Not set')}")
    print(f"No Proxy: {os.environ.get('NO_PROXY', 'Not set')}")
    print(f"Requests CA Bundle: {os.environ.get('REQUESTS_CA_BUNDLE', 'Not set')}")
    
    api_key = os.environ.get("ANTHROPIC_API_KEY")
    if not api_key:
        print("\nError: ANTHROPIC_API_KEY environment variable not set")
        print("Please set your API key with: export ANTHROPIC_API_KEY='your-key-here'")
        return False
    
    try:
        # Initialize client
        client = Anthropic(api_key=api_key)
        
        # Test message using current API format
        print("\nSending test message...")
        message = client.messages.create(
            model="claude-3-5-sonnet-20241022",
            messages=[
                {
                    "role": "user",
                    "content": "Say 'proxy test successful' if you can read this."
                }
            ]
        )
        
        print("\nResponse:")
        if hasattr(message, 'content'):
            print(message.content[0].text)
        else:
            print(message)
        return True
        
    except Exception as e:
        print(f"\nError occurred: {e}")
        print("\nTroubleshooting tips:")
        print("1. Check if your proxy is running and accessible")
        print("2. Verify your SSL certificates are properly installed")
        print("3. Ensure your API key is valid")
        print("4. Check if proxy environment variables are correctly set")
        print("\nDebug Information:")
        try:
            import requests
            try:
                response = requests.get('https://example.com')
                print(f"Test HTTPS request status: {response.status_code}")
            except Exception as req_e:
                print(f"HTTPS test failed: {req_e}")
        except ImportError:
            print("requests library not available for debug testing")
        return False

def main():
    """Main function to run the test and return appropriate exit code."""
    try:
        import pkg_resources
        anthropic_version = pkg_resources.get_distribution('anthropic').version
        print(f"Anthropic SDK version: {anthropic_version}")
    except Exception as e:
        print("Could not determine Anthropic SDK version")

    success = test_anthropic_connection()
    sys.exit(0 if success else 1)

if __name__ == "__main__":
    main()
