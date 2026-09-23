from contextlib import asynccontextmanager
from fastapi import FastAPI,Depends
from pydantic import BaseModel
from pydantic_settings import BaseSettings
from sqlalchemy import create_engine,text,Integer,String,Text,ForeignKey
from sqlalchemy.orm import declarative_base,sessionmaker,Session,Mapped,mapped_column
from pgvector.sqlalchemy import Vector
from sentence_transformers import SentenceTransformer
class S(BaseSettings):
    DATABASE_URL:str="postgresql://postgres:postgres@localhost:5432/rag_db";EMBEDDING_MODEL:str="sentence-transformers/all-MiniLM-L6-v2";EMBEDDING_DIMENSION:int=384;CHUNK_SIZE:int=700;CHUNK_OVERLAP:int=100;TOP_K:int=5
s=S();engine=create_engine(s.DATABASE_URL,pool_pre_ping=True);Local=sessionmaker(bind=engine);Base=declarative_base();model=None
class Document(Base):
    __tablename__="documents";id:Mapped[int]=mapped_column(Integer,primary_key=True);title:Mapped[str]=mapped_column(String(255));content:Mapped[str]=mapped_column(Text)
class Chunk(Base):
    __tablename__="document_chunks";id:Mapped[int]=mapped_column(Integer,primary_key=True);document_id:Mapped[int]=mapped_column(ForeignKey("documents.id"));chunk_index:Mapped[int]=mapped_column(Integer);content:Mapped[str]=mapped_column(Text);embedding=mapped_column(Vector(s.EMBEDDING_DIMENSION))
class DocIn(BaseModel):title:str;content:str
class SearchIn(BaseModel):query:str;top_k:int|None=None
def db():
    x=Local()
    try:yield x
    finally:x.close()
def chunks(t):
    t=" ".join(t.split());out=[];start=0
    while start<len(t):
        end=min(start+s.CHUNK_SIZE,len(t));out.append(t[start:end]);start=end-s.CHUNK_OVERLAP if end<len(t) else end
    return out
@asynccontextmanager
async def life(app):
    global model
    with engine.begin() as c:c.execute(text("CREATE EXTENSION IF NOT EXISTS vector"))
    Base.metadata.create_all(engine);model=SentenceTransformer(s.EMBEDDING_MODEL);yield
app=FastAPI(title="RAG Service",lifespan=life)
@app.get("/health")
def health():return {"status":"healthy","service":"rag-service","retrieval":"pgvector"}
@app.post("/api/v1/rag/documents")
def add(x:DocIn,d:Session=Depends(db)):
    cs=chunks(x.content);vs=model.encode(cs,normalize_embeddings=True).tolist();doc=Document(title=x.title,content=x.content);d.add(doc);d.flush()
    for i,(c,v) in enumerate(zip(cs,vs)):d.add(Chunk(document_id=doc.id,chunk_index=i,content=c,embedding=v))
    d.commit();return {"id":doc.id,"title":doc.title,"chunks_created":len(cs)}
@app.post("/api/v1/rag/search")
def search(x:SearchIn,d:Session=Depends(db)):
    v=model.encode([x.query],normalize_embeddings=True)[0].tolist();dist=Chunk.embedding.cosine_distance(v)
    rows=d.query(Chunk,Document.title,dist.label("distance")).join(Document,Document.id==Chunk.document_id).order_by(dist).limit(x.top_k or s.TOP_K).all()
    return [{"document_id":c.document_id,"document_title":title,"chunk_id":c.id,"chunk_index":c.chunk_index,"content":c.content,"distance":float(score)} for c,title,score in rows]
