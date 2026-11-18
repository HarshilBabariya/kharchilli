"""Checks that every string key the app uses exists in all three languages. Usage: python3 tool/check_strings.py [--prune]

--prune also removes keys nothing refers to, so the language files never carry dead strings.
"""
import json, pathlib, re, sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
LANGS = ('en', 'hi', 'gu')
# Keys built at runtime from an enum or id: any key starting with one of these counts as used.
DYNAMIC = ('mood_', 'act_', 'rel_', 'gender_', 'face_', 'mode_', 'period_', 'fest_', 'rw_', 'b_', 'unit_', 'lvl_', 'pay_', 'repeat_', 'beard_', 'kind_', 'cat_', 'channel_', 'faq_', 'preset_', 'svc_', 'pack_tiranga')

source = '\n'.join(p.read_text() for p in (ROOT / 'lib').rglob('*.dart'))
used = set(re.findall(r"\btr(?:Pick|Plural)?\(\s*'([a-z0-9_]+)'", source)) | set(re.findall(r"'((?:[a-z0-9]+_)+[a-z0-9]+)'", source))
failed = False
for lang in LANGS:
    path = ROOT / 'assets' / 'l10n' / f'{lang}.json'
    data = json.loads(path.read_text())
    known = set(data['strings']) | set(data['arrays']) | set(data['plurals'])
    for key in sorted(set(re.findall(r"\btr(?:Pick|Plural)?\(\s*'([a-z0-9_]+)'", source)) - known):
        print(f'{lang}: missing {key}')
        failed = True
    dead = sorted(k for k in known if k not in used and not k.startswith(DYNAMIC))
    if '--prune' in sys.argv:
        for section in ('strings', 'arrays', 'plurals'):
            data[section] = {k: v for k, v in data[section].items() if k not in dead}
        path.write_text(json.dumps(data, ensure_ascii=False, indent=0))
    elif dead:
        print(f'{lang}: {len(dead)} unused, e.g. {dead[:8]}')
        failed = True
sys.exit(1 if failed else 0)
