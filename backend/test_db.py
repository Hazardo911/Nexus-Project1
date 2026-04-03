from app.db.database import SessionLocal, engine, Base
from app.db import models, crud
import uuid

def test_db():
    # Create tables if they don't exist (Supabase tables should already exist but for testing local or new environments)
    # Base.metadata.create_all(bind=engine) # The user said schema already exists, so skipping.

    db = SessionLocal()
    try:
        # 1. Create a dummy user
        test_email = f"test_{uuid.uuid4().hex[:8]}@example.com"
        print(f"Creating user with email: {test_email}")
        user = crud.create_user(db, name="Test User", email=test_email)
        print(f"User created with ID: {user.id}")

        # 2. Create a session
        print("Creating session...")
        session = crud.create_session(db, user_id=user.id, mode="training")
        print(f"Session created with ID: {session.id}")

        # 3. Insert a training session record
        print("Inserting training record...")
        record = crud.insert_training_session(
            db, 
            session_id=session.id,
            score=95.0,
            symmetry=92.5,
            stability=88.0,
            speed=1.2,
            feedback="Great form, keep it up!"
        )
        print(f"Training record inserted for session: {record.session_id}")

        # 5. Insert a rehab session record
        print("Inserting rehab record...")
        rehab_record = crud.insert_rehab_session(
            db,
            session_id=session.id,
            injury_type="ACL",
            stage="early",
            score=85.0,
            safety=1.0, # Float as per schema
            rom=45.0,
            stability=90.0,
            decision="Safe to continue",
            feedback="Maintain good posture"
        )
        print(f"Rehab record inserted for session: {rehab_record.session_id}")

        print("\nDATABASE TEST SUCCESSFUL!")

    except Exception as e:
        print(f"\nDATABASE TEST FAILED: {e}")
        db.rollback()
    finally:
        db.close()

if __name__ == "__main__":
    test_db()
