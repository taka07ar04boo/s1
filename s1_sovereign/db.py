import os
import psycopg2
from psycopg2.extras import RealDictCursor
from dotenv import load_dotenv

# Load environment variables from .env file
load_dotenv()

def get_safe_connection():
    try:
        return psycopg2.connect(
            host=os.environ.get("DB_HOST", "localhost"),
            port=os.environ.get("DB_PORT", "5432"),
            dbname=os.environ.get("DB_NAME", "pckeiba"),
            user=os.environ.get("DB_USER", "postgres"),
            password=os.environ.get("DB_PASSWORD", "")
        )
    except Exception as e:
        print(f"Failed to connect to database: {e}")
        return None

class A3Database:
    def execute_query(self, sql, params=None, fetch=False):
        conn = get_safe_connection()
        if not conn:
            raise Exception("Database connection failed")
        
        try:
            # Use RealDictCursor to allow accessing columns by name like row['status']
            with conn.cursor(cursor_factory=RealDictCursor) as cur:
                cur.execute(sql, params)
                if fetch:
                    result = cur.fetchall()
                    conn.commit()
                    return result
                else:
                    conn.commit()
                    return None
        finally:
            conn.close()
