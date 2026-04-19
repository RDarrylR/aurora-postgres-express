"""FastAPI app backed by Aurora PostgreSQL Express.

Run with:
    uvicorn app:app --reload --port 8000
"""

from __future__ import annotations

from contextlib import asynccontextmanager
from typing import Any

from fastapi import FastAPI, HTTPException
from pydantic import BaseModel, Field

import crud


class NoteCreate(BaseModel):
    title: str = Field(min_length=1, max_length=200)
    body: str = Field(default="", max_length=10_000)


class NoteUpdate(BaseModel):
    title: str = Field(min_length=1, max_length=200)
    body: str = Field(default="", max_length=10_000)


@asynccontextmanager
async def lifespan(app: FastAPI):
    yield


app = FastAPI(title="Aurora Express Notes", lifespan=lifespan)


@app.get("/healthz")
def healthz() -> dict[str, str]:
    return {"status": "ok"}


@app.get("/notes")
def list_notes(limit: int = 20) -> list[dict[str, Any]]:
    return crud.list_notes(limit)


@app.post("/notes", status_code=201)
def create_note(payload: NoteCreate) -> dict[str, Any]:
    note_id = crud.create_note(payload.title, payload.body)
    return crud.get_note(note_id) or {"id": note_id}


@app.get("/notes/{note_id}")
def read_note(note_id: int) -> dict[str, Any]:
    note = crud.get_note(note_id)
    if note is None:
        raise HTTPException(status_code=404, detail="Note not found")
    return note


@app.put("/notes/{note_id}")
def update_note(note_id: int, payload: NoteUpdate) -> dict[str, Any]:
    if not crud.update_note(note_id, payload.title, payload.body):
        raise HTTPException(status_code=404, detail="Note not found")
    return crud.get_note(note_id)  # type: ignore[return-value]


@app.delete("/notes/{note_id}", status_code=204)
def delete_note(note_id: int) -> None:
    if not crud.delete_note(note_id):
        raise HTTPException(status_code=404, detail="Note not found")
