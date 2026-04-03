import os
from sqlalchemy import create_engine
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker
from dotenv import load_dotenv

load_dotenv()

DATABASE_URL = os.getenv("DATABASE_URL")

db_url = os.getenv("DATABASE_URL")

# ✅ Handle CI mode FIRST
if not DATABASE_URL:
    if os.getenv("CI") == "true":
        print("⚡ CI mode: using dummy SQLite DB")
        DATABASE_URL = "sqlite:///:memory:"
        engine = create_engine(DATABASE_URL)
    else:
        raise ValueError("DATABASE_URL not set in environment")
else:
    engine = create_engine(DATABASE_URL, connect_args={"sslmode": "require"})

SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

Base = declarative_base()
