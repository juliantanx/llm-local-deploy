# RAG (Retrieval-Augmented Generation) Guide

This guide explains how to set up and use RAG capabilities with LLM Local Deploy.

## What is RAG?

RAG combines LLMs with a knowledge base, allowing the model to:
- Answer questions about your documents
- Reduce hallucinations with grounded responses
- Work with private/internal documents

## Architecture

```
Documents → Embeddings → Vector DB → Retrieved Context → LLM → Response
```

Components:
- **Ollama**: LLM inference + embeddings
- **ChromaDB**: Vector database for document storage
- **Open WebUI**: Document upload interface

## Quick Start

### 1. Start with RAG Support

```bash
# Enable RAG by setting environment variable
ENABLE_RAG=true ./scripts/start.sh

# Or use the RAG compose file directly
docker compose -f docker-compose.yml -f docker-compose.rag.yml up -d
```

### 2. Pull Embedding Model

```bash
# Pull the embedding model
ollama pull nomic-embed-text
```

### 3. Upload Documents

1. Open WebUI at http://localhost:3000
2. Go to **Workspace** → **Documents**
3. Upload your documents (PDF, TXT, MD, etc.)

### 4. Use RAG

When chatting, the system will automatically retrieve relevant documents and include them in the context.

## Configuration

### Environment Variables

```bash
# In .env file
ENABLE_RAG=true

# Embedding settings
RAG_EMBEDDING_ENGINE=ollama
RAG_EMBEDDING_MODEL=nomic-embed-text

# ChromaDB settings
CHROMA_HOST=chromadb
CHROMA_PORT=8000
```

### Embedding Models

| Model | Dimension | Size | Best For |
|-------|-----------|------|----------|
| nomic-embed-text | 768 | ~600MB | General purpose |
| mxbai-embed-large | 1024 | ~1GB | High quality |
| all-minilm | 384 | ~100MB | Fast, lightweight |

### Chunking Settings

Configure how documents are split:

```bash
# In Open WebUI settings
CHUNK_SIZE=1500          # Characters per chunk
CHUNK_OVERLAP=100        # Overlap between chunks
TOP_K=4                  # Number of chunks to retrieve
```

## Supported Document Types

- **Text**: `.txt`, `.md`, `.rst`
- **Documents**: `.pdf`, `.docx`, `.pptx`
- **Code**: `.py`, `.js`, `.java`, etc.
- **Data**: `.csv`, `.json`, `.xml`

## API Usage

### Add Document via API

```python
import requests

# Upload document
files = {'file': open('document.pdf', 'rb')}
response = requests.post(
    'http://localhost:3000/api/v1/documents/',
    files=files
)
```

### Query with RAG

```python
from openai import OpenAI

client = OpenAI(
    base_url="http://localhost:11434/v1",
    api_key="ollama"
)

# RAG is automatically applied when documents exist
response = client.chat.completions.create(
    model="llama3.2:3b",
    messages=[
        {"role": "user", "content": "What does the document say about X?"}
    ]
)
```

### Direct ChromaDB Access

```python
import chromadb

client = chromadb.HttpClient(
    host='localhost',
    port=8000
)

# Get collection
collection = client.get_collection('documents')

# Query
results = collection.query(
    query_texts=["search query"],
    n_results=5
)
```

## Best Practices

### Document Preparation

1. **Clean documents**: Remove headers, footers, navigation
2. **Split large files**: Documents > 100 pages should be split
3. **Use clear formatting**: Well-structured documents work better

### Chunking Strategy

| Document Type | Chunk Size | Overlap |
|---------------|------------|---------|
| Technical docs | 1000-1500 | 100-200 |
| Legal/contracts | 500-800 | 100 |
| General text | 1500-2000 | 150 |
| Code | 500-1000 | 50 |

### Query Optimization

1. **Be specific**: More specific queries return better results
2. **Use keywords**: Important terms help retrieval
3. **Ask follow-ups**: Context is maintained in conversation

## Performance Tuning

### Memory Requirements

| Collection Size | ChromaDB RAM |
|-----------------|--------------|
| < 10k chunks | 2GB |
| 10k-100k chunks | 4GB |
| > 100k chunks | 8GB+ |

### Indexing

ChromaDB uses HNSW indexing by default:

```bash
# In ChromaDB configuration
CHROMA_INDEX_HNSW_M=16       # Higher = more accurate, slower
CHROMA_INDEX_HNSW_EF=100     # Higher = more accurate, slower
```

## Troubleshooting

### ChromaDB Connection Error

```
Error: Cannot connect to ChromaDB
```

**Solutions:**
1. Check ChromaDB is running: `docker compose ps`
2. Verify port: `curl http://localhost:8000/api/v1/heartbeat`
3. Check logs: `docker compose logs chromadb`

### Embedding Model Not Found

```
Error: Model 'nomic-embed-text' not found
```

**Solution:**
```bash
ollama pull nomic-embed-text
```

### Slow Retrieval

**Solutions:**
1. Reduce `TOP_K` setting
2. Use smaller embedding model
3. Increase ChromaDB memory
4. Optimize chunk size

### Out of Memory

**Solutions:**
1. Use smaller embedding model (`all-minilm`)
2. Reduce collection size
3. Increase Docker memory limit

## Advanced: Custom Embeddings

### Use Custom Embedding Endpoint

```bash
# In .env
RAG_EMBEDDING_ENGINE=openai
OPENAI_API_KEY=sk-xxx
OPENAI_EMBEDDING_MODEL=text-embedding-3-small
```

### Hybrid Search

Combine keyword and semantic search:

```python
# In Open WebUI settings
ENABLE_HYBRID_SEARCH=true
BM25_WEIGHT=0.3
SEMANTIC_WEIGHT=0.7
```

## Example: Building a Knowledge Base

```bash
# 1. Start with RAG
ENABLE_RAG=true ./scripts/start.sh

# 2. Pull models
ollama pull llama3.2:3b
ollama pull nomic-embed-text

# 3. Upload documents via WebUI or API

# 4. Query
curl http://localhost:11434/api/chat -d '{
  "model": "llama3.2:3b",
  "messages": [
    {"role": "user", "content": "Summarize the key points from my documents"}
  ]
}'
```