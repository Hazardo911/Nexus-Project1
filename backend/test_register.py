import requests
import uuid

def test_register():
    url = "http://127.0.0.1:8000/register"
    
    # Generate a unique email for each test run
    unique_id = uuid.uuid4().hex[:6]
    payload = {
        "name": "Test User",
        "email": f"test_{unique_id}@example.com",
        "password": "securepassword123"
    }
    
    print(f"Attempting to register user: {payload['email']}...")
    
    try:
        response = requests.post(url, json=payload)
        
        if response.status_code == 200:
            data = response.json()
            print("\nREGISTRATION SUCCESSFUL!")
            print(f"User ID: {data.get('user_id')}")
            print(f"Access Token: {data.get('access_token')[:30]}...")
            print(f"Token Type: {data.get('token_type')}")
        else:
            print(f"\nREGISTRATION FAILED (Status: {response.status_code})")
            print(f"Error: {response.text}")
            
    except requests.exceptions.ConnectionError:
        print("\nERROR: Backend not reachable. Make sure FastAPI is running on http://127.0.0.1:8000")

if __name__ == "__main__":
    test_register()
