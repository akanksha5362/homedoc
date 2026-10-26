"""
Agent memory (Day 3.2 §22). Deliberately split into two narrow, in-memory
stores for the foundation stage — NOT a general-purpose cache the agent
can stuff anything into.

- ConversationMemory: raw message history for the current session only.
- SessionMemory: small structured facts extracted during the current task
  (e.g. "user is looking for a General Physician").

Explicitly NOT covered here (per Day 3.2 §22, these remain separate,
consent-gated, structured systems, never informal LLM memory):
- Long-term user context: not implemented — would need explicit consent
  and storage design, Day 4+ scope.
- Medical records: live in the real database behind the consent engine
  (Architecture v1 §T), never copied into this in-memory store.

Storage is in-process and non-persistent (foundation stage only) — a real
deployment needs a shared store (Redis, per Architecture v1's real-time
layer) so memory survives across backend instances/restarts.
"""
from __future__ import annotations

from dataclasses import dataclass, field


@dataclass
class ConversationMemory:
    session_id: str
    messages: list[dict[str, str]] = field(default_factory=list)  # [{"role": ..., "content": ...}]

    def add(self, *, role: str, content: str) -> None:
        self.messages.append({"role": role, "content": content})


@dataclass
class SessionMemory:
    session_id: str
    facts: dict[str, str] = field(default_factory=dict)


class InMemorySessionStore:
    def __init__(self) -> None:
        self._conversations: dict[str, ConversationMemory] = {}
        self._sessions: dict[str, SessionMemory] = {}

    def get_conversation(self, session_id: str) -> ConversationMemory:
        return self._conversations.setdefault(session_id, ConversationMemory(session_id=session_id))

    def get_session(self, session_id: str) -> SessionMemory:
        return self._sessions.setdefault(session_id, SessionMemory(session_id=session_id))
