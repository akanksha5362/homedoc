"""
RAG foundation (Day 3.2 §21). NOT IMPLEMENTED — interfaces only, so the
seam exists and nothing downstream needs to change shape when a real
implementation lands. Calling any method here raises NotImplementedError
deliberately; nothing in this codebase calls these yet.

Planned architecture (documented, not built):
    Document ingestion -> Chunking -> Embedding -> Metadata -> pgvector
    storage -> similarity search -> context construction -> LLM.

Knowledge sources this is intended for (Day 3.2 §21): HomeDoc FAQs,
policies, appointment rules, service info, doctor info, approved health
education. Explicitly NOT for medical records — those stay structured
data behind consent checks (see Architecture v1 §T), never dumped into a
vector index (Day 3.2 §21: "Do not dump the patient's entire medical
history into vector search").

Vector search strategy: pgvector on the existing PostgreSQL instance
(Architecture v1 §I already chose this over a dedicated vector DB for
MVP-adjacent RAG needs) — no new datastore required when this is built.
"""
from __future__ import annotations

from abc import ABC, abstractmethod
from dataclasses import dataclass


@dataclass
class RetrievedChunk:
    content: str
    source: str
    score: float


class EmbeddingProvider(ABC):
    @abstractmethod
    async def embed(self, text: str) -> list[float]:
        raise NotImplementedError


class RAGService(ABC):
    @abstractmethod
    async def ingest_document(self, *, source: str, content: str, metadata: dict) -> None:
        raise NotImplementedError

    @abstractmethod
    async def retrieve(self, *, query: str, top_k: int = 5) -> list[RetrievedChunk]:
        raise NotImplementedError


class NotImplementedRAGService(RAGService):
    """Default binding until a real implementation lands — fails loudly
    and immediately rather than silently returning empty results, so a
    future caller can't mistake "not built" for "no matches found."
    """

    async def ingest_document(self, *, source: str, content: str, metadata: dict) -> None:
        raise NotImplementedError("RAG ingestion is not implemented yet (Day 4+ scope).")

    async def retrieve(self, *, query: str, top_k: int = 5) -> list[RetrievedChunk]:
        raise NotImplementedError("RAG retrieval is not implemented yet (Day 4+ scope).")
