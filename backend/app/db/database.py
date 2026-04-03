import os

from dotenv import load_dotenv
from sqlalchemy import create_engine
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker

load_dotenv()

DATABASE_URL = os.getenv("DATABASE_URL")

if not DATABASE_URL:
    if os.getenv("CI") == "true":
        DATABASE_URL = "sqlite:///:memory:"
        engine = create_engine(DATABASE_URL)
    else:
        raise ValueError("DATABASE_URL not set in environment")
else:
    engine = create_engine(DATABASE_URL, connect_args={"sslmode": "require"})

SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

Base = declarative_base()
