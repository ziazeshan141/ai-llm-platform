from fastapi import Depends, FastAPI, HTTPException
from jose import jwt
from passlib.context import CryptContext
from pydantic import BaseModel, EmailStr, Field
from sqlalchemy.orm import Session

from app.config import settings
from app.database import Base, engine, get_db
from app.models.user import User

from .metrics import setup_metrics


# ============================================================
# Database Initialization
# ============================================================

Base.metadata.create_all(
    bind=engine
)


# ============================================================
# FastAPI Application
# ============================================================

app = FastAPI(
    title="Auth Service",
    version="1.0.0",
)


# ============================================================
# Prometheus Metrics
# ============================================================

setup_metrics(
    app,
    service_name="auth-service",
)


# ============================================================
# Password Hashing
# ============================================================

password_context = CryptContext(
    schemes=["bcrypt"],
    deprecated="auto",
)


# ============================================================
# Request Models
# ============================================================

class RegisterRequest(BaseModel):
    email: EmailStr
    username: str

    password: str = Field(
        min_length=8,
        max_length=72,
    )


class LoginRequest(BaseModel):
    email: EmailStr
    password: str


# ============================================================
# Health Check
# ============================================================

@app.get("/health")
def health():
    return {
        "status": "healthy",
        "service": "auth-service",
    }


# ============================================================
# Register User
# ============================================================

@app.post("/api/v1/auth/register")
def register(
    request: RegisterRequest,
    db: Session = Depends(get_db),
):
    # Check whether email or username already exists.
    existing_user = (
        db.query(User)
        .filter(
            (User.email == request.email)
            | (User.username == request.username)
        )
        .first()
    )

    if existing_user:
        raise HTTPException(
            status_code=409,
            detail="User already exists",
        )

    # Hash the password before storing it.
    hashed_password = password_context.hash(
        request.password
    )

    # Create user.
    user = User(
        email=request.email,
        username=request.username,
        hashed_password=hashed_password,
    )

    db.add(user)
    db.commit()
    db.refresh(user)

    return {
        "id": user.id,
        "email": user.email,
        "username": user.username,
    }


# ============================================================
# Login
# ============================================================

@app.post("/api/v1/auth/login")
def login(
    request: LoginRequest,
    db: Session = Depends(get_db),
):
    # Find user by email.
    user = (
        db.query(User)
        .filter(
            User.email == request.email
        )
        .first()
    )

    # Validate credentials.
    if (
        not user
        or not password_context.verify(
            request.password,
            user.hashed_password,
        )
    ):
        raise HTTPException(
            status_code=401,
            detail="Invalid credentials",
        )

    # Generate JWT.
    access_token = jwt.encode(
        {
            "sub": str(user.id),
        },
        settings.JWT_SECRET_KEY,
        algorithm=settings.JWT_ALGORITHM,
    )

    return {
        "access_token": access_token,
        "token_type": "bearer",
    }