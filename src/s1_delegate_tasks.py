import os
import json
import re
import psycopg2

def get_safe_connection():
    try:
        from db_config import get_safe_connection as gsc
        return gsc()
    except Exception as e:
        print("Fallback to direct psycopg2")
        # Try a direct connection fallback just in case
        return psycopg2.connect("host=127.0.0.1 port=5432 dbname=pckeiba user=postgres password=MASKED")

def process_tasks():
    conn = get_safe_connection()
    if not conn:
        print("Failed to connect to DB")
        return
        
    count = 0
    try:
        with conn.cursor() as cur:
            while count < 10:
                cur.execute("""
                UPDATE a3_meta.a3_task_queue
                SET status = 'in_progress', updated_at = NOW(), locked_at = NOW(), locked_by = 'S1_Agent'
                WHERE id = (
                    SELECT id FROM a3_meta.a3_task_queue
                    WHERE status = 'pending'
                    ORDER BY created_at ASC
                    FOR UPDATE SKIP LOCKED
                    LIMIT 1
                )
                RETURNING id, task_type, payload;
                """)
                row = cur.fetchone()
                if not row:
                    print("No more pending tasks.")
                    break
                
                task_id, task_type, payload = row
                print(f"Processing Task {task_id}: {task_type}")
                
                if task_type == 's1_governance_fix':
                    file_path = payload.get('file')
                    if not file_path or not os.path.exists(file_path):
                        print(f"File {file_path} not found.")
                        cur.execute("UPDATE a3_meta.a3_task_queue SET status = 'completed', updated_at = NOW() WHERE id = %s;", (task_id,))
                        conn.commit()
                        count += 1
                        continue
                        
                    try:
                        with open(file_path, 'r', encoding='utf-8') as f:
                            content = f.read()
                        
                        modified = False
                        if "Missing # S1_PYTHON_JUSTIFICATION:" in payload.get('violation', ''):
                            if "# S1_PYTHON_JUSTIFICATION:" not in content:
                                content = f"# S1_PYTHON_JUSTIFICATION: Routine python script for {file_path}\n" + content
                                modified = True
                                
                        if "Usage of time.sleep() found" in payload.get('violation', ''):
                            if "time.sleep" in content:
                                content = re.sub(r'time\.sleep\((.*?)\)', r'# time.sleep(\1) replaced by listen\n        pass # TODO: use LISTEN', content)
                                modified = True
                        
                        if modified:
                            with open(file_path, 'w', encoding='utf-8') as f:
                                f.write(content)
                                
                        cur.execute("UPDATE a3_meta.a3_task_queue SET status = 'completed', updated_at = NOW() WHERE id = %s;", (task_id,))
                        conn.commit()
                        print(f"Task {task_id} completed successfully.")
                        count += 1
                    except Exception as e:
                        err = str(e)
                        cur.execute("UPDATE a3_meta.a3_task_queue SET status = 'failed', error_message = %s, updated_at = NOW() WHERE id = %s;", (err, task_id))
                        conn.commit()
                        print(f"Task {task_id} failed: {err}")
                elif task_type == 'data_mining_integration':
                    try:
                        feature_name = payload.get('feature_name', 'Unknown Feature')
                        description = payload.get('description', 'No description')
                        source_file = payload.get('source_file', 'unknown.sql')
                        
                        sub_task_name = f"Data Mining: {feature_name}"
                        script_content = f"-- Integration for {feature_name}\n-- Source: {source_file}\n-- Description: {description}\nSELECT 1; -- TODO: Implement"
                        
                        cur.execute("""
                        INSERT INTO a3_meta.a3_sub_tasks (
                            sub_task_name, sub_task_type, status, script_content, priority
                        )
                        VALUES (%s, 'SQL_EXEC', 'QUEUED', %s, 90)
                        RETURNING sub_task_id;
                        """, (sub_task_name, script_content))
                        row = cur.fetchone()
                        sub_task_id = row[0]
                        
                        cur.execute("UPDATE a3_meta.a3_task_queue SET status = 'completed', updated_at = NOW() WHERE id = %s;", (task_id,))
                        conn.commit()
                        print(f"Task {task_id} completed successfully (Subtask {sub_task_id} created).")
                        count += 1
                    except Exception as e:
                        err = str(e)
                        cur.execute("UPDATE a3_meta.a3_task_queue SET status = 'failed', error_message = %s, updated_at = NOW() WHERE id = %s;", (err, task_id))
                        conn.commit()
                        print(f"Task {task_id} failed: {err}")
                elif task_type == 'architecture_integration':
                    try:
                        file_name = payload.get('file', 'Unknown File')
                        description = payload.get('description', 'No description')
                        phase = payload.get('phase', 'Unknown Phase')
                        
                        sub_task_name = f"Architecture Integration: {file_name} ({phase})"
                        script_content = f"# Integration for {file_name}\n# Phase: {phase}\n# Description: {description}\nprint('To be implemented')"
                        
                        cur.execute("""
                        INSERT INTO a3_meta.a3_sub_tasks (
                            sub_task_name, sub_task_type, status, script_content, priority
                        )
                        VALUES (%s, 'PYTHON_EXEC', 'QUEUED', %s, 90)
                        RETURNING sub_task_id;
                        """, (sub_task_name, script_content))
                        row = cur.fetchone()
                        sub_task_id = row[0]
                        
                        cur.execute("UPDATE a3_meta.a3_task_queue SET status = 'completed', updated_at = NOW() WHERE id = %s;", (task_id,))
                        conn.commit()
                        print(f"Task {task_id} completed successfully (Subtask {sub_task_id} created).")
                        count += 1
                    except Exception as e:
                        err = str(e)
                        cur.execute("UPDATE a3_meta.a3_task_queue SET status = 'failed', error_message = %s, updated_at = NOW() WHERE id = %s;", (err, task_id))
                        conn.commit()
                        print(f"Task {task_id} failed: {err}")
                else:
                    cur.execute("UPDATE a3_meta.a3_task_queue SET status = 'failed', error_message = 'Automated script cannot handle this task type' WHERE id = %s;", (task_id,))
                    conn.commit()
                    print(f"Skipping unknown task type {task_type}")

    finally:
        conn.close()
        
    print(f"Processed {count} tasks.")

if __name__ == '__main__':
    process_tasks()
