"""Usage-level colour lint for Pasture's Swift views (the AA gate checks token pairs, not how views use them).

    python3 color_usage_lint.py <repo-root>

Fails (exit 1) on:
  R1  a fill token used as a foreground: foregroundStyle(... brandFill ...)  -> dark mode text fails AA (2.6-3.7:1)
  R2  a raw system colour in a view (.white / .black / Color.white / Color.black)
  R3  an asset looked up by string outside the theme: Color("...")
  R4  quiz correctness colours (correct*/wrong*) outside the quiz views
"""
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
DEFAULT_ROOT = os.path.dirname(os.path.dirname(HERE))
QUIZ = {'Shepherd/Views/Lesson/QuizView.swift', 'Shepherd/Views/Components/ShepherdComponents.swift'}
RULES = [
    # greedy to the end of the line, so a ')' inside a ternary or call cannot hide the token
    ('R1', re.compile(r'foregroundStyle\(.*(?:brandFill|shepherdBrandFill)'), None),
    ('R2', re.compile(r'(?<![A-Za-z])(?:Color)?\.(?:white|black)\b'), None),
    ('R3', re.compile(r'Color\("[A-Za-z]+"\)'), None),
    ('R4', re.compile(r'(?:ShepherdTheme\.(?:success|successSubtle|error|errorSubtle|correct|correctSubtle|wrong|wrongSubtle)|(?:Color)?\.shepherd(?:Correct|Wrong|Success|Error))\b'), QUIZ),
]

def run_lint(root=None):
    root = root or DEFAULT_ROOT
    shepherd_dir = os.path.join(root, 'Shepherd')
    widgets_dir = os.path.join(root, 'ShepherdWidgets')
    if not os.path.isdir(shepherd_dir) and not os.path.isdir(widgets_dir):
        print(f"error: neither Shepherd/ nor ShepherdWidgets/ found under {root}", file=sys.stderr)
        sys.exit(2)
    hits = []
    for base in ('Shepherd', 'ShepherdWidgets'):
        base_dir = os.path.join(root, base)
        if not os.path.isdir(base_dir):
            continue
        for dp, _, fs in os.walk(base_dir):
            for f in fs:
                if not f.endswith('.swift'):
                    continue
                p = os.path.join(dp, f)
                rel = os.path.relpath(p, root)
                if rel.startswith('Shepherd/Theme/'):
                    continue
                with open(p, encoding='utf-8') as f_in:
                    for i, line in enumerate(f_in, 1):
                        code = line.split('//')[0]
                        for rid, rx, allowed in RULES:
                            if rx.search(code) and not (allowed and rel in allowed):
                                hits.append((rid, rel, i, code.strip()[:110]))
    counts = {}
    for rid, rel, i, code in hits:
        counts[rid] = counts.get(rid, 0) + 1
        print(f'{rid} {rel}:{i}  {code}')
    print('summary:', ', '.join(f'{k}={v}' for k, v in sorted(counts.items())) or 'clean')
    return hits, counts

if __name__ == '__main__':
    hits, _ = run_lint(sys.argv[1] if len(sys.argv) > 1 else None)
    sys.exit(1 if hits else 0)
