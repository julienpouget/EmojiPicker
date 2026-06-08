#!/usr/bin/env python3
#
# generate-emoji-data.py
# EmojiPicker
#
# Copyright © 2026 Julien Pouget.
# Licensed under the MIT License. See LICENSE.
#
"""Generate the bundled emojis.json from the Unicode emoji-test.txt file.

By default it downloads the **latest released** Unicode emoji data and writes a
compact JSON to the package resources. The Unicode version is taken from the
file's own "# Version:" header, so the output always reflects the source.

Usage:
  generate-emoji-data.py [output]                 # latest released version
  generate-emoji-data.py [output] --version 16.0  # a specific version
  generate-emoji-data.py [output] --input FILE    # a local emoji-test.txt
  generate-emoji-data.py [output] --url URL        # an explicit URL

Sources (Unicode moved emoji into the main UCD release from 17.0):
  latest : https://www.unicode.org/Public/UCD/latest/emoji/emoji-test.txt
  >=17.0 : https://www.unicode.org/Public/<x.y.0>/emoji/emoji-test.txt
  <=16.0 : https://www.unicode.org/Public/emoji/<x.y>/emoji-test.txt

Output structure:
{
  "unicodeVersion": "17.0",
  "categories": [ { "id": "<categoryId>", "emojis": [ {emoji}, ... ] }, ... ]
}

emoji object:
  e : base emoji string
  n : lowercase name
  v : emoji version (float, e.g. 0.6, 14.0)
  k : list of search keyword tokens (from name + subgroup)
  t : optional { "0".."4": tonedString } uniform skin-tone variants
"""
import argparse
import json
import re
import sys
import urllib.request

LATEST_URL = "https://www.unicode.org/Public/UCD/latest/emoji/emoji-test.txt"

SKIN_MODIFIERS = {
    0x1F3FB: 0,  # light
    0x1F3FC: 1,  # medium-light
    0x1F3FD: 2,  # medium
    0x1F3FE: 3,  # medium-dark
    0x1F3FF: 4,  # dark
}

# Map Unicode group name -> our stable category id. "Component" is skipped.
GROUP_TO_CATEGORY = {
    "Smileys & Emotion": "smileysAndPeople",
    "People & Body": "smileysAndPeople",
    "Animals & Nature": "animalsAndNature",
    "Food & Drink": "foodAndDrink",
    "Travel & Places": "travelAndPlaces",
    "Activities": "activities",
    "Objects": "objects",
    "Symbols": "symbols",
    "Flags": "flags",
}

CATEGORY_ORDER = [
    "smileysAndPeople",
    "animalsAndNature",
    "foodAndDrink",
    "activities",
    "travelAndPlaces",
    "objects",
    "symbols",
    "flags",
]

STOPWORDS = {"and", "with", "of", "the", "a", "in", "on", "to", "for"}

DEFAULT_OUTPUT = "Sources/EmojiPicker/Resources/emojis.json"


def candidate_urls(version):
    """URLs to try for a pinned version, newest layout first."""
    parts = version.split(".")
    while len(parts) < 3:
        parts.append("0")
    new_layout = f"https://www.unicode.org/Public/{'.'.join(parts)}/emoji/emoji-test.txt"
    old_layout = f"https://www.unicode.org/Public/emoji/{parts[0]}.{parts[1]}/emoji-test.txt"
    return [new_layout, old_layout]


def fetch(url):
    request = urllib.request.Request(url, headers={"User-Agent": "EmojiPicker-generator"})
    with urllib.request.urlopen(request, timeout=60) as response:
        return response.read().decode("utf-8")


def load_source(args):
    """Return (text, label) for the emoji-test.txt to parse."""
    if args.input:
        with open(args.input, encoding="utf-8") as f:
            return f.read(), args.input
    urls = [args.url] if args.url else (
        candidate_urls(args.version) if args.version else [LATEST_URL]
    )
    last_error = None
    for url in urls:
        try:
            print(f"downloading {url}", file=sys.stderr)
            return fetch(url), url
        except Exception as error:  # noqa: BLE001 - report and try the next URL
            last_error = error
            print(f"  failed: {error}", file=sys.stderr)
    raise SystemExit(f"could not download emoji data: {last_error}")


def parse(lines):
    categories = {cid: [] for cid in CATEGORY_ORDER}
    base_index = {}  # base codepoint tuple -> emoji dict, to attach skin variants
    current_category = None
    current_subgroup = ""
    unicode_version = "?"

    line_re = re.compile(
        r"^([0-9A-Fa-f ]+);\s*(\S+)\s*#\s*(\S+)\s+E([0-9.]+)\s+(.*)$"
    )

    for raw in lines:
        line = raw.rstrip("\n")
        if line.startswith("# Version:"):
            unicode_version = line.split(":", 1)[1].strip()
            continue
        if line.startswith("# group:"):
            gname = line.split(":", 1)[1].strip()
            current_category = GROUP_TO_CATEGORY.get(gname)
            continue
        if line.startswith("# subgroup:"):
            current_subgroup = line.split(":", 1)[1].strip().replace("-", " ")
            continue
        if not line or line.startswith("#"):
            continue
        if current_category is None:
            continue  # Component group etc.
        m = line_re.match(line)
        if not m:
            continue
        if m.group(2) != "fully-qualified":
            continue
        cps_str, _, emoji, ver, name = m.group(1), m.group(2), m.group(3), m.group(4), m.group(5)
        cps = [int(x, 16) for x in cps_str.split()]
        version = float(ver)
        name = name.strip().lower()

        # Classify skin tones used in this sequence.
        tones = [SKIN_MODIFIERS[c] for c in cps if c in SKIN_MODIFIERS]
        base_cps = [c for c in cps if c not in SKIN_MODIFIERS]
        base_key = tuple(base_cps)

        if not tones:
            # Base emoji.
            tokens = [
                t for t in re.split(r"[ \-_:,&]+", name + " " + current_subgroup)
                if t and t not in STOPWORDS
            ]
            seen = set()
            kw = []
            for t in tokens:  # dedupe, preserving order
                if t not in seen:
                    seen.add(t)
                    kw.append(t)
            obj = {"e": emoji, "n": name, "v": version, "k": kw}
            base_index[base_key] = obj
            categories[current_category].append(obj)
        else:
            # Skin-tone variant. Only keep "uniform" tone variants (all
            # modifiers identical) so a single global tone applies.
            if len(set(tones)) != 1:
                continue
            base = base_index.get(base_key)
            if base is None:
                continue
            base.setdefault("t", {})[str(tones[0])] = emoji

    ordered = [{"id": cid, "emojis": categories[cid]} for cid in CATEGORY_ORDER]
    return {"unicodeVersion": unicode_version, "categories": ordered}


def main():
    parser = argparse.ArgumentParser(description="Generate emojis.json from Unicode emoji-test.txt.")
    parser.add_argument("output", nargs="?", default=DEFAULT_OUTPUT,
                        help=f"output JSON path (default: {DEFAULT_OUTPUT})")
    parser.add_argument("--version", help="Unicode version to fetch, e.g. 16.0 (default: latest released)")
    parser.add_argument("--input", help="use a local emoji-test.txt instead of downloading")
    parser.add_argument("--url", help="explicit emoji-test.txt URL")
    args = parser.parse_args()

    text, label = load_source(args)
    data = parse(text.splitlines())

    with open(args.output, "w", encoding="utf-8") as f:
        json.dump(data, f, ensure_ascii=False, indent=2)
        f.write("\n")

    total = sum(len(c["emojis"]) for c in data["categories"])
    toned = sum(1 for c in data["categories"] for e in c["emojis"] if "t" in e)
    print(f"source: {label}")
    print(f"unicode {data['unicodeVersion']}: {total} base emojis, {toned} with skin tones -> {args.output}")
    for c in data["categories"]:
        print(f"  {c['id']}: {len(c['emojis'])}")


if __name__ == "__main__":
    main()
