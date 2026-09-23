from fastapi import FastAPI,HTTPException
from pydantic import BaseModel
from pydantic_settings import BaseSettings
import httpx
class S(BaseSettings):
    LLM_BASE_URL:str="http://localhost:8000/v1";LLM_API_KEY:str="local-vllm";LLM_MODEL:str="qwen2.5-1.5b"
s=S();app=FastAPI(title="AI Service")
class Chat(BaseModel): message:str
@app.get("/health")
def health():return {"status":"healthy","service":"ai-service","model":s.LLM_MODEL}
@app.post("/api/v1/ai/chat")
async def chat(x:Chat):
    payload={"model":s.LLM_MODEL,"messages":[{"role":"user","content":x.message}]}
    try:
        async with httpx.AsyncClient(timeout=120) as c:r=await c.post(f"{s.LLM_BASE_URL}/chat/completions",json=payload,headers={"Authorization":f"Bearer {s.LLM_API_KEY}"})
        r.raise_for_status();d=r.json();return {"model":s.LLM_MODEL,"answer":d["choices"][0]["message"]["content"]}
    except Exception as e: raise HTTPException(503,f"LLM unavailable: {type(e).__name__}")
