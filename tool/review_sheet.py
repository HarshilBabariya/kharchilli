"""Puts every Hindi and Gujarati string of the app and the website beside its English one, for a native speaker to read.

  python3 tool/review_sheet.py export [translations.csv]   writes the sheet; it opens in Google Sheets and Excel
  python3 tool/review_sheet.py apply reviewed.csv          copies the Hindi and Gujarati cells that were changed back

The reviewer edits the Hindi and Gujarati columns in place and leaves the first two columns alone.
"""
import csv, json, pathlib, re, sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
LANGS = ('en', 'hi', 'gu')
# Each source: its name in the sheet, where its language files are, and the indent they are saved with.
SOURCES = (('app', 'assets/l10n', 0), ('site', 'website/src/i18n', 2))
PLACEHOLDER = re.compile(r'%\d\$[sd]|\{\w+\}')


def flatten(node, path=()):
    if isinstance(node, dict):
        for key, value in node.items():
            yield from flatten(value, path + (key,))
    elif isinstance(node, list):
        for index, value in enumerate(node):
            yield from flatten(value, path + (index,))
    else:
        yield path, node


def put(node, path, text):
    for step in path[:-1]:
        node = node[step]
    node[path[-1]] = text


def load():
    return {name: {lang: json.loads((ROOT / folder / f'{lang}.json').read_text()) for lang in LANGS} for name, folder, _ in SOURCES}


def export(target):
    files = load()
    with open(target, 'w', newline='', encoding='utf-8-sig') as out:
        sheet = csv.writer(out)
        sheet.writerow(['Where', 'English', 'Hindi', 'Gujarati'])
        for name, texts in files.items():
            hindi, gujarati = dict(flatten(texts['hi'])), dict(flatten(texts['gu']))
            for path, english in flatten(texts['en']):
                sheet.writerow(['/'.join([name, *map(str, path)]), english, hindi[path], gujarati[path]])
    print(f'wrote {target}')


def apply(source):
    files = load()
    paths = {name: {'/'.join([name, *map(str, path)]): (path, english) for path, english in flatten(texts['en'])} for name, texts in files.items()}
    current = {(name, lang): dict(flatten(texts[lang])) for name, texts in files.items() for lang in LANGS[1:]}
    changed = skipped = 0
    with open(source, newline='', encoding='utf-8-sig') as sheet:
        for where, _, *cells in list(csv.reader(sheet))[1:]:
            name = where.split('/')[0]
            if where not in paths.get(name, {}):
                print(f'skipped {where}: no such string')
                skipped += 1
                continue
            path, english = paths[name][where]
            for lang, text in zip(LANGS[1:], cells):
                if text == current[name, lang][path]:
                    continue
                if not text.strip() or sorted(PLACEHOLDER.findall(text)) != sorted(PLACEHOLDER.findall(english)):
                    print(f'skipped {where} ({lang}): it is empty, or lost a placeholder such as %1$s that the English has')
                    skipped += 1
                    continue
                put(files[name][lang], path, text)
                changed += 1
    for name, folder, indent in SOURCES:
        for lang in LANGS[1:]:
            (ROOT / folder / f'{lang}.json').write_text(json.dumps(files[name][lang], ensure_ascii=False, indent=indent) + ('\n' if indent else ''))
    print(f'{changed} strings updated, {skipped} skipped')


if len(sys.argv) > 1 and sys.argv[1] == 'export':
    export(sys.argv[2] if len(sys.argv) > 2 else 'translations.csv')
elif len(sys.argv) == 3 and sys.argv[1] == 'apply':
    apply(sys.argv[2])
else:
    sys.exit(__doc__)
