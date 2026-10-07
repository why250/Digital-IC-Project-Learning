"""Check repository Markdown navigation and lesson coverage using the stdlib.

Run from any directory: python tools/check_docs.py
Generated results are optional; this checker never runs EDA tools or uses SSH.
"""

from collections import Counter
from pathlib import Path
import re
import subprocess
import sys
import unicodedata
from urllib.parse import unquote, urlsplit


ROOT = Path(__file__).resolve().parents[1]
LINK = re.compile(r"!?\[[^\]\n]*\]\(([^)\n]+)\)")
HEADING = re.compile(r"^#{1,6}\s+(.+?)\s*#*\s*$")


def prose(text):
    """Ignore fenced examples when inspecting headings and links."""
    marker = None
    result = []
    for line in text.splitlines():
        fence = re.match(r"^\s{0,3}(`{3,}|~{3,})", line)
        if fence:
            token = fence[1]
            if marker is None:
                marker = token
            elif token[0] == marker[0] and len(token) >= len(marker):
                marker = None
        elif marker is None:
            result.append(line)
    return "\n".join(result)


def anchors(text):
    """GitHub-style heading IDs, including repeated-heading suffixes."""
    seen = set()
    for line in text.splitlines():
        match = HEADING.match(line)
        if not match:
            continue
        title = re.sub(r"\[([^\]]+)\]\([^)]+\)", r"\1", match[1]).lower()
        slug = "".join(
            c for c in title
            if c in " -_" or unicodedata.category(c)[0] in "LNM"
        ).replace(" ", "-")
        candidate = slug
        suffix = 0
        while candidate in seen:
            suffix += 1
            candidate = f"{slug}-{suffix}"
        seen.add(candidate)
    return seen


def main():
    listing = subprocess.run(
        ["git", "ls-files", "--cached", "--others", "--exclude-standard", "-z"],
        cwd=ROOT, capture_output=True, check=True,
    )
    paths = sorted({
        ROOT / name for name in listing.stdout.decode("utf-8").split("\0")
        if name.endswith(".md")
    })
    errors = []
    texts = {}
    for path in paths:
        try:
            texts[path] = prose(path.read_text(encoding="utf-8-sig"))
        except (UnicodeError, OSError) as exc:
            errors.append(f"{path.relative_to(ROOT)}: {exc}")

    graph = {path: set() for path in texts}
    local_links = 0
    generated_links = 0
    for source, text in texts.items():
        for match in LINK.finditer(text):
            # The repository uses inline destinations; optional quoted titles
            # and angle-wrapped destinations are accepted as well.
            raw = match[1].strip()
            target = raw[1:raw.index(">")] if raw.startswith("<") else raw.split()[0]
            url = urlsplit(target)
            if url.scheme or url.netloc:
                continue
            local_links += 1
            path = (source.parent / unquote(url.path)).resolve() if url.path else source
            label = f"{source.relative_to(ROOT)} -> {target}"
            if not path.is_relative_to(ROOT):
                errors.append(f"Outside repository: {label}")
                continue
            relative = path.relative_to(ROOT)
            if "results" in relative.parts or ".tools" in relative.parts:
                generated_links += 1
                continue
            if not path.is_file():
                errors.append(f"Missing file: {label}")
                continue
            if path in texts:
                graph[source].add(path)
                if url.fragment and unquote(url.fragment) not in anchors(texts[path]):
                    errors.append(f"Missing heading: {label}")

    # Each lecture and answer series must cover every lesson exactly once.
    series = [
        ("course", "", 1, 24, "0[1-6]_*.md", "07_answers.md"),
        ("mixed_signal", "", 25, 48, "0[1-6]_*.md", "08_answers.md"),
        ("delta_sigma_filter", "DF", 1, 8, "0[1-8]_*.md", "10_answers.md"),
        ("adc_digital", "AD", 1, 20, "0[1-5]_*.md", "07_answers.md"),
        ("dac_digital", "TD", 1, 12, "0[1-4]_*.md", "06_answers.md"),
        ("ams", "AM", 1, 6, "0[1-6]_*.md", "09_answers.md"),
    ]
    for folder, prefix, first, last, lectures, answers in series:
        directory = ROOT / "docs" / folder
        pattern = re.compile(rf"^#{{1,2}} {prefix}(\d{{2}})(?=[:：\s]|$)", re.M)
        expected = Counter(range(first, last + 1))
        for kind, files in (
            ("lectures", sorted(directory.glob(lectures))),
            ("answers", [directory / answers]),
        ):
            actual = Counter(
                int(number) for file in files
                for number in pattern.findall(texts.get(file, ""))
            )
            if actual != expected:
                errors.append(
                    f"Lesson coverage {folder}/{kind}: "
                    f"missing={dict(expected - actual)} extra={dict(actual - expected)}"
                )

    pending = [ROOT / "README.md"]
    reachable = set()
    while pending:
        path = pending.pop()
        if path not in reachable:
            reachable.add(path)
            pending.extend(graph.get(path, ()))
    for path in texts:
        if path != ROOT / "AGENTS.md" and path not in reachable:
            errors.append(f"Unreachable from README: {path.relative_to(ROOT)}")

    if errors:
        print("\n".join(errors), file=sys.stderr)
        return 1
    print(
        f"DOCS_CHECK_COMPLETE files={len(texts)} local_links={local_links} "
        f"optional_generated_links={generated_links} series={len(series)} "
        "coverage=PASS navigation=PASS utf8=PASS"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
