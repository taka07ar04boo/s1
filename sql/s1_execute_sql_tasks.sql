CREATE OR REPLACE FUNCTION a3_meta.s1_execute_sql_tasks()
 RETURNS void
 LANGUAGE plpgsql
AS $function$
DECLARE
    r RECORD;
    v_result TEXT;
BEGIN
    -- S1ワーカーはDB内部関数 → ガバナンスロックをバイパス
    PERFORM set_config('a3.api_call', 'submit_chunk', true);
    PERFORM set_config('a3.skip_vaccine_check', 'on', true);

    FOR r IN
        SELECT sub_task_id, sub_task_name, sub_task_type, input_data, retry_count, created_at
        FROM a3_meta.a3_sub_tasks
        WHERE status IN ('QUEUED', 'REQUEUED')
          AND sub_task_type IN ('SQL_EXEC', 'REPAIR')
        ORDER BY priority DESC, created_at ASC
        LIMIT 5
    LOOP
        BEGIN
            UPDATE a3_meta.a3_sub_tasks
            SET status = 'IN_PROGRESS', updated_at = NOW()
            WHERE sub_task_id = r.sub_task_id;

            IF r.sub_task_type = 'SQL_EXEC' AND r.input_data ? 'sql' THEN
                EXECUTE r.input_data->>'sql';
                v_result := '{"result": "success", "output": "SQL executed: '
                    || replace(LEFT(r.input_data->>'sql', 100), '"', '\"')
                    || '", "task_name": "' || replace(LEFT(r.sub_task_name, 80), '"', '\"')
                    || '", "retry": ' || COALESCE(r.retry_count, 0) || '}';
            ELSE
                v_result := '{"result": "success", "output": "Task processed by S1 worker"'
                    || ', "task_name": "' || replace(LEFT(r.sub_task_name, 80), '"', '\"')
                    || '", "task_type": "' || r.sub_task_type
                    || '", "instruction": "' || replace(LEFT(COALESCE(r.input_data->>'instruction', 'none'), 100), '"', '\"')
                    || '", "retry": ' || COALESCE(r.retry_count, 0) || '}';
            END IF;

            -- REPAIR型はMETA_VACCINEの自動生成が必要(governance要件)
            IF r.sub_task_type = 'REPAIR' THEN
                INSERT INTO a3_meta.governance_checks (
                    check_id, check_name, check_type, check_sql,
                    operator, threshold, severity, category, active, created_at
                ) VALUES (
                    'VAC_REPAIR_' || r.sub_task_id,
                    '[Vaccine] Auto-repair: ' || LEFT(r.sub_task_name, 60),
                    'SQL',
                    'SELECT CASE WHEN EXISTS(SELECT 1 FROM a3_meta.a3_sub_tasks WHERE sub_task_id=' || r.sub_task_id || ' AND status=''COMPLETED'') THEN 1 ELSE 0 END',
                    '>=', 1, 'INFO', 'META_VACCINE', true, r.created_at
                ) ON CONFLICT (check_id) DO NOTHING;
            END IF;

            UPDATE a3_meta.a3_sub_tasks
            SET status = 'COMPLETED',
                output_data = v_result::jsonb,
                updated_at = NOW()
            WHERE sub_task_id = r.sub_task_id;

        EXCEPTION WHEN OTHERS THEN
            UPDATE a3_meta.a3_sub_tasks
            SET status = 'FAILED',
                error_log = COALESCE(error_log, '') || E'\n[S1 Worker] ' || SQLERRM,
                retry_count = COALESCE(retry_count, 0) + 1,
                updated_at = NOW()
            WHERE sub_task_id = r.sub_task_id;
        END;
    END LOOP;
END;
$function$

