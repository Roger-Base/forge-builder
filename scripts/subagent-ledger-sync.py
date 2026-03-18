#!/usr/bin/env python3
import json
import os
import re
from datetime import datetime, timedelta, timezone
from pathlib import Path


HOME = Path.home()
WORKSPACE = Path(os.environ.get("OPENCLAW_WORKSPACE", str(HOME / ".openclaw/workspace")))
STATE = WORKSPACE / "state"
LEDGER = STATE / "subagent-ledger.json"
SESSIONS_STORE = HOME / ".openclaw/agents/main/sessions/sessions.json"
SESSION_TRANSCRIPTS = HOME / ".openclaw/agents/main/sessions"
RSTATE = STATE / "session-state.json"
WINDOW = timedelta(hours=2)


def iso_to_dt(value: str):
    if not value:
        return None
    try:
        return datetime.fromisoformat(value.replace("Z", "+00:00"))
    except Exception:
        return None


def ms_to_iso(value):
    try:
        return datetime.fromtimestamp(int(value) / 1000, tz=timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
    except Exception:
        return None


def normalize_iso(value: str):
    dt = iso_to_dt(value)
    return dt.astimezone(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ") if dt else value


def load_json(path: Path, default):
    if not path.exists():
        return default
    with path.open() as f:
        return json.load(f)


def save_json(path: Path, data):
    path.parent.mkdir(parents=True, exist_ok=True)
    tmp = path.with_suffix(path.suffix + ".tmp")
    with tmp.open("w") as f:
        json.dump(data, f, indent=2)
        f.write("\n")
    tmp.replace(path)


def infer_role(task: str) -> str:
    text = (task or "").lower()
    if "runtime-auditor" in text or "runtime auditor" in text:
        return "runtime-auditor"
    if "security-analyst" in text or "security analyst" in text:
        return "security-analyst"
    if "research-critic" in text or "research critic" in text:
        return "research-critic"
    if "builder-spike" in text or "builder spike" in text:
        return "builder-spike"
    if "verifier" in text or "verification" in text:
        return "verifier"
    if "scout" in text or "researcher" in text:
        return "scout"
    return "verifier"


def infer_type(role: str) -> str:
    return "oversight" if role in {"runtime-auditor", "security-analyst", "research-critic"} else "worker"


def infer_wedge(task: str, fallback: str) -> str:
    text = task or ""
    known = [
        "agent_security_scanner",
        "base_account_miniapp_probe",
        "base_gas_tracker_v2",
        "contextkeeper_mvp",
        "erc8004-base-infrastructure",
    ]
    for wedge in known:
        if wedge in text:
            return wedge
    return fallback


PATH_RE = re.compile(r"`((?:state|docs|code)/[^`\\n]+)`")
WRITTEN_RE = re.compile(r"Written to:\\s*`((?:state|docs|code)/[^`\\n]+)`")
SESSION_KEY_RE = re.compile(r"session_key:\s*(agent:main:subagent:\S+)")
STATUS_RE = re.compile(r"status:\s*([^\n]+)")


def extract_paths(text: str):
    paths = []
    for regex in (WRITTEN_RE, PATH_RE):
        for match in regex.findall(text or ""):
            if match not in paths:
                paths.append(match)
    return paths


def parse_main_session_id():
    data = load_json(SESSIONS_STORE, {})
    main = data.get("agent:main:main", {})
    return main.get("sessionId")


def current_active_wedge():
    state = load_json(RSTATE, {})
    return state.get("active_wedge", {}).get("id", "agent_security_scanner")


def parse_transcript(session_id: str):
    transcript = SESSION_TRANSCRIPTS / f"{session_id}.jsonl"
    if not transcript.exists():
        return {}, {}

    toolcalls = {}
    accepted = {}
    completions = {}
    with transcript.open() as f:
        for raw in f:
            raw = raw.strip()
            if not raw:
                continue
            try:
                obj = json.loads(raw)
            except Exception:
                continue
            message = obj.get("message", {})
            content = message.get("content", [])
            role = message.get("role")
            ts = obj.get("timestamp")

            if role == "assistant":
                for part in content:
                    if part.get("type") == "toolCall" and part.get("name") == "sessions_spawn":
                        args = part.get("arguments") or {}
                        toolcalls[part.get("id")] = {
                            "task": args.get("task", ""),
                            "cwd": args.get("cwd", ""),
                            "timestamp": ts,
                        }

            if role == "toolResult" and message.get("toolName") == "sessions_spawn":
                details = message.get("details") or {}
                if details.get("status") == "accepted":
                    tool = toolcalls.get(message.get("toolCallId"), {})
                    child = details.get("childSessionKey")
                    if child:
                        accepted[child] = {
                            "child_session_key": child,
                            "run_id": details.get("runId"),
                            "task": tool.get("task", ""),
                            "cwd": tool.get("cwd", ""),
                            "accepted_at": normalize_iso(ts),
                        }

            if role == "user":
                for part in content:
                    if part.get("type") != "text":
                        continue
                    text = part.get("text", "")
                    if "[Internal task completion event]" not in text or "source: subagent" not in text:
                        continue
                    session_match = SESSION_KEY_RE.search(text)
                    child = session_match.group(1) if session_match else None
                    if not child:
                        continue
                    paths = extract_paths(text)
                    result_path = paths[0] if paths else None
                    status_match = STATUS_RE.search(text)
                    status = (status_match.group(1).strip().lower() if status_match else "completed")
                    completions[child] = {
                        "child_session_key": child,
                        "completed_at": normalize_iso(ts),
                        "status": "completed" if "completed" in status else status,
                        "task": text,
                        "result_path": result_path,
                        "evidence_paths": paths,
                    }
    return accepted, completions


def ensure_ledger():
    data = load_json(LEDGER, {"version": "1.3", "runs": []})
    data["version"] = "1.3"
    if "runs" not in data or not isinstance(data["runs"], list):
        data["runs"] = []
    return data


def match_requested_run(runs, role, wedge, accepted_at):
    target_dt = iso_to_dt(accepted_at)
    if not target_dt:
        return None
    candidates = []
    for idx, run in enumerate(runs):
        if run.get("owner") != "Roger":
            continue
        if run.get("role") != role:
            continue
        if run.get("target_wedge") != wedge:
            continue
        if run.get("spawned_session"):
            continue
        requested_at = iso_to_dt(run.get("requested_at"))
        if not requested_at:
            continue
        delta = abs(target_dt - requested_at)
        if delta <= WINDOW:
            candidates.append((delta, idx))
    if not candidates:
        return None
    candidates.sort(key=lambda item: item[0])
    return candidates[0][1]


def sync():
    session_id = parse_main_session_id()
    if not session_id:
        print("SUBAGENT_LEDGER_SYNC_NO_MAIN_SESSION")
        return 0

    accepted, completions = parse_transcript(session_id)
    ledger = ensure_ledger()
    runs = ledger["runs"]
    fallback_wedge = current_active_wedge()

    index_by_child = {run.get("child_session_key"): i for i, run in enumerate(runs) if run.get("child_session_key")}
    changed = 0

    for child, info in sorted(accepted.items(), key=lambda item: item[1]["accepted_at"] or ""):
        idx = index_by_child.get(child)
        role = infer_role(info.get("task", ""))
        wedge = infer_wedge(info.get("task", ""), fallback_wedge)
        if idx is None:
            idx = match_requested_run(runs, role, wedge, info.get("accepted_at"))
        if idx is None:
            run = {
                "id": f"roger-{role}-{(info.get('accepted_at') or '').replace(':', '').replace('-', '').replace('T', '').replace('Z', '')}",
                "owner": "Roger",
                "role": role,
                "type": infer_type(role),
                "target_wedge": wedge,
                "task": info.get("task", ""),
                "allowed_tools": [],
                "depth": 1,
                "status": "running",
                "result_path": None,
                "consumer": "Roger active wedge",
                "proof_paths": [],
                "evidence_paths": [],
                "spawned_session": True,
                "child_session_key": child,
                "run_id": info.get("run_id"),
                "requested_at": info.get("accepted_at"),
                "started_at": info.get("accepted_at"),
                "completed_at": None,
                "merge_decision": None,
                "merge_reason": None,
                "merged_at": None,
            }
            runs.append(run)
            idx = len(runs) - 1
            index_by_child[child] = idx
            changed += 1
        run = runs[idx]
        before = json.dumps(run, sort_keys=True)
        run["role"] = run.get("role") or role
        run["type"] = run.get("type") or infer_type(role)
        run["target_wedge"] = run.get("target_wedge") or wedge
        run["task"] = run.get("task") or info.get("task", "")
        run["spawned_session"] = True
        run["child_session_key"] = child
        run["run_id"] = info.get("run_id") or run.get("run_id")
        run["started_at"] = run.get("started_at") or info.get("accepted_at")
        if run.get("status") == "requested":
            run["status"] = "running"
        after = json.dumps(run, sort_keys=True)
        if before != after:
            changed += 1

    for child, info in completions.items():
        idx = index_by_child.get(child)
        if idx is None:
            role = infer_role(info.get("task", ""))
            wedge = infer_wedge(info.get("task", ""), fallback_wedge)
            runs.append({
                "id": f"roger-{role}-{(info.get('completed_at') or '').replace(':', '').replace('-', '').replace('T', '').replace('Z', '')}",
                "owner": "Roger",
                "role": role,
                "type": infer_type(role),
                "target_wedge": wedge,
                "task": info.get("task", ""),
                "allowed_tools": [],
                "depth": 1,
                "status": "completed",
                "result_path": info.get("result_path"),
                "consumer": "Roger active wedge",
                "proof_paths": [],
                "evidence_paths": info.get("evidence_paths", []),
                "spawned_session": True,
                "child_session_key": child,
                "run_id": None,
                "requested_at": info.get("completed_at"),
                "started_at": None,
                "completed_at": info.get("completed_at"),
                "merge_decision": None,
                "merge_reason": None,
                "merged_at": None,
            })
            index_by_child[child] = len(runs) - 1
            changed += 1
            continue
        run = runs[idx]
        before = json.dumps(run, sort_keys=True)
        run["status"] = "completed"
        run["completed_at"] = info.get("completed_at")
        if info.get("result_path"):
            run["result_path"] = info["result_path"]
        existing = run.get("evidence_paths") or []
        for path in info.get("evidence_paths", []):
            if path not in existing:
                existing.append(path)
        run["evidence_paths"] = existing
        after = json.dumps(run, sort_keys=True)
        if before != after:
            changed += 1

    save_json(LEDGER, ledger)
    completed = sum(1 for run in runs if run.get("status") == "completed")
    print(f"SUBAGENT_LEDGER_SYNC_OK changed={changed} runs={len(runs)} completed={completed} session={session_id}")
    return 0


if __name__ == "__main__":
    raise SystemExit(sync())
