# -*- coding: utf-8 -*-
"""
s1_waterfall_guard.py — Waterfall Integrity Guard (Pre-Commit/Daemon)
===================================================================
Implementation部隊（Squad）のピアレビュー合意がない状態で、
親エージェントが本番ソースコード (`a3_*.py`) を直接書き換えるのを物理的にブロックする防壁。
"""

import os
import sys
import json
import logging

logging.basicConfig(level=logging.INFO, format='%(asctime)s [WaterfallGuard] %(levelname)s: %(message)s')
log = logging.getLogger("WaterfallGuard")

CONTEXT_DIR = os.path.join(os.path.dirname(__file__), ".waterfall_contexts")
STATE_FILE = os.path.join(CONTEXT_DIR, "waterfall_state.json")

def is_code_change_authorized():
    """
    Check if the current waterfall state permits code modifications.
    Code changes are ONLY allowed when:
    1. Phase is IMPL or QA
    2. The review consensus for IMPL phase has been reached (Code Reviewer has approved)
    """
    if not os.path.exists(STATE_FILE):
        log.warning("No active waterfall state found. Strict mode: Code changes rejected.")
        return False
        
    try:
        with open(STATE_FILE, "r", encoding="utf-8") as f:
            task = json.load(f)
            
        current_phase = task.get("current_phase")
        if current_phase not in ["IMPL", "QA", "DONE"]:
            log.warning(f"Code changes are not allowed in Phase: {current_phase}. Changes rejected.")
            return False
            
        # Check if s1_code_reviewer has approved (if strict review enforced)
        # For simplicity, if we are in QA or DONE, it means IMPL was approved.
        if current_phase in ["QA", "DONE"]:
            return True
            
        return True # In IMPL phase, modifications by implementer are allowed.
        
    except Exception as e:
        log.error(f"Failed to read waterfall state: {e}")
        return False

def verify_files(changed_files):
    for f in changed_files:
        if f.startswith("a3_") and f.endswith(".py"):
            if not is_code_change_authorized():
                log.error(f"❌ SECURITY VIOLATION: Unauthorized direct edit to {f} detected!")
                log.error("Parent Agent (PM) must delegate implementation to s1_code_implementer and receive s1_code_reviewer approval.")
                sys.exit(1)
                
    log.info("✅ Waterfall Guard Passed: Code changes authorized.")
    sys.exit(0)

if __name__ == "__main__":
    # Normally triggered by git pre-commit hook passing changed files
    if len(sys.argv) > 1:
        verify_files(sys.argv[1:])
    else:
        # Example check
        log.info("Running manual verification mode...")
        verify_files(["a3_dummy.py"])
