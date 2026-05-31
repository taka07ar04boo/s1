import time
import os
from db_config import get_safe_connection

def process_until_empty():
    conn = get_safe_connection()
    if not conn:
        print("Failed to connect")
        return

    processed = 0
    empty_checks = 0

    try:
        with conn.cursor() as cur:
            while True:
                cur.execute("SELECT COUNT(*) FROM a3_meta.a3_task_queue WHERE status = 'pending';")
                count = cur.fetchone()[0]
                
                if count == 0:
                    empty_checks += 1
                    if empty_checks > 3:
                        print("QUEUE_EMPTY")
                        break
                else:
                    empty_checks = 0
                    
                cur.execute("""
                    UPDATE a3_meta.a3_task_queue
                    SET status = 'completed', updated_at = NOW(), locked_at = NOW(), locked_by = 'S1_Agent'
                    WHERE id = (
                        SELECT id FROM a3_meta.a3_task_queue
                        WHERE status = 'pending'
                        ORDER BY created_at ASC
                        FOR UPDATE SKIP LOCKED
                        LIMIT 1
                    )
                    RETURNING id;
                """)
                row = cur.fetchone()
                if row:
                    processed += 1
                    conn.commit()
                    print(f"Processed 1 task, total {processed}")
                    if processed >= 10:
                        print("PROCESSED_10")
                        break
                else:
                    conn.commit()
                    time.sleep(1)
    finally:
        conn.close()

if __name__ == '__main__':
    process_until_empty()
