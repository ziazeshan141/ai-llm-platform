from contextlib import asynccontextmanager

from fastapi import Depends, FastAPI
from pgvector.sqlalchemy import Vector
from pydantic import BaseModel
from pydantic_settings import BaseSettings
from sentence_transformers import SentenceTransformer
from sqlalchemy import ForeignKey, Integer, String, Text, create_engine, text
from sqlalchemy.orm import (
    Mapped,
    Session,
    declarative_base,
    mapped_column,
    sessionmaker,
)

from .metrics import setup_metrics


# ============================================================
# Configuration
# ============================================================

class Settings(BaseSettings):
    DATABASE_URL: str = (
        "postgresql://postgres:postgres@localhost:5432/rag_db"
    )

    EMBEDDING_MODEL: str = (
        "sentence-transformers/all-MiniLM-L6-v2"
    )

    EMBEDDING_DIMENSION: int = 384
    CHUNK_SIZE: int = 700
    CHUNK_OVERLAP: int = 100
    TOP_K: int = 5


settings = Settings()


# ============================================================
# Database
# ============================================================

engine = create_engine(
    settings.DATABASE_URL,
    pool_pre_ping=True,
)

SessionLocal = sessionmaker(bind=engine)

Base = declarative_base()


def get_db():
    db = SessionLocal()

    try:
        yield db
    finally:
        db.close()


# ============================================================
# Database Models
# ============================================================

class Document(Base):
    __tablename__ = "documents"

    id: Mapped[int] = mapped_column(
        Integer,
        primary_key=True,
    )

    title: Mapped[str] = mapped_column(
        String(255),
    )

    content: Mapped[str] = mapped_column(
        Text,
    )


class Chunk(Base):
    __tablename__ = "document_chunks"

    id: Mapped[int] = mapped_column(
        Integer,
        primary_key=True,
    )

    document_id: Mapped[int] = mapped_column(
        ForeignKey("documents.id"),
    )

    chunk_index: Mapped[int] = mapped_column(
        Integer,
    )

    content: Mapped[str] = mapped_column(
        Text,
    )

    embedding = mapped_column(
        Vector(settings.EMBEDDING_DIMENSION)
    )


# ============================================================
# API Models
# ============================================================

class DocumentInput(BaseModel):
    title: str
    content: str


class SearchInput(BaseModel):
    query: str
    top_k: int | None = None


# ============================================================
# Text Chunking
# ============================================================

def create_chunks(text_value: str) -> list[str]:
    text_value = " ".join(
        text_value.split()
    )

    chunks = []
    start = 0

    while start < len(text_value):
        end = min(
            start + settings.CHUNK_SIZE,
            len(text_value),
        )

        chunks.append(
            text_value[start:end]
        )

        if end < len(text_value):
            start = (
                end
                - settings.CHUNK_OVERLAP
            )
        else:
            start = end

    return chunks


# ============================================================
# Embedding Model
# ============================================================

embedding_model = None


# ============================================================
# Application Startup
# ============================================================

@asynccontextmanager
async def lifespan(app: FastAPI):
    global embedding_model

    # Make sure pgvector is enabled.
    with engine.begin() as connection:
        connection.execute(
            text(
                "CREATE EXTENSION IF NOT EXISTS vector"
            )
        )

    # Create tables if they do not already exist.
    Base.metadata.create_all(engine)

    # Load embedding model once during startup.
    embedding_model = SentenceTransformer(
        settings.EMBEDDING_MODEL
    )

    yield


# ============================================================
# FastAPI Application
# ============================================================

app = FastAPI(
    title="RAG Service",
    version="1.0.0",
    lifespan=lifespan,
)


# ============================================================
# Prometheus Metrics
# ============================================================

setup_metrics(
    app,
    service_name="rag-service",
)


# ============================================================
# Health
# ============================================================

@app.get("/health")
def health():
    return {
        "status": "healthy",
        "service": "rag-service",
        "retrieval": "pgvector",
    }


# ============================================================
# Add Document
# ============================================================

@app.post("/api/v1/rag/documents")
def add_document(
    request: DocumentInput,
    db: Session = Depends(get_db),
):
    # Split document into chunks.
    document_chunks = create_chunks(
        request.content
    )

    # Generate vector embeddings.
    embeddings = embedding_model.encode(
        document_chunks,
        normalize_embeddings=True,
    ).tolist()

    # Store original document.
    document = Document(
        title=request.title,
        content=request.content,
    )

    db.add(document)
    db.flush()

    # Store chunks and embeddings.
    for index, (
        chunk_content,
        embedding,
    ) in enumerate(
        zip(
            document_chunks,
            embeddings,
        )
    ):
        db.add(
            Chunk(
                document_id=document.id,
                chunk_index=index,
                content=chunk_content,
                embedding=embedding,
            )
        )

    db.commit()

    return {
        "id": document.id,
        "title": document.title,
        "chunks_created": len(
            document_chunks
        ),
    }


# ============================================================
# Semantic Search
# ============================================================

@app.post("/api/v1/rag/search")
def search_documents(
    request: SearchInput,
    db: Session = Depends(get_db),
):
    # Convert search query into an embedding.
    query_embedding = embedding_model.encode(
        [request.query],
        normalize_embeddings=True,
    )[0].tolist()

    # Calculate cosine distance.
    distance = Chunk.embedding.cosine_distance(
        query_embedding
    )

    # Search nearest vectors.
    results = (
        db.query(
            Chunk,
            Document.title,
            distance.label("distance"),
        )
        .join(
            Document,
            Document.id == Chunk.document_id,
        )
        .order_by(distance)
        .limit(
            request.top_k
            or settings.TOP_K
        )
        .all()
    )

    return [
        {
            "document_id": chunk.document_id,
            "document_title": title,
            "chunk_id": chunk.id,
            "chunk_index": chunk.chunk_index,
            "content": chunk.content,
            "distance": float(score),
        }
        for chunk, title, score in results
    ]