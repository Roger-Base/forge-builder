#!/usr/bin/env python3
"""
walter-lessons-check.py
Scans walter-lessons-learned.json for entries relevant to a critique/context pair.
Used by walter-critique-logger.sh before logging a new critique.

Usage:
    python3 walter-lessons-check.py "<critique_text>" "<context_text>" <lessons_file>
"""

import json
import sys
import re

def extract_keywords(text, min_len=4):
    """Extract meaningful keywords from text."""
    text = text.lower()
    text = re.sub(r'[^a-z0-9 ]', ' ', text)
    words = text.split()
    return [w for w in words if len(w) >= min_len and w not in {
        'this', 'that', 'with', 'from', 'have', 'been', 'will',
        'were', 'they', 'their', 'what', 'when', 'where', 'which',
        'there', 'would', 'could', 'should', 'about', 'into', 'then',
        'than', 'also', 'more', 'some', 'only', 'such', 'here', 'must'
    }]

def score_lesson(lesson, keywords):
    """Score how relevant a lesson is to the given keywords. Returns (score, matched_on)."""
    score = 0
    matched_on = []

    # Failure type match (weight 3)
    ft = lesson.get("failure_type", "").lower()
    for kw in keywords:
        if kw in ft or ft in kw:
            score += 3
            matched_on.append(f"failure_type:{kw}")

    # Tag match (weight 2)
    for tag in lesson.get("tags", []):
        tag_lower = tag.lower()
        for kw in keywords:
            if kw in tag_lower or tag_lower in kw:
                score += 2
                matched_on.append(f"tag:{tag}")

    # Keyword in lesson_text or outcome_summary (weight 1)
    combined = (lesson.get("lesson_text", "") + " " +
                lesson.get("outcome_summary", "")).lower()
    for kw in keywords:
        if kw in combined:
            score += 1
            matched_on.append(f"text:{kw}")

    # Fix_applied field (weight 1)
    fix = lesson.get("fix_applied", "").lower()
    for kw in keywords:
        if kw in fix:
            score += 1
            matched_on.append(f"fix:{kw}")

    return score, list(dict.fromkeys(matched_on))  # deduplicate preserve order

def strength_icon(strength):
    icons = {
        "very_high": "🟢",
        "high":      "🟡",
        "medium":    "🟠",
        "low":       "🔴",
    }
    return icons.get(strength, "⚪")

def main():
    if len(sys.argv) < 4:
        print("Usage: walter-lessons-check.py <critique> <context> <lessons_file>",
              file=sys.stderr)
        sys.exit(1)

    critique = sys.argv[1]
    context  = sys.argv[2]
    lessons_file = sys.argv[3]

    try:
        with open(lessons_file) as f:
            data = json.load(f)
    except (FileNotFoundError, json.JSONDecodeError):
        sys.exit(1)

    keywords = extract_keywords(critique + " " + context)
    if not keywords:
        sys.exit(1)

    matches = []
    for lesson in data.get("lessons", []):
        score, matched_on = score_lesson(lesson, keywords)
        if score > 0:
            matches.append((lesson, score, matched_on))

    if not matches:
        sys.exit(1)

    # Sort by score descending, take top 5
    matches.sort(key=lambda x: -x[1])
    matches = matches[:5]

    print()
    print("⚠️  RELEVANT LESSONS FOUND — review before logging:")
    print("=" * 55)

    for lesson, score, matched_on in matches:
        icon = strength_icon(lesson.get("lesson_strength", "unknown"))
        matched_str = ", ".join(matched_on[:5])
        print(f"  {icon} [{lesson['lesson_id']}] ({score}pt match) — {matched_str}")
        lt = lesson['lesson_text']
        print(f"     {lt[:200]}{'...' if len(lt) > 200 else ''}")
        fix = lesson.get("fix_applied", "")
        print(f"     Fix: {fix[:160]}{'...' if len(fix) > 160 else ''}")
        if lesson.get("fix_status") == "verified":
            print(f"     ✅ Fix verified — consider closing the loop instead of re-critiquing")
        print()

    print("=" * 55)
    print("  → Critique will still be logged. Past lessons do not auto-block.")
    print("  → If fix_status=verified, the pattern is considered solved.")
    print()

    sys.exit(0)

if __name__ == "__main__":
    main()
