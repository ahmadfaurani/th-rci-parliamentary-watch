# Workstream: Tabung Haji RCI Parliamentary Impact Assessment
# Repo: ahmadfaurani/th-rci-parliamentary-watch
# Runs after: CJ-TH-01 (Parliamentary Impact Watch, every 6h)
# Updated: 2026-08-04 — Initial deployment

set -e
WORKDIR="/home/p62operator/.openclaw/workspace-th-rci"
cd "$WORKDIR"

# STEP 1: Export cronjob configurations from Hermes internal state
# PITFALL: Shell variables are NOT accessible inside python3 -c "..." blocks.
# Hardcode all paths in the Python code instead of referencing $WORKDIR.
python3 -c "
import json
try:
    with open('/home/p62operator/.hermes/cron/jobs.json') as f:
        data = json.load(f)
    jobs = data['jobs']
    workstream_ids = [
        '25b1b7a9d17f',  # CJ-TH-01: Tabung Haji RCI Parliamentary Impact Watch
    ]
    ws_jobs = [j for j in jobs if j.get('id') in workstream_ids]
    export = {
        'workstream': 'Tabung Haji RCI Parliamentary Impact Assessment',
        'exported_at': __import__('datetime').datetime.utcnow().isoformat() + 'Z',
        'repo': 'ahmadfaurani/th-rci-parliamentary-watch',
        'workspace': '/home/p62operator/.openclaw/workspace-th-rci',
        'total_cronjobs': len(ws_jobs) + 1,
        'cronjobs': []
    }
    for j in ws_jobs:
        m = j.get('model')
        model_name = m.get('model') if isinstance(m, dict) else None
        provider = m.get('provider') if isinstance(m, dict) else None
        sched = j.get('schedule', {})
        sched_display = sched.get('display', '?') if isinstance(sched, dict) else str(sched)
        export['cronjobs'].append({
            'id': j['id'],
            'name': j['name'],
            'schedule': sched_display,
            'deliver': j.get('deliver', '?'),
            'model': model_name or 'inherit (default)',
            'provider': provider or j.get('provider', 'inherit'),
            'enabled_toolsets': j.get('enabled_toolsets', 'all'),
            'workdir': j.get('workdir', 'default'),
            'enabled': j.get('enabled', True),
            'prompt': j.get('prompt', '')
        })
    # Add this script-only job
    export['cronjobs'].append({
        'id': 'script-only',
        'name': 'TH-RCI Parliamentary Git Sync',
        'schedule': '0 11 * * *',
        'deliver': 'local',
        'model': 'N/A (script-only)',
        'provider': 'N/A',
        'enabled_toolsets': ['terminal'],
        'workdir': '/home/p62operator/.openclaw/workspace-th-rci',
        'enabled': True,
        'prompt': ''
    })
    import os
    os.makedirs('/home/p62operator/.openclaw/workspace-th-rci/05-TOOLS-AND-AUTOMATION', exist_ok=True)
    with open('/home/p62operator/.openclaw/workspace-th-rci/05-TOOLS-AND-AUTOMATION/cronjob-configs.json', 'w') as f:
        json.dump(export, f, indent=2, ensure_ascii=False)
    print(f'Exported {len(ws_jobs) + 1} cronjob configs')
except Exception as e:
    print(f'Config export skipped: {e}')
"

# STEP 2: Git sync
TIMESTAMP=$(date -u +%Y-%m-%dT%H:%M:%SZ)
CHANGES=$(git status --porcelain | wc -l)

if [ "$CHANGES" -gt 0 ]; then
    git add -A
    git commit -m "auto: th-rci-parliamentary git-sync $TIMESTAMP"
    git push origin main 2>&1 && echo "✅ Pushed $CHANGES files to th-rci-parliamentary-watch" || echo "⚠️ Committed locally, push deferred (auth pending)"
else
    echo "No changes to sync — th-rci-parliamentary-watch"
fi
