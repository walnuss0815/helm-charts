import os, string, sys
from pathlib import Path

input_dir = Path(sys.argv[1])
output_dir = Path(sys.argv[2])
output_dir.mkdir(parents=True, exist_ok=True)

for f in input_dir.iterdir():
    if not f.is_file():
        continue
    result = string.Template(f.read_text()).safe_substitute(os.environ)
    out = output_dir / f.name
    out.write_text(result)
    print(f"Templated: {f} → {out}")
