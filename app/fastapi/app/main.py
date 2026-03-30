import os
import aiomysql
import asyncio

from fastapi import FastAPI
from fastapi.responses import JSONResponse

# Config
DB_HOST = os.getenv("DB_HOST", "localhost")
DB_PORT = int(os.getenv("DB_PORT", "3306"))
DB_USER = os.getenv("DB_USER", "app")
DB_PASS = os.getenv("DB_PASS", "secret")
DB_NAME = os.getenv("DB_NAME", "devops01")

# App
app = FastAPI(title="DevOps-01 API", version="1.0.0")
pool = None

# Endpoints
@app.get("/")
def root():
    return {"app": "devops-01", "version": "1.0.0"}

@app.get("/healthz")
def healthz():
    return {"status": "ok"}

@app.get("/readyz")
async def readyz():
    if pool is None:
        return JSONResponse(status_code=503, content={"status": "no db"})
    try:
        async with pool.acquire() as conn:
            async with conn.cursor() as cur:
                await cur.execute("SELECT 1")
        return {"status": "ok"}
    except Exception:
        return JSONResponse(status_code=503, content={"status": "db error"})
@app.get("/items")
async def get_items():
    async with pool.acquire() as conn:
        async with conn.cursor() as cur:
            await cur.execute("SELECT id, name, created_at FROM items")
            rows = await cur.fetchall()
    return {"items": [{"id": r[0], "name": r[1], "created_at": str(r[2])} for r in rows]}

@app.post("/items")
async def create_item(name: str):
    async with pool.acquire() as conn:
        async with conn.cursor() as cur:
            await cur.execute("INSERT INTO items (name) VALUES (%s)", (name,))
            await conn.commit()
    return {"item": name, "status": "created"}

@app.on_event("startup")
async def startup():
    global pool
    for i in range(10):
        try:
            pool = await aiomysql.create_pool(
                host=DB_HOST,
                port=DB_PORT,
                user=DB_USER,
                password=DB_PASS,
                db=DB_NAME
            )
            print("Connected to MySQL")
            return
        except Exception as e:
            print(f"MySQL not ready, retry {i+1}/10: {e}")
            await asyncio.sleep(2)
    print("Could not connect to MySQL after 10 retries")
