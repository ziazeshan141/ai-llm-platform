# AI LLM Platform — Developer Handoff

Application/developer-owned source only.

Included: Auth, API Gateway, AI service, real RAG service (chunking + sentence-transformer embeddings + pgvector), React frontend, database initialization SQL.

Intentionally excluded because the DevOps engineer will write them: Dockerfiles, docker-compose.yml, Kubernetes, Terraform, CI/CD, ArgoCD, monitoring and vLLM deployment.

Runtime: Python 3.12, Node 22, PostgreSQL 16 with pgvector, and an OpenAI-compatible LLM endpoint.
Ports: gateway 8000, auth 8001, AI 8002, RAG 8003.
