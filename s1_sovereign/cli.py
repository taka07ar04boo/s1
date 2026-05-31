import argparse
import sys
from .s1_auto_task_processor import process_tasks as auto_task_process
from .s1_data_mining_orchestrator import main as data_mining_main
from .s1_delegate_tasks import process_tasks as delegate_process
from .s1_queue_monitor import process_until_empty as queue_process
from .s1_waterfall_orchestrator import (
    init_db_schema, create_task, approve_phase,
    delegate_to_subagent, check_subtask_status
)

def main():
    parser = argparse.ArgumentParser(description="S1 Sovereign CLI")
    subparsers = parser.add_subparsers(dest="command", help="Available commands")

    subparsers.add_parser("auto-task", help="Run auto task processor")
    subparsers.add_parser("data-mining", help="Run data mining orchestrator")
    subparsers.add_parser("delegate", help="Run delegate tasks")
    subparsers.add_parser("queue", help="Run queue monitor")
    
    waterfall_parser = subparsers.add_parser("waterfall", help="Run waterfall orchestrator")
    waterfall_parser.add_argument("wf_cmd", choices=["start", "approve", "delegate", "status"], help="Waterfall command")
    waterfall_parser.add_argument("args", nargs="*", help="Arguments for the waterfall command")

    args = parser.parse_args()

    if args.command == "auto-task":
        auto_task_process()
    elif args.command == "data-mining":
        data_mining_main()
    elif args.command == "delegate":
        delegate_process()
    elif args.command == "queue":
        queue_process()
    elif args.command == "waterfall":
        init_db_schema()
        cmd = args.wf_cmd
        wargs = args.args
        if cmd == "start":
            title = wargs[0] if len(wargs) > 0 else "Default Task"
            context = wargs[1] if len(wargs) > 1 else "No Context"
            create_task(title, context)
        elif cmd == "approve":
            role = wargs[0] if len(wargs) > 0 else "Reviewer"
            comments = wargs[1] if len(wargs) > 1 else "Approved"
            approve_phase(role, comments)
        elif cmd == "delegate":
            if len(wargs) < 4:
                print("Usage: s1-sovereign waterfall delegate <task_id> <phase> <role> <instructions>")
                return
            delegate_to_subagent(wargs[0], wargs[1], wargs[2], wargs[3])
        elif cmd == "status":
            if len(wargs) < 1:
                print("Usage: s1-sovereign waterfall status <sub_task_id>")
                return
            check_subtask_status(wargs[0])
    else:
        parser.print_help()

if __name__ == "__main__":
    main()
