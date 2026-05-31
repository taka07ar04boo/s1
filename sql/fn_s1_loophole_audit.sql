CREATE OR REPLACE FUNCTION a3_meta.fn_s1_loophole_audit()
 RETURNS TABLE(check_name text, status text, details text, affected_count integer)
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_count INT;
BEGIN
    -- ?? CHECK-L1: ?????????? & ????? ??
    -- governance_checks ? SELECT 1 / SELECT 0 ????SQL
    SELECT COALESCE(count(*), 0)::int INTO v_count
    FROM a3_meta.governance_checks
    WHERE TRIM(check_sql) IN ('SELECT 1', 'SELECT 0')
      AND check_id != 'GOV-MAX-RIGOR-01';

    IF v_count > 0 THEN
        DELETE FROM a3_meta.governance_checks
        WHERE TRIM(check_sql) IN ('SELECT 1', 'SELECT 0')
          AND check_id != 'GOV-MAX-RIGOR-01';
    END IF;

    INSERT INTO a3_meta.s1_audit_log (audit_type, check_name, status, details, affected_count)
    VALUES ('LOOPHOLE', 'PAPER_VACCINE_PURGE',
            CASE WHEN v_count > 0 THEN 'PURGED' ELSE 'PASS' END,
            format('??????????&???: %s?', v_count), v_count);

    RETURN QUERY SELECT 'PAPER_VACCINE_PURGE'::TEXT,
        CASE WHEN v_count > 0 THEN 'PURGED' ELSE 'PASS' END,
        format('??????????&???: %s?', v_count), v_count;

    -- ?? CHECK-L2: Goal ?????????? & ??FAIL ??
    SELECT COALESCE(count(*), 0)::int INTO v_count
    FROM a3_meta.s1_goals
    WHERE (success_criteria_query IS NULL
           OR TRIM(success_criteria_query) IN ('SELECT 1', 'SELECT 0', ''))
      AND a3_meta.s1_goals.status NOT IN ('FAILED', 'ABANDONED', 'CANCELLED');

    IF v_count > 0 THEN
        UPDATE a3_meta.s1_goals
        SET status = 'FAILED',
            description = COALESCE(description, '')
                || ' [?????:L2] ??????? ? ??FAIL'
        WHERE (success_criteria_query IS NULL
               OR TRIM(success_criteria_query) IN ('SELECT 1', 'SELECT 0', ''))
          AND a3_meta.s1_goals.status NOT IN ('FAILED', 'ABANDONED', 'CANCELLED');
    END IF;

    INSERT INTO a3_meta.s1_audit_log (audit_type, check_name, status, details, affected_count)
    VALUES ('LOOPHOLE', 'GOAL_DUMMY_CRITERIA',
            CASE WHEN v_count > 0 THEN 'FAIL' ELSE 'PASS' END,
            format('????????Goal: %s?', v_count), v_count);

    RETURN QUERY SELECT 'GOAL_DUMMY_CRITERIA'::TEXT,
        CASE WHEN v_count > 0 THEN 'FAIL' ELSE 'PASS' END,
        format('????????Goal: %s?', v_count), v_count;

    -- ?? CHECK-L3: 999???????? ??
    SELECT COALESCE(count(*), 0)::int INTO v_count
    FROM a3_meta.governance_checks
    WHERE threshold = 999 AND active = true;

    INSERT INTO a3_meta.s1_audit_log (audit_type, check_name, status, details, affected_count)
    VALUES ('LOOPHOLE', 'BYPASS_THRESHOLD_999',
            CASE WHEN v_count > 0 THEN 'FAIL' ELSE 'PASS' END,
            format('999?????????????: %s?', v_count), v_count);

    RETURN QUERY SELECT 'BYPASS_THRESHOLD_999'::TEXT,
        CASE WHEN v_count > 0 THEN 'FAIL' ELSE 'PASS' END,
        format('999?????????????: %s?', v_count), v_count;

    -- ?? CHECK-L4: ?????? (= vs ==) ???? ??
    SELECT COALESCE(count(*), 0)::int INTO v_count
    FROM a3_meta.governance_checks
    WHERE operator = '=' AND active = true;

    IF v_count > 0 THEN
        UPDATE a3_meta.governance_checks
        SET operator = '=='
        WHERE operator = '=' AND active = true;
    END IF;

    INSERT INTO a3_meta.s1_audit_log (audit_type, check_name, status, details, affected_count)
    VALUES ('LOOPHOLE', 'OPERATOR_MISMATCH_AUTOFIX',
            CASE WHEN v_count > 0 THEN 'FIXED' ELSE 'PASS' END,
            format('??? = ? == ????: %s?', v_count), v_count);

    RETURN QUERY SELECT 'OPERATOR_MISMATCH_AUTOFIX'::TEXT,
        CASE WHEN v_count > 0 THEN 'FIXED' ELSE 'PASS' END,
        format('??? = ? == ????: %s?', v_count), v_count;

    -- ?? CHECK-L5: ????????? ??
    SELECT COALESCE(count(*), 0)::int INTO v_count
    FROM a3_meta.governance_checks
    WHERE active = false;

    INSERT INTO a3_meta.s1_audit_log (audit_type, check_name, status, details, affected_count)
    VALUES ('LOOPHOLE', 'DISABLED_CHECK_DETECTION',
            CASE WHEN v_count > 0 THEN 'WARN' ELSE 'PASS' END,
            format('??????????: %s?', v_count), v_count);

    RETURN QUERY SELECT 'DISABLED_CHECK_DETECTION'::TEXT,
        CASE WHEN v_count > 0 THEN 'WARN' ELSE 'PASS' END,
        format('??????????: %s?', v_count), v_count;

    -- ?? CHECK-L6: ????? (padding/dummy output) ??
    SELECT COALESCE(count(*), 0)::int INTO v_count
    FROM a3_meta.a3_sub_tasks
    WHERE a3_meta.a3_sub_tasks.status = 'COMPLETED'
      AND output_data IS NOT NULL
      AND (output_data::text ~* 'padding|dummy|auto_completed|placeholder'
           OR (length(trim(output_data::text)) < 20 AND output_data::text NOT IN ('{}', '{"success": true}', '{"status": "ok"}')))
      AND sub_task_type NOT IN ('AUDIT', 'TASK_SPLITTER')
      AND updated_at > NOW() - INTERVAL '24 hours';

    INSERT INTO a3_meta.s1_audit_log (audit_type, check_name, status, details, affected_count)
    VALUES ('LOOPHOLE', 'FAKE_COMPLETION_DETECTION',
            CASE WHEN v_count > 0 THEN 'FAIL' ELSE 'PASS' END,
            format('??? (??24h): %s?', v_count), v_count);

    RETURN QUERY SELECT 'FAKE_COMPLETION_DETECTION'::TEXT,
        CASE WHEN v_count > 0 THEN 'FAIL' ELSE 'PASS' END,
        format('??? (??24h): %s?', v_count), v_count;

    -- ?? CHECK-L7: ??????????? & ??FAIL ??
    SELECT COALESCE(count(*), 0)::int INTO v_count
    FROM a3_meta.a3_sub_tasks
    WHERE sub_task_type = 'PYTHON_EXEC'
      AND (script_content IS NULL OR length(trim(script_content)) < 5)
      AND a3_meta.a3_sub_tasks.status NOT IN ('FAILED', 'CANCELLED');

    IF v_count > 0 THEN
        UPDATE a3_meta.a3_sub_tasks
        SET status    = 'FAILED',
            error_log = COALESCE(error_log, '')
                || E'\n[?????:L7] ???????? ? ??FAIL'
        WHERE sub_task_type = 'PYTHON_EXEC'
          AND (script_content IS NULL OR length(trim(script_content)) < 5)
          AND a3_meta.a3_sub_tasks.status NOT IN ('FAILED', 'CANCELLED');
    END IF;

    INSERT INTO a3_meta.s1_audit_log (audit_type, check_name, status, details, affected_count)
    VALUES ('LOOPHOLE', 'EMPTY_SCRIPT_QUARANTINE',
            CASE WHEN v_count > 0 THEN 'FAIL' ELSE 'PASS' END,
            format('??????PYTHON_EXEC: %s?', v_count), v_count);

    RETURN QUERY SELECT 'EMPTY_SCRIPT_QUARANTINE'::TEXT,
        CASE WHEN v_count > 0 THEN 'FAIL' ELSE 'PASS' END,
        format('??????PYTHON_EXEC: %s?', v_count), v_count;

    RETURN;
END;
$function$

