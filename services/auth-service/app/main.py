from fastapi import FastAPI,Depends,HTTPException
from sqlalchemy.orm import Session
from passlib.context import CryptContext
from jose import jwt
from pydantic import BaseModel,EmailStr,Field
from app.database import Base,engine,get_db
from app.models.user import User
from app.config import settings
Base.metadata.create_all(bind=engine)
app=FastAPI(title="Auth Service")
pwd=CryptContext(schemes=["bcrypt"],deprecated="auto")
class Register(BaseModel):
    email:EmailStr; username:str; password:str=Field(min_length=8,max_length=72)
class Login(BaseModel):
    email:EmailStr; password:str
@app.get("/health")
def health(): return {"status":"healthy","service":"auth-service"}
@app.post("/api/v1/auth/register")
def register(x:Register,db:Session=Depends(get_db)):
    if db.query(User).filter((User.email==x.email)|(User.username==x.username)).first(): raise HTTPException(409,"User already exists")
    u=User(email=x.email,username=x.username,hashed_password=pwd.hash(x.password));db.add(u);db.commit();db.refresh(u)
    return {"id":u.id,"email":u.email,"username":u.username}
@app.post("/api/v1/auth/login")
def login(x:Login,db:Session=Depends(get_db)):
    u=db.query(User).filter(User.email==x.email).first()
    if not u or not pwd.verify(x.password,u.hashed_password): raise HTTPException(401,"Invalid credentials")
    return {"access_token":jwt.encode({"sub":str(u.id)},settings.JWT_SECRET_KEY,algorithm=settings.JWT_ALGORITHM),"token_type":"bearer"}
