import uvicorn
from main_with_auth import app

if __name__ == "__main__":
    uvicorn.run(
        "main_with_auth:app",
        host="0.0.0.0",
        port=8080,
        reload=True,
        log_level="info"
    )
