"""Compile the standalone file, then run mocked Roblox role and lifecycle checks.

Set LUAU_BIN and LUAU_COMPILE_BIN if the standalone Luau tools are not on PATH.
This cannot verify the live game's data schema or reproduce Roblox rendering.
"""
import os
from pathlib import Path
import shutil
import subprocess
import tempfile

root = Path(__file__).resolve().parents[1]
luau = os.environ.get("LUAU_BIN") or shutil.which("luau")
compiler = os.environ.get("LUAU_COMPILE_BIN") or shutil.which("luau-compile")
if not luau or not compiler:
    raise SystemExit("Install Luau or set LUAU_BIN and LUAU_COMPILE_BIN.")
source = root / "main.lua"
subprocess.run([compiler, "--null", str(source)], check=True)
fixture = (root / "tests" / "checks.luau").read_text()
fixture = fixture.replace("-- INSERT STANDALONE HUB", source.read_text())
with tempfile.TemporaryDirectory() as directory:
    path = Path(directory) / "checks.luau"
    path.write_text(fixture)
    subprocess.run([luau, str(path)], check=True)

# Exercise the new support module independently of game UI discovery.
module=(root/'src/SessionTools.lua').read_text()
fixture=(root/'tests/session_checks.luau').read_text().replace('-- SESSION',module)
with tempfile.TemporaryDirectory() as directory:
    path=Path(directory)/'session.luau';path.write_text(fixture)
    subprocess.run([luau,str(path)],check=True)
import re,html
page=(root/'docs/SuperheroArena_Editor.html').read_text()
assert html.unescape(re.search(r'<textarea id="source"[^>]*>(.*?)</textarea>',page,re.S).group(1))==source.read_text()
for module in ['Visuals','Instinct','Interface','SessionTools']:
    assert (root/'src'/f'{module}.lua').read_text() in source.read_text()
print('PASS: embedded feature sources and complete editable-file parity.')

report=re.search(r'<textarea id="reportSource"[^>]*>(.*?)</textarea>',page,re.S).group(1)
assert len(report)<2000 and 'Diagnostics' in html.unescape(report)
with tempfile.NamedTemporaryFile(mode='w',suffix='.js') as file:
    file.write(re.search(r'<script>(.*?)</script>',page,re.S).group(1));file.flush()
    subprocess.run(['node','--check',file.name],check=True)
print('PASS: editor targets the full code field; diagnostic snippet and browser syntax preserved.')
