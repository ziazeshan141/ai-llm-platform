from fastapi import FastAPI,Request,Response,HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic_settings import BaseSettings
import httpx
class S(BaseSettings):
    AUTH_SERVICE_URL:str="http://localhost:8001"; AI_SERVICE_URL:str="http://localhost:8002"; RAG_SERVICE_URL:str="http://localhost:8003"
s=S();app=FastAPI(title="API Gateway")
app.add_middleware(CORSMiddleware,allow_origins=["http://localhost:5173","http://localhost:8088"],allow_methods=["*"],allow_headers=["*"])
@app.get("/health")
def health(): return {"status":"healthy","service":"api-gateway"}
async def proxy(req:Request,url:str):
    try:
        async with httpx.AsyncClient(timeout=120) as c:r=await c.request(req.method,url,params=req.query_params,content=await req.body(),headers={k:v for k,v in req.headers.items() if k.lower() not in {"host","content-length"}})
    except httpx.RequestError: raise HTTPException(503,"Upstream unavailable")
    return Response(r.content,status_code=r.status_code,media_type=r.headers.get("content-type"))
@app.api_route("/api/v1/auth/{p:path}",methods=["GET","POST","PUT","DELETE","PATCH"])
async def auth(p:str,req:Request):return await proxy(req,f"{s.AUTH_SERVICE_URL}/api/v1/auth/{p}")
@app.api_route("/api/v1/ai/{p:path}",methods=["GET","POST","PUT","DELETE","PATCH"])
async def ai(p:str,req:Request):return await proxy(req,f"{s.AI_SERVICE_URL}/api/v1/ai/{p}")
@app.api_route("/api/v1/rag/{p:path}",methods=["GET","POST","PUT","DELETE","PATCH"])
async def rag(p:str,req:Request):return await proxy(req,f"{s.RAG_SERVICE_URL}/api/v1/rag/{p}")
