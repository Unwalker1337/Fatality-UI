"""Run with: python tests/run.py --luau /path/to/luau"""
import argparse
from pathlib import Path
import shutil
import subprocess
import tempfile

parser = argparse.ArgumentParser()
parser.add_argument('--luau', default=shutil.which('luau'))
args = parser.parse_args()
if not args.luau:
    parser.error('Pass --luau or put the Luau CLI on PATH')
root = Path(__file__).resolve().parents[1]
parts = ['LIB_SOURCE = [====[' + (root/'src/source.luau').read_text(encoding='utf-8') + ']====]\n',
         (root/'tests/roblox_mock.luau').read_text(encoding='utf-8'),
         (root/'tests/binds_tabs.luau').read_text(encoding='utf-8')]
with tempfile.TemporaryDirectory(prefix='fatality-ui-tests-') as folder:
    harness = Path(folder)/'verify.luau'
    harness.write_text('\n'.join(parts), encoding='utf-8')
    raise SystemExit(subprocess.run([args.luau, str(harness)]).returncode)
