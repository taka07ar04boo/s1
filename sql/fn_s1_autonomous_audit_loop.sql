CREATE OR REPLACE FUNCTION a3_meta.fn_s1_autonomous_audit_loop()
 RETURNS TABLE(phase text, r_action text, r_details text)
 LANGUAGE plpgsql
AS $function$
BEGIN
    -- Phase 1: ズル監査 + 抜け道監査
    phase := '1_AUDIT';
    FOR r_action, r_details IN
        SELECT ag.r_check::text, ag.r_details::text
        FROM a3_meta.fn_waterfall_audit_gate() ag
        WHERE ag.r_status NOT IN ('PASS')
    LOOP
        RETURN NEXT;
    END LOOP;

    -- Phase 2: 合議差し戻し (偽完了・低品質を自動差し戻し)
    phase := '2_DELIBERATION';
    FOR r_action, r_details IN
        SELECT dr.r_action, dr.r_details
        FROM a3_meta.fn_deliberation_revert() dr
        WHERE dr.r_count > 0
    LOOP
        RETURN NEXT;
    END LOOP;

    -- Phase 3: 修復タスク自動ディスパッチ
    phase := '3_DISPATCH';
    FOR r_action, r_details IN
        SELECT ad.r_action, ad.r_details
        FROM a3_meta.fn_audit_auto_dispatch() ad
    LOOP
        RETURN NEXT;
    END LOOP;

    -- Phase 4: プロジェクト健全性チェック
    phase := '4_PROJECT_HEALTH';
    FOR r_action, r_details IN
        SELECT ph.r_project, ph.r_details
        FROM a3_meta.fn_project_health_check() ph
        WHERE ph.r_status != 'ACTIVE'
    LOOP
        RETURN NEXT;
    END LOOP;

    RETURN;
END;
$function$

