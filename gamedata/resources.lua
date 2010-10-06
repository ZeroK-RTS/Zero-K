-- $Id: resources.lua 4609 2009-05-12 01:32:58Z carrepairer $
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
--  file:    resources.lua
--  brief:   resources definitions
--
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local resources = {
	graphics = {
		smoke = {
			'smoke/smoke00.tga',
			'smoke/smoke01.tga',
			'smoke/smoke02.tga',
			'smoke/smoke03.tga',
			'smoke/smoke04.tga',
			'smoke/smoke05.tga',
			'smoke/smoke06.tga',
			'smoke/smoke07.tga',
			'smoke/smoke08.tga',
			'smoke/smoke09.tga',
			'smoke/smoke10.tga',
			'smoke/smoke11.tga',
		},

		scars = {
			'unknown/scars/scar1.png',
			'unknown/scars/scar2.png',
			'unknown/scars/scar3.png',
			'unknown/scars/scar4.png',
		},

		trees = {
			bark='Bark.bmp',
			leaf='bleaf.bmp',
			gran1='gran.bmp',
			gran2='gran2.bmp',
			birch1='birch1.bmp',
			birch2='birch2.bmp',
			birch3='birch3.bmp',
		},

		maps = {
			detailtex='detailtex2.bmp',
			watertex='ocean.jpg',
		},

		groundfx = {
			groundflash='GPL/groundflash.tga',
			groundring='groundring.tga',
			seismic='GPL/circles.png',
		},

		projectiletextures = {
			----- Weapons ---------------
			--sbtrailtexture         ='smoketrail
			--missiletrailtexture    ='smoketrail
			--muzzleflametexture     ='explo
			--repulsetexture         ='explo
			--dguntexture            ='flare
			--flareprojectiletexture ='flare
			--sbflaretexture         ='flare
			--missileflaretexture    ='flare
			--beamlaserflaretexture  ='flare
			--bubbletexture          ='circularthingy
			--geosquaretexture       ='circularthingy
			--gfxtexture             ='circularthingy
			--projectiletexture      ='circularthingy
			--repulsegfxtexture      ='circularthingy
			--sphereparttexture      ='circularthingy
			--torpedotexture         ='circularthingy
			--wrecktexture           ='circularthingy
			--plasmatexture          ='circularthingy
			gfxtexture='GPL/nano.tga',
			bubbletexture='PD/BubbleAlpha.tga',
			dguntexture='GPL/flash2.tga',
			sphereparttexture='cdet.bmp',
			repulsegfxtexture='cdet.bmp',

			--------- reclaim effect --------
			shard1='unknown/shard1.tga',
			shard2='unknown/shard2.tga',
			shard3='unknown/shard3.tga',
			

			----------Spring Effects--------
			circularthingy='circularthingy.tga',
			laserend='laserend.tga',
			laserfalloff='laserfalloff.tga',
			randdots='randdots.tga',
			smoketrail='PD/smoketrail.tga',
			wake='GPL/wake.png',
			flare='flare.tga',
			flame='GPL/flame.tga',
			explofade='explofade.tga',
			--heatcloud='explo.tga',
			--explo='explo.tga',
			heatcloud='GPL/explo.png',
			explo='GPL/fire.png',


			-----------Saktoths-----------
			spikeexplo='Saktoths/spikeexplo.tga',
			starexplo='Saktoths/starexplo.tga',
			flowexplo='Saktoths/flowexplo.tga',
			cloudexplo='Saktoths/cloudexplo.tga',
			sakexplo='Saktoths/sakexplo.tga',
			fireball2='Saktoths/fireball.tga',
			------------------------------


			smoke04='GPL/smoke04.png',
			orangesmoke3='GPL/smoke_orange.png',
			fire2='GPL/fire.png',
			WhiteLightGPL='GPL/lightw.png',
			kfoam='Other/foam.tga',
			bubble='PD/BubbleAlpha.tga',
			shell='PD/shell.tga',
			plasma2='GPL/plasma.tga',
			plasma3='GPL/plasmashot.png',
			flowerflash='PD/flowerflash.tga',
			plasma='GPL/plasma.tga',
			redexplo='CC/redexplo.tga',
			pinkexplo='CC/pinkexplo.tga',
			brightblueexplo='CC/brightblueexplo.tga',
			blueexplo='CC/blueexplo.tga',
			purpleexplo='CC/purpleexplo.tga',
			pinkexplo='CC/pinkexplo.tga',
			diamondstar='Other/diamondstar.tga',
			exp02_1='GPL/Explosion3/exp02_1.png',
			exp02_2='GPL/Explosion3/exp02_2.png',
			exp02_3='GPL/Explosion3/exp02_3.png',
			smoke='PD/smokesmall.tga',
			orangesmoke2='PD/SmokeOrange.tga',
			kE1_0001='PD/Explosion1/0001.tga',
			kE1_0002='PD/Explosion1/0002.tga',
			kE1_0003='PD/Explosion1/0003.tga',
			kE1_0004='PD/Explosion1/0004.tga',
			kE1_0005='PD/Explosion1/0005.tga',
			kE1_0006='PD/Explosion1/0006.tga',
			kE1_0007='PD/Explosion1/0007.tga',
			kE1_0008='PD/Explosion1/0008.tga',
			kE1_0009='PD/Explosion1/0009.tga',
			kE1_0010='PD/Explosion1/0010.tga',
			kE1_0011='PD/Explosion1/0011.tga',
			kE1_0012='PD/Explosion1/0012.tga',
			kE1_0013='PD/Explosion1/0013.tga',
			kE1_0014='PD/Explosion1/0014.tga',
			kE1_0015='PD/Explosion1/0015.tga',
			kE1_0016='PD/Explosion1/0016.tga',
			kE1_0017='PD/Explosion1/0017.tga',
			kE1_0018='PD/Explosion1/0018.tga',
			kE1_0019='PD/Explosion1/0019.tga',
			kE1_0020='PD/Explosion1/0020.tga',
			kE1_0021='PD/Explosion1/0021.tga',
			smokesmall='PD/smokesmall.tga',
			lightb='PD/lightningball.tga',
			lightring='PD/lightring.tga',
			whitelightb='PD/whitelightningball.tga',
			lightb3='PD/lightningball3.tga',
			lightb4='PD/lightningball4.tga',
			lightning='PD/lightning.tga',
			dust='Other/dust.tga',
			kburst='Other/burst.tga',
			plasma0029='Other/plasma0029.tga',
			orangesmoke='PD/orangesmoke.tga',
			fireball='PD/fireball.tga',
			fireball_green='PD/fireball_crimson.tga',
			fireball_gray='PD/fireball_gray.tga',
			dirtplosion2='PD/dirtplosion2.tga',
			debris2='Other/debris2.tga',
			debris='Other/debris.tga',
			kfoom='Other/Foom.tga',
			exp00_1='GPL/Explosion2/exp00_1.tga',
			exp00_2='GPL/Explosion2/exp00_2.tga',
			exp00_3='GPL/Explosion2/exp00_3.tga',
			exp00_4='GPL/Explosion2/exp00_4.tga',
			exp00_5='GPL/Explosion2/exp00_5.tga',
			exp00_6='GPL/Explosion2/exp00_6.tga',
			exp00_7='GPL/Explosion2/exp00_7.tga',
			exp00_8='GPL/Explosion2/exp00_8.tga',
			exp00_9='GPL/Explosion2/exp00_9.tga',
			exp00_10='GPL/Explosion2/exp00_10.tga',
			largelaser='GPL/largelaserfalloff.png',
			smallflare='GPL/smallflare.tga',
			Light='Other/light.png',
			databeam='GPL/databeam.png',
			corelaser='GPL/corelaser.png',
			sporetrail='GPL/sporetrail.tga',
			sporetrail2='GPL/sporetrail2.tga',
			sporetrailblue='GPL/sporetrailblue.tga',

			-----------Smoth's-----------
			["2explo"]='CC/2explo.tga',
			["3explo"]='CC/3explo.tga',
			["4explo"]='CC/4explo.tga',
			["5explo"]='CC/5explo.tga',
			bluenovaexplo='CC/bluenovaexplo.tga',
			greennovaexplo='CC/greennovaexplo.tga',
			pinknovaexplo='CC/pinknovaexplo.tga',
			firenovaexplo='CC/firenovaexplo.tga',
			uglynovaexplo='CC/uglynovaexplo.tga',
			crimsonnovaexplo='CC/crimsonnovaexplo.tga',
			electnovaexplo='CC/electnovaexplo.png',
			novabg='CC/novabg.tga',
			redexplo='CC/redexplo.tga',
			purpleexplo='CC/purpleexplo.tga',
			blueexplo='CC/blueexplo.tga',
			pinkexplo='CC/pinkexplo.tga',
			brightblueexplo='CC/brightblueexplo.tga',
			bigexplo='CC/bigexplo.tga',
			fireyexplo='CC/fireyexplo.tga',
			bigexplosmoke='CC/bigexplosmoke.tga',
			--explowave='CC/explowave.tga',
			flash1='CC/flash1.tga',
			flash2='CC/flash2.tga',
			flash3='CC/flash3.tga',
			lightening='CC/lightening.tga',
			shotgunflare='CC/shotgunflare.tga',
			flashside1='CC/flashside1.tga',
			flashside2='CC/flashside2.tga',
			shotgunside='CC/shotgunside.tga',
			megaparticle='CC/megaparticle.tga',
			shot='CC/shot.tga',	
			gunshot='CC/gunshot.tga',
			beamrifle='CC/beamrifle.tga',
			beamrifletip='CC/beamrifletip.tga',
			dirt='CC/dirt.png',
			odd='CC/odd.tga',

			--------------NOTA-----------
			otaplas1='Other/ota_plas/boom2.png',
			otaplas2='Other/ota_plas/boom3.png',
			otaplas3='Other/ota_plas/boom4.png',
			otaplas4='Other/ota_plas/boom5.png',
			otaplas5='Other/ota_plas/boom6.png',
			otaplas6='Other/ota_plas/boom7.png',
			otaplas7='Other/ota_plas/boom8.png',
			otaplas8='Other/ota_plas/boom9.png',
			otaplas9='Other/ota_plas/boom10.png',
			otaplas10='Other/ota_plas/boom11.png',
			otaplas11='Other/ota_plas/boom12.png',
			otaplas12='Other/ota_plas/boom13.png',
			otaplas13='Other/ota_plas/boom14.png',
			otaplas14='Other/ota_plas/boom15.png',
			otaplas15='Other/ota_plas/boom16.png',
			otaplas16='Other/ota_plas/boom17.png',
			otaplas17='Other/ota_plas/boom18.png',
			otaplas18='Other/ota_plas/boom19.png',

			------------XTA--------------
			whitelight='Other/lightw.bmp',
			redlight='Other/light_red.png',
			YELLOWBLAST='Other/G_FIRE3.tga',
			YELLOWBLAST1='Other/G_FIRE2.tga',
			YELLOWBLAST2='Other/G_FIRE3.tga',
			YELLOWBLAST3='Other/G_FIRE4.tga',
			splash='PD/dirtplosion2.tga',
			muzzleside='muzzleside.tga',
			muzzlefront='muzzlefront.tga',


			------------Evil4Zerggin
			smoketrailthin='PD/smoketrailthin.tga',
			smoketrailthinner='PD/smoketrailthinner.tga',
			splashside='PD/splashside.tga',
			splashbase='PD/splashbase.tga',


			------------???---------------
			bluering='CC/bluering.tga',
			darksmoketrail='darksmoketrail.tga',
			lightsmoketrail='lightsmoketrail.tga',
			-----------KDRs-----------
			blooddrop='PD/blooddrop.png',
			bloodblast='PD/bloodblast.png',
			bloodsplat='Pd/bloodsplat.tga',
			blooddropwhite='PD/blooddropwhite.tga',
			bloodblastwhite='PD/bloodblastwhite.tga',
			null='PD/null.tga',
			------------------------------
			
			steam='PD/steam.tga',
		},
	},
}

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

return resources

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
