#!/usr/bin/env python3
"""Save a live Zero-K fixture, load it in a fresh process, and verify continuation."""
import argparse
import json
import os
from pathlib import Path
import re
import signal
import subprocess
import sys
import time

from portal_paths import ROOT, WORKSPACE, DEFAULT_GAME, diagnostic_library


def execute(command, env, output, seconds):
    with output.open('w') as log:
        process = subprocess.Popen(command, env=env, stdout=log, stderr=subprocess.STDOUT,
                                   start_new_session=True)
        try:
            return process.wait(timeout=seconds)
        except subprocess.TimeoutExpired:
            return -1
        finally:
            if process.poll() is None:
                os.killpg(process.pid, signal.SIGTERM)
                try:
                    process.wait(timeout=5)
                except subprocess.TimeoutExpired:
                    os.killpg(process.pid, signal.SIGKILL)
                    process.wait()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--engine-dir', type=Path, required=True)
    parser.add_argument('--game-dir', type=Path, default=DEFAULT_GAME)
    parser.add_argument('--output', type=Path, help='Fresh output directory (default: timestamped workspace run)')
    parser.add_argument('--normal', action='store_true', help='Ordinary single-map control')
    parser.add_argument('--seconds', type=int, default=90, help='Timeout per process')
    args = parser.parse_args()
    name = ('save-normal-' if args.normal else 'save-portals-') + time.strftime('%Y%m%d-%H%M%S')
    output = (args.output or WORKSPACE / 'runs' / name).resolve()
    fixture = 'mechanics-baseline' if args.normal else 'mechanics-full'
    command = [sys.executable, str(ROOT / 'play_duels.py'), str(output), '--prepare-only',
               '--engine-dir', str(args.engine_dir.resolve()), '--game-dir', str(args.game_dir.resolve()),
               '--test', fixture, '--modoption', 'zk_duels_save=1', '--offscreen-gpu',
               '--frames', '1800', '--speed', '6']
    if args.normal:
        command.append('--normal')
    subprocess.run(command, check=True)
    launch = json.loads((output / 'command.json').read_text())
    command = launch['command']
    command.insert(1, '--only-local')
    (output / 'command.json').write_text(json.dumps(launch, indent=2) + '\n')
    env = dict(os.environ, SDL_VIDEODRIVER='offscreen', SDL_AUDIODRIVER='dummy',
               FONTCONFIG_FILE=str(output / 'fonts.conf'),
               LD_PRELOAD=str(diagnostic_library('limit_swap')), SPRING_PROBE_FPS='30')
    env.pop('LIBGL_ALWAYS_SOFTWARE', None)
    codes = [execute(command, env, output / 'console.log', args.seconds)]
    saved = output / 'write/Saves/portal-mechanics.ssf'
    source = (output / 'console.log').read_text(errors='replace')
    saved_ok = codes[0] == 0 and saved.exists() and saved.stat().st_size > 0
    loaded = ''
    if saved_ok:
        reload_dir = output / 'loaded'
        reload_dir.mkdir()
        config = reload_dir / 'spring.conf'
        config.write_text((output / 'spring.conf').read_text() + '\nPortalFixtureReloaded = 1\n')
        reload_command = list(command)
        reload_command[reload_command.index('--config') + 1] = str(config)
        reload_command[reload_command.index('--write-dir') + 1] = str(reload_dir / 'write')
        reload_command[-1] = str(saved)
        (reload_dir / 'command.json').write_text(json.dumps({'command': reload_command}, indent=2))
        codes.append(execute(reload_command, env, reload_dir / 'console.log', args.seconds))
        loaded = (reload_dir / 'console.log').read_text(errors='replace')
    marker = r'\[FULL_SAVELOAD\] BASELINE_DONE failures=0' if args.normal else r'\[FULL_SAVELOAD\] DONE checks=\d+ failures=0'
    errors = r'pass=false|LUA_ERRRUN|Segmentation fault|sync error|desync'
    passed = saved_ok and codes == [0, 0] and bool(re.search(marker, loaded)) and not re.search(errors, source + loaded, re.I)
    result = {'passed': passed, 'normal': args.normal, 'exit_codes': codes,
              'save_bytes': saved.stat().st_size if saved.exists() else 0,
              'source_assertions': len(re.findall(r'ASSERT .*pass=true', source)),
              'loaded_assertions': len(re.findall(r'ASSERT .*pass=true', loaded)),
              'engine_version': launch['engine_version'], 'game_commit': launch['game_commit']}
    (output / 'result.json').write_text(json.dumps(result, indent=2) + '\n')
    print(json.dumps(result, indent=2))
    if not passed:
        raise SystemExit('FAIL: see ' + str(output))


if __name__ == '__main__':
    main()
