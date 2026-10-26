#!/usr/bin/env python3
"""Run two independent ZK clients, including networked player portal orders."""

import argparse
from contextlib import ExitStack
import json
import os
from pathlib import Path
import re
import signal
import subprocess
import sys
import time

from portal_paths import ROOT, WORKSPACE, DEFAULT_GAME, diagnostic_library


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("name")
    parser.add_argument("--game-dir", type=Path, default=DEFAULT_GAME)
    parser.add_argument("--engine-dir", type=Path, required=True)
    parser.add_argument("--seconds", type=int, default=120)
    parser.add_argument("--rounds", type=int, default=1, choices=range(1, 33), metavar="1..32")
    parser.add_argument("--units", type=int, default=1, choices=range(1, 65), metavar="1..64")
    args = parser.parse_args()
    game = args.game_dir.resolve()
    engine = args.engine_dir.resolve()
    subprocess.run(
        [
            sys.executable,
            str(ROOT / "play_duels.py"),
            args.name,
            "--game-dir",
            str(game),
            "--engine-dir",
            str(engine),
            "--offscreen-gpu",
            "--render-fps",
            "15",
            "--test",
            "network",
            "--frames",
            str(max(3600, args.rounds * 2000 + 1200)),
            "--modoption",
            "zk_duels_network_rounds=" + str(args.rounds),
            "--modoption",
            "zk_duels_network_units=" + str(args.units),
            "--speed",
            "2",
            "--prepare-only",
        ],
        check=True,
    )
    run = WORKSPACE / "runs" / args.name
    metadata = json.loads((run / "command.json").read_text())
    host_command = metadata["command"]
    script = run / "start.txt"
    text = script.read_text()
    # The fixture assigns one human to the first team in each of the first two
    # authored regions. Every other team remains a passive AI.
    composition = next(
        data
        for path in (WORKSPACE / "content/maps").glob("*.sdd/composition.json")
        if (data := json.loads(path.read_text())).get("name", data.get("map")) == metadata["options"]["map"]
    )
    peer_team = next(team["team"] for team in composition["teams"] if team["region"] == 2)
    text = re.sub(r"^\[AI" + str(peer_team) + r"\].*\n", "", text, flags=re.M)
    text = text.replace(
        "[TEAM" + str(peer_team) + "] { TeamLeader=0;", "[TEAM" + str(peer_team) + "] { TeamLeader=1;"
    )
    text = (
        text.rsplit("}", 1)[0]
        + "[PLAYER1] { Name=PortalPeer; Spectator=0; Team="
        + str(peer_team)
        + "; }\n}\n"
    )
    script.write_text(text)
    config = run / "spring.conf"
    config.write_text(config.read_text().replace("WorkerThreadCount = 2", "WorkerThreadCount = 1"))
    peer = run / "peer-isolation"
    peer.mkdir()
    for name in ("games", "maps", "base", "fonts", "AI"):
        (peer / name).symlink_to(run / "isolation" / name)
    port = re.search(r"HostPort=(\d+);", text).group(1)
    peer_script = run / "peer-start.txt"
    peer_script.write_text("[GAME]{IsHost=0;HostIP=127.0.0.1;HostPort=" + port + ";MyPlayerName=PortalPeer;}")
    peer_command = list(host_command)
    peer_command[peer_command.index("--isolation-dir") + 1] = str(peer)
    peer_command[peer_command.index("--write-dir") + 1] = str(run / "peer-write")
    peer_command[-1] = str(peer_script)
    env = dict(
        os.environ,
        SDL_VIDEODRIVER="offscreen",
        SDL_AUDIODRIVER="dummy",
        FONTCONFIG_FILE=str(run / "fonts.conf"),
        LD_PRELOAD=str(diagnostic_library('limit_swap')),
        SPRING_PROBE_FPS="15",
    )
    logs = [run / "console.log", run / "peer-console.log"]
    processes = []
    codes = []
    started = time.monotonic()
    with ExitStack() as stack:
        try:
            for command, path in zip((host_command, peer_command), logs):
                log = stack.enter_context(path.open("w"))
                processes.append(
                    subprocess.Popen(
                        command, env=env, stdout=log, stderr=subprocess.STDOUT, start_new_session=True
                    )
                )
            for process in processes:
                codes.append(process.wait(timeout=max(1, args.seconds - (time.monotonic() - started))))
        except subprocess.TimeoutExpired:
            codes = [-9] * len(processes)
        finally:
            for process in processes:
                if process.poll() is None:
                    os.killpg(process.pid, signal.SIGTERM)
                    try:
                        process.wait(timeout=5)
                    except subprocess.TimeoutExpired:
                        os.killpg(process.pid, signal.SIGKILL)
                        process.wait()
    texts = [path.read_text(errors="replace") for path in logs]
    snapshots = [re.findall(r"\[NETWORK_WITNESS\] ([^\n]+)", text) for text in texts]
    views = [re.findall(r"\[NETWORK_LOCAL_VIEW\] ([^\n]+)", text) for text in texts]
    assertions = [
        re.findall(r"\[(NETWORK_TEST|NETWORK_UI)\] ASSERT (\S+) pass=(true|false)", text) for text in texts
    ]
    passed = all(
        code == 0
        and "PORTAL_NETWORK_PASS" in text
        and "LUA_ERRRUN" not in text
        and not re.search(r"sync error|desync|PORTAL_NETWORK_FAIL|pass=false", text, re.I)
        for code, text in zip(codes, texts)
    )
    transits = [len(re.findall(r"\[ZKDUELS\] TRANSIT ", text)) for text in texts]
    expected_transits = 2 * args.units * args.rounds
    expected_assertions = 6 + args.rounds * (6 * args.units + 4)
    passed = (
        passed
        and transits == [expected_transits, expected_transits]
        and all(len(items) == expected_assertions for items in assertions)
        and len(snapshots[0]) >= 4
        and snapshots[0] == snapshots[1]
        and views[0] == [str(1 + (i % 2)) for i in range(args.rounds + 1)]
        and views[1] == [str(2 - (i % 2)) for i in range(args.rounds + 1)]
    )
    report = {
        "passed": passed,
        "rounds": args.rounds,
        "units_per_client": args.units,
        "expected_transits": expected_transits,
        "observed_transits": transits,
        "expected_assertions_per_client": expected_assertions,
        "exit_codes": codes,
        "elapsed_seconds": time.monotonic() - started,
        "matching_snapshots": snapshots[0] == snapshots[1],
        "snapshot_count": len(snapshots[0]),
        "views": views,
        "assertions": assertions,
        "commands": [host_command, peer_command],
    }
    (run / "network-result.json").write_text(json.dumps(report, indent=2))
    print("PASS" if passed else "FAIL", run)
    raise SystemExit(not passed)


if __name__ == "__main__":
    main()
