import logging
import os
from fastapi import FastAPI
from contextlib import asynccontextmanager
from app.core.ai.inference import get_model
from app.core.ai.model import CLASS_NAMES
from app.api.routes import analyze, demo, rehab, summary, stream

logging.basicConfig(level=logging.INFO)

@asynccontextmanager
async def lifespan(app: FastAPI):
    if os.getenv("CI") == "true":
        logging.info("⚡ CI mode: skipping model load")
    else:
        get_model()
        logging.info("Nexus model ready.")
    yield


app = FastAPI(title="Nexus AI Backend", version="2.0.0", lifespan=lifespan)

app.include_router(analyze.router, prefix="/analyze")
app.include_router(rehab.router, prefix="/rehab")
app.include_router(summary.router, prefix="/summary")
app.include_router(stream.router)
app.include_router(demo.router)


@app.get("/health")
def health():
    return {
        "status": "running",
        "model": "nexus_stgcn_v2",
        "classes": list(CLASS_NAMES.values()),
    }
