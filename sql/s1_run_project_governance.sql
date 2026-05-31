CREATE OR REPLACE FUNCTION a3_meta.s1_run_project_governance(p_project_id text DEFAULT 'A3'::text)
 RETURNS TABLE(check_id text, check_name text, passed boolean, severity text, detail text, project_id text)
 LANGUAGE plpgsql
AS $function$
DECLARE
    r RECORD;
    v_result NUMERIC;
    v_passed BOOLEAN;
BEGIN
    -- プロジェクト存在チェック
    IF NOT EXISTS (SELECT 1 FROM a3_meta.s1_projects WHERE s1_projects.project_id = p_project_id AND status = 'ACTIVE') THEN
        check_id := 'ERR'; check_name := 'Unknown project'; passed := false;
        severity := 'CRITICAL'; detail := 'Project ' || p_project_id || ' not found in s1_projects';
        project_id := p_project_id;
        RETURN NEXT; RETURN;
    END IF;

    -- S1共通チェック + 該当プロジェクト固有チェック を結合実行
    FOR r IN
        SELECT gc.check_id, gc.check_name, gc.check_sql, gc.operator,
               gc.threshold, gc.severity, gc.detail_template, gc.project_id
        FROM a3_meta.governance_checks gc
        WHERE gc.active = true
          AND gc.check_type = 'SQL'
          AND gc.project_id IN ('S1', p_project_id)
        ORDER BY gc.display_order NULLS LAST, gc.check_id
    LOOP
        BEGIN
            EXECUTE r.check_sql INTO v_result;
            
            v_passed := CASE r.operator
                WHEN '>=' THEN COALESCE(v_result, 0) >= r.threshold
                WHEN '<=' THEN COALESCE(v_result, 0) <= r.threshold
                WHEN '='  THEN COALESCE(v_result, 0) = r.threshold
                WHEN '<'  THEN COALESCE(v_result, 0) < r.threshold
                WHEN '>'  THEN COALESCE(v_result, 0) > r.threshold
                ELSE true
            END;
            
            check_id   := r.check_id;
            check_name := r.check_name;
            passed     := v_passed;
            severity   := r.severity;
            detail     := REPLACE(COALESCE(r.detail_template, ''), '{value}', COALESCE(v_result::text, 'NULL'));
            project_id := r.project_id;
            RETURN NEXT;
            
        EXCEPTION WHEN OTHERS THEN
            check_id   := r.check_id;
            check_name := r.check_name;
            passed     := false;
            severity   := 'CRITICAL';
            detail     := 'EXEC ERROR: ' || SQLERRM;
            project_id := r.project_id;
            RETURN NEXT;
        END;
    END LOOP;
END;
$function$

