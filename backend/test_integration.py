import uuid
from datetime import datetime
from app.db.database import SessionLocal
from app.db import crud, models

def run_integration_test():
    db = SessionLocal()
    try:
        print("--- STARTING INTEGRATION TEST ---")
        
        # 1. Create User
        email = f"user_{uuid.uuid4().hex[:6]}@nexus.ai"
        user = crud.create_user(db, name="Integration Tester", email=email)
        print(f"[OK] User created: {user.id}")

        # 2. Training Session Flow
        print("\nTesting Training Flow...")
        session_t = crud.create_session(db, user_id=user.id, mode="training")
        print(f"[OK] Training session created: {session_t.id}")
        
        t_record = crud.insert_training_session(
            db, 
            session_id=session_t.id,
            score=88.5,
            symmetry=94.0,
            stability=82.0,
            speed=0.95,
            feedback="Consistent depth on squats."
        )
        print(f"[OK] Training record inserted.")

        # 3. Movement Metrics
        print("\nTesting Movement Metrics...")
        metric1 = crud.insert_movement_metric(db, session_t.id, "left_knee", 115.2, 0.4, 0.1)
        metric2 = crud.insert_movement_metric(db, session_t.id, "right_knee", 112.8, 0.45, 0.12)
        print(f"[OK] Movement metrics inserted.")

        # 4. Training Summary
        print("\nTesting Training Summary...")
        t_summary = crud.upsert_training_summary(
            db, 
            user_id=user.id,
            weekly_avg=85.0,
            monthly_avg=82.5,
            symmetry_trend=2.5,
            stability_trend=-1.2,
            speed_trend=0.05
        )
        print(f"[OK] Training summary upserted.")

        # 5. Rehab Session Flow
        print("\nTesting Rehab Flow...")
        session_r = crud.create_session(db, user_id=user.id, mode="rehab")
        print(f"[OK] Rehab session created: {session_r.id}")
        
        r_record = crud.insert_rehab_session(
            db,
            session_id=session_r.id,
            injury_type="ACL",
            stage="mid",
            score=75.0,
            safety=1.0,
            rom=95.0,
            stability=78.0,
            decision="Mid-stage recovery on track.",
            feedback="Avoid twisting under load."
        )
        print(f"[OK] Rehab record inserted.")

        # 6. Rehab Summary
        print("\nTesting Rehab Summary...")
        r_summary = crud.upsert_rehab_summary(
            db,
            user_id=user.id,
            safe_rate=92.0,
            avg_rom=88.5,
            stability_trend=5.0,
            recovery_trend=15.0
        )
        print(f"[OK] Rehab summary upserted.")

        print("\n--- INTEGRATION TEST SUCCESSFUL: ALL TABLES COVERED ---")

    except Exception as e:
        print(f"\n[ERROR] Integration test failed: {e}")
        db.rollback()
    finally:
        db.close()

if __name__ == "__main__":
    run_integration_test()
