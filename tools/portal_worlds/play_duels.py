#!/usr/bin/env python3
"""Play or verify portal duels. Uses a private display unless --play is explicit."""
import argparse
import atexit
import json
import math
import os
from pathlib import Path
import signal
import shutil
import sys
import threading
import subprocess
import time

from income_settings import team_income_multipliers
from portal_paths import WORKSPACE, DEFAULT_GAME, diagnostic_library

def main():
	parser = argparse.ArgumentParser()
	parser.add_argument('name', nargs='?', default=time.strftime('duels-%Y%m%d-%H%M%S'))
	parser.add_argument('--prepare-only', action='store_true', help='Write isolated launch files without starting the engine')
	parser.add_argument('--mode', default='duels')
	parser.add_argument('--normal', action='store_true', help='Original Living Lands, clean Zero-K checkout, ordinary 1v1 without portal modoptions')
	parser.add_argument('--game-dir', type=Path, default=DEFAULT_GAME, help='Zero-K source checkout (default: this checkout); --normal disables portal mode')
	parser.add_argument('--seconds', type=int, default=1200)
	parser.add_argument('--ai', help='Defaults to CircuitAI for play, passive NullAI for scripted fixtures')
	parser.add_argument('--ai-dir', type=Path, help='Optional isolated AI root, including Interfaces/ and Skirmish/')
	parser.add_argument('--record', action='store_true', help='Record all-world dots as a spectator (headless or --watch)')
	income_options = parser.add_mutually_exclusive_group()
	income_options.add_argument('--duel-income-multiplier', type=float, default=1, help='Income factor for the first team in each region')
	income_options.add_argument('--region-income-multipliers', help='Comma-separated income factors for the first team in each authored region, e.g. 2,4,8,16')
	parser.add_argument('--map', default='Portal Worlds v3')
	parser.add_argument('--offscreen-gpu', action='store_true', help='Render on the GPU with SDL offscreen, without a desktop window')
	parser.add_argument('--x11-hidden', action='store_true', help='Use an unmapped desktop GL window for renderer comparisons')
	parser.add_argument('--settings-from', type=Path, help='Copy a previous run\'s graphics and LuaUI settings for reproduction')
	parser.add_argument('--render-fps', type=float, default=30, help='Offscreen drawing cap; zero disables it')
	parser.add_argument('--frames', type=int, default=54000)
	parser.add_argument('--headless', action='store_true')
	parser.add_argument('--human', action='store_true', help='Offscreen human team for input tests')
	parser.add_argument('--watch', action='store_true', help='Explicitly open a visible AI match')
	parser.add_argument('--play', action='store_true', help='Explicitly launch a visible human-vs-AI game; runs until you exit')
	parser.add_argument('--teams', type=int, default=None)
	parser.add_argument('--speed', type=float, default=10)
	parser.add_argument('--test', default='none')
	parser.add_argument('--modoption', action='append', default=[], metavar='KEY=VALUE', help='Additional game modoption (repeatable)')
	parser.add_argument('--engine-dir', type=Path, required=True, help='Recoil install directory')
	parser.add_argument('--nano', choices=['legacy','geometry','instanced'], default='legacy')
	parser.add_argument('--shadows', type=int, choices=[0,1,2], default=1)
	parser.add_argument('--factories', choices=['cloak','all'], default='all')
	args = parser.parse_args()
	if not math.isfinite(args.duel_income_multiplier) or args.duel_income_multiplier < 1:
		parser.error('--duel-income-multiplier must be finite and at least 1')
	if args.record and (args.play or args.human): parser.error('--record requires a spectator; use --watch or --headless')
	args.ai = args.ai or ('NullAI' if args.test != 'none' else 'CircuitAI')
	game_dir=args.game_dir.resolve()
	if args.normal:
		args.mode='baseline'
		args.teams=2
		if args.map.startswith('Portal Worlds '): args.map='Living Lands 4.1'
	layout=None
	for candidate in (WORKSPACE/'content/maps').glob('*.sdd/composition.json'):
		data=json.loads(candidate.read_text())
		if data.get('name',data.get('map'))==args.map: layout=data;break
	if args.normal:
		from map_sources import lua_data,map_info
		import struct
		normal_source=None
		for source in (WORKSPACE/'content').glob('*-source'):
			files=list((source/'maps').glob('*.smf'))
			if not files: continue
			info=map_info(source)
			native_name=(info.get('name','')+' '+str(info.get('version',''))).strip()
			if args.map in (native_name,files[0].stem): normal_source=source;normal_smf=files[0];break
		if normal_source is None: parser.error('Original map source is not available for '+args.map)
		startfile=normal_source/'mapconfig/map_startboxes.lua'
		if not startfile.exists(): startfile=game_dir/'LuaRules/Configs/StartBoxes'/(args.map+'.lua')
		boxes=lua_data(startfile,normal_source)
		boxes=boxes if isinstance(boxes,list) else [b for _,b in sorted(boxes.items(),key=lambda item:int(item[0]))]
		header=struct.unpack_from('<16s7i2f7i',normal_smf.read_bytes())
		layout={'size':[header[3]*8,header[4]*8],'teams':[{'team':i,'region':1,'start':b['startpoints'][0],'boxes':b['boxes']} for i,b in enumerate(boxes[:2])]}
	if not layout or 'teams' not in layout: parser.error('Map has no generated composition manifest; run build_portal_worlds.py first')
	if args.teams is None: args.teams=len(layout['teams'])
	if not 1<=args.teams<=len(layout['teams']): parser.error('Team count exceeds the authored start positions')
	try:
		income_multipliers = team_income_multipliers(layout['teams'], args.duel_income_multiplier, args.region_income_multipliers)
	except ValueError as error:
		parser.error(str(error))
	game_dir=args.game_dir.resolve()
	if not game_dir.is_dir(): parser.error('Game checkout does not exist: '+str(game_dir))
	engine_dir = args.engine_dir.resolve()
	if args.watch and args.play: parser.error('Choose --watch or --play')
	args.human = args.human or args.play or (args.test != 'none' and not args.headless and not args.normal)
	args.play = args.play or args.watch
	if args.play and (args.headless or args.test != 'none' ): parser.error('--play uses ordinary gameplay only')
	run = WORKSPACE / 'runs' / args.name
	run.mkdir(parents=True, exist_ok=False)
	xlog = (run / 'xvfb.log').open('w')
	xserver = None if args.prepare_only or args.headless or args.play or args.offscreen_gpu or args.x11_hidden else subprocess.Popen(['Xvfb', ':117', '-screen', '0', '1280x720x24', '-nolisten', 'tcp', '-ac', '-noreset'], stdout=xlog, stderr=subprocess.STDOUT)
	atexit.register(lambda: xserver.terminate() if xserver and xserver.poll() is None else None)
	time.sleep(1)
	if xserver and xserver.poll() is not None:
		raise RuntimeError('Could not start private Xvfb; see xvfb.log')
	iso = run / 'isolation'
	write = run / 'write'
	for path in (iso / 'games', iso / 'maps', write / 'screenshots'):
		path.mkdir(parents=True, exist_ok=True)
	for name in ('base', 'fonts'):
		(iso / name).symlink_to(engine_dir / name)
	ai_dir = args.ai_dir.resolve() if args.ai_dir else engine_dir/'AI'
	(iso/'AI').symlink_to(ai_dir)
	(iso / 'games/Zero-K.sdd').symlink_to(game_dir)
	for path in [*(WORKSPACE/'content/maps').iterdir(),*(WORKSPACE/'content').glob('*.sd7')]:
		if not (iso/'maps'/path.name).exists(): (iso/'maps'/path.name).symlink_to(path)
	if args.normal: (iso/'maps/original.sdd').symlink_to(normal_source)
	settings = {
		'Fullscreen': 0, 'XResolutionWindowed': 1280, 'YResolutionWindowed': 720,
		'WindowPosX': 0, 'WindowPosY': 0, 'VSync': 0, 'HangTimeout': 60, 'snd_volmaster': 0,
		'Sound': 0, 'LuaSocketEnabled': 0, 'DevLua': 1, 'UseLuaMemPools': 0,
		'TextureMemPoolSize': 0, 'Shadows': args.shadows, 'ShadowMapSize': 2048, 'GrassDetail': 0, 'Water': 0,
		'GroundDetail': 100, 'MaxParticles': 20000, 'MaxNanoParticles': 5000,
		'UnitIconDist': 10000, 'UnitIconsAsUI': 0,
		'AdvUnitShading': 1, 'AdvMapShading': 1, 'ROAM': 1,
		'AllowDeferredMapRendering': 1, 'AllowDeferredModelRendering': 1,
		'NanoParticlesGL4': int(args.nano!='legacy'), 'NanoParticlesNoGeometryShader': int(args.nano=='instanced'),
		'WorkerThreadCount': 2, 'ShowFPS': 1, 'ShowClock': 1,
	}
	config = run / 'spring.conf'
	if args.settings_from:
		for line in (args.settings_from/'spring.conf').read_text().splitlines():
			if '=' in line:
				key,value=line.split('=',1)
				settings[key.strip()]=value.strip()
		if (args.settings_from/'write/LuaUI').is_dir():
			shutil.copytree(args.settings_from/'write/LuaUI',write/'LuaUI')
	config.write_text(''.join(f'{key} = {value}\n' for key, value in settings.items()))
	ai_root=ai_dir/'Skirmish'/args.ai
	ai_versions=sorted(path.name for path in ai_root.iterdir() if path.is_dir())
	ai_version='stable' if 'stable' in ai_versions else ai_versions[-1]
	port = 21000 + os.getpid() % 20000
	script = run / 'start.txt'
	disabled = '' if args.factories == 'all' else 'factoryhover+factoryship+factoryamph+factoryplane+factorygunship+factoryveh+factorytank+factoryjump+factoryspider+factoryshield+striderhub'
	positions=[entry['start'] for entry in layout['teams']]
	colors = ['0.2 0.6 1','1 0.25 0.2','0.2 1 0.65','1 0.7 0.15','0.7 0.4 1','1 0.4 0.75','0.2 0.9 1','0.8 0.9 0.2']
	import colorsys
	while len(colors)<args.teams:
		colors.append(' '.join(map(str,colorsys.hsv_to_rgb(len(colors)*0.61803398875%1,.7,1))))
	portal_options='' if args.normal else f'zk_duels={args.mode}; zk_duels_headless={1 if args.headless else 0}; zk_duels_end={0 if args.play else args.frames}; zk_duels_test={args.test}; zk_duels_speed={1 if args.play else args.speed};'
	if args.normal and args.test != 'none':
		portal_options=f'zk_duels_test={args.test}; zk_duels_speed={args.speed};'
	if args.record:
		portal_options += f'portal_record=1; portal_record_end={0 if args.play else args.frames}; portal_record_quit={0 if args.play else 1}; portal_record_speed={1 if args.play else args.speed};'
	import re
	for option in args.modoption:
		if not re.fullmatch(r'[a-zA-Z0-9_]+=[a-zA-Z0-9_.+-]+', option):
			parser.error('Invalid --modoption: ' + option)
		portal_options += option + ';'
	parts = [f"""[GAME]
{{
 GameType=Zero-K $VERSION;
 MapName={args.map};
 IsHost=1;
 HostPort={port};
 GameStartDelay=0;
 StartPosType=3;
 MyPlayerName=Probe;
 [MODOPTIONS] {{ {portal_options} maxspeed=100; minspeed=0.1; fixedstartpos=1; shuffle=off; commends=1; }}
 [PLAYER0] {{ Name=Probe; Spectator={0 if args.human else 1}; Team=0; }}
"""]
	for team in range(args.teams):
		x,z = positions[team]
		if not (args.human and team == 0):
			parts.append(f'[AI{team}] {{ Name=Circuit{team}; ShortName={args.ai}; Version={ai_version}; Team={team}; Host=0; [OPTIONS] {{ profile=default; cheating=0; ally_aware=0; disabledunits={disabled}; }} }}')
		income = income_multipliers[team]
		parts.append(f'[TEAM{team}] {{ TeamLeader=0; AllyTeam={team}; IncomeMultiplier={income}; RgbColor={colors[team]}; StartPosX={x}; StartPosZ={z}; [CUSTOMKEYS] {{ start_x={x}; start_z={z}; }} }}')
		polygon=layout['teams'][team]['boxes'][0]
		x0,x1=min(p[0] for p in polygon)/layout['size'][0],max(p[0] for p in polygon)/layout['size'][0]
		z0,z1=min(p[1] for p in polygon)/layout['size'][1],max(p[1] for p in polygon)/layout['size'][1]
		parts.append(f'[ALLYTEAM{team}] {{ NumAllies=0; StartRectLeft={x0}; StartRectTop={z0}; StartRectRight={x1}; StartRectBottom={z1}; }}')
	script.write_text('\n'.join(parts) + '\n}\n')
	fontconfig = run / 'fonts.conf'
	fontconfig.write_text(f'<fontconfig><dir>{engine_dir / "fonts"}</dir><cachedir>{run / "fontcache"}</cachedir></fontconfig>')
	env = dict(os.environ, DISPLAY=':117', LIBGL_ALWAYS_SOFTWARE='1', LP_NUM_THREADS='4', FONTCONFIG_FILE=str(fontconfig),
		SDL_AUDIODRIVER='dummy', ALSOFT_DRIVERS='null')
	cmd = [str(engine_dir / ('spring-headless' if args.headless else 'spring')), '--isolation', '--isolation-dir', str(iso),
		'--write-dir', str(write), '--config', str(config), '--nocolor', str(script)]
	if args.play:
		env = dict(os.environ, FONTCONFIG_FILE=str(fontconfig))
	elif (args.offscreen_gpu or args.x11_hidden) and not args.headless:
		env = dict(os.environ, FONTCONFIG_FILE=str(fontconfig), SDL_VIDEODRIVER='offscreen', SDL_AUDIODRIVER='dummy')
		if args.x11_hidden:
			env.update(SDL_VIDEODRIVER='x11',LD_PRELOAD=str(diagnostic_library('hidden_sdl')))
		env.pop('LIBGL_ALWAYS_SOFTWARE', None)
	if not args.play and not args.headless and args.render_fps>0:
		limiter=diagnostic_library('limit_swap')
		env['LD_PRELOAD']=str(limiter)+(':'+env['LD_PRELOAD'] if env.get('LD_PRELOAD') else '')
		env['SPRING_PROBE_FPS']=str(args.render_fps)
	ai_build = json.loads((ai_dir/'build-info.json').read_text()) if (ai_dir/'build-info.json').exists() else None
	if ai_build is None and not args.ai_dir and (engine_dir/'preview-manifest.json').exists():
		preview = json.loads((engine_dir/'preview-manifest.json').read_text())
		bundled = preview.get('native_ai', {}).get(args.ai)
		if bundled:
			ai_build = dict(bundled, from_engine_preview=True, library_sha256=bundled['packaged_library_sha256'])
	(run / 'command.json').write_text(json.dumps({'command': cmd, 'display': env.get('DISPLAY'),
		'game_worktree_changes': subprocess.check_output(['git','-C',str(game_dir),'status','--porcelain'],text=True).splitlines(),
		'ai_build': ai_build,
		'renderer': 'headless' if args.headless else 'desktop default' if args.play else 'GPU unmapped X11' if args.x11_hidden else 'GPU offscreen' if args.offscreen_gpu else 'llvmpipe',
		'engine_version': subprocess.check_output([cmd[0],'--sync-version'],text=True).strip(),
		'options': {k:str(v) if isinstance(v,Path) else v for k,v in vars(args).items()}, 'game_commit': subprocess.check_output(
		['git', '-C', str(game_dir), 'rev-parse', 'HEAD'], text=True).strip()}, indent=2))
	print(f'Run:         {run}\nLog:         {run / "console.log"}\nEngine log:  {write / "infolog.txt"}\nScreenshots: {write / "screenshots"}\nRecordings:  {write / "recordings"}', flush=True)
	if args.prepare_only:
		xlog.close()
		return
	with (run / 'console.log').open('w') as log:
		process = subprocess.Popen(cmd, env=env, stdout=subprocess.PIPE if args.play else log, stderr=subprocess.STDOUT, start_new_session=True)
		def stream_output():
			for raw in iter(process.stdout.readline, b''):
				line=raw.decode('utf-8', errors='replace')
				log.write(line);log.flush()
				try: sys.stdout.write(line);sys.stdout.flush()
				except BrokenPipeError: pass
		stream = threading.Thread(target=stream_output, daemon=True) if args.play else None
		if stream: stream.start()
		(run / 'pid').write_text(str(process.pid))
		start = time.monotonic()
		shots = set()
		while process.poll() is None and (args.play or time.monotonic() - start < args.seconds):
			elapsed = time.monotonic() - start
			for stamp in (20, 45, 90, 150, 240):
				if not args.headless and not args.play and not args.offscreen_gpu and not args.x11_hidden and elapsed >= stamp and stamp not in shots:
					capture(run / f'screen-{stamp:03d}.png')
					shots.add(stamp)
			time.sleep(0.5)
		if process.poll() is None:
			if not args.headless and not args.play and not args.offscreen_gpu and not args.x11_hidden: capture(run / 'screen-final.png')
			process.terminate()
			try:
				process.wait(timeout=8)
			except subprocess.TimeoutExpired:
				os.killpg(process.pid, signal.SIGKILL)
				process.wait()
		if stream: stream.join(timeout=5)
		(run / 'exit.json').write_text(json.dumps({'exit_code': process.returncode,
			'elapsed_seconds': time.monotonic() - start}, indent=2))
	if xserver:
		xserver.terminate()
		xserver.wait(timeout=5)
	xlog.close()
	print(run)
	raise SystemExit(process.returncode)

def capture(path):
	from PIL import ImageGrab
	ImageGrab.grab(xdisplay=':117').save(path)

if __name__ == '__main__':
	main()
