-- $Id$

-- changelog: versus666,	(21oct2010):	corrected the numerous awfull bad spellings in french.

return {
	en = {
		tasks = {
			descs = {
				'Introduction',
				'Restore your interface',
				'Building a Metal Extractor (mex)',
				'Building a Solar Collector',
				'Building a Light Laser Tower (LLT)',
				'Building another mex on a different metal spot.',
				'Building another Solar Collector',
				'Building a Factory',
				'Building a Radar',
				'Building a Constructor',
				'Using a constructor to assist your factory',
				'Building Raider Bots in your factory.',
				'Congratulations!',
			},
			tips = {
				nil,
				nil,
				nil,
				'Energy generating structures power your mexes and factories.',
				nil,
				'Always try to acquire more metal spots to build more mexes.',
				'Always try and build more energy structures to keep your economy growing.',
				nil,
				'Radar coverage shows you distant enemy units as blips.',
				'Just like your Commander, Constructors build (and assist building of) structures.',
				'Factories that are assisted by constructors build faster.',
				'Combat units are used to attack your enemies and make them suffer.',
				nil,
			},
		},
		steps = {
			intro = [[Hello! I am Nubtron, the multilingual friendly robot. I will teach you how to play Zero-K. <(Click next to continue)>]],
			intro2 = [[Just follow my instructions and learn at your own pace. <(Click next to continue)>]],
			intro3 = [[Practice zooming the camera in and out with your mouse's scroll wheel <(Click next to continue)>]],
			intro4 = [[Practice panning the camera by holding down the middle mouse button and dragging. <(Click next to continue)>]],
			intro5 =  [[Place your starting position by clicking on a nice flat spot on the map, then click on the <Ready> button]],
			selectComm = [[Select only your commander by clicking on it or pressing <ctrl+c>.]],
			showMetalMap = [[View the metal map by pressing <F4>.]],
			hideMetalMap = [[Hide the metal map by pressing <F4>.]],
			selectBotLab = [[Select only your Bot Lab by clicking on it (the blue circles will help you find it).]],
			selectCon = [[Select one constructor by clicking on it (the blue circles will help you find it).]],
			guardFac = [[Have the constructor guard your Bot Lab by right clicking on the Lab. The constructor will assist it until you give it a different order.]],
			tutorialEnd = [[This is the end of the tutorial. It is now safe to shut off Nubtron. Goodbye! (Click next to restart tutorial)]],
			
			selectBuild_m = [[Select the #replace# from your build menu (build-icon shown here)]],
			build_m = [[You are now building a #replace#. <Wait for it to finish.>]],
			
			finish = [[You have an unfinished #replace# shown by the red circles. <Right click on it to finish building>. ]],
			selectBuild = [[Select the #replace# from your build menu (build-icon shown here)]],
			start = [[<Place it near your other structures.> It will turn red if you try to place it on uneven terrain.]],
			build = [[Good work! You are now building a #replace#. <Wait for it to finish.>]],
			
			startMex = [[Place it on a green patch.]],
			selectBuildMex = [[The build-icon for the mex is shown to the right. Select it in your build menu on the left under the Econ tab.]],
			startBotLab = [[Before placing it, you can rotate the structure with the <[> and <]> keys. <Turn it and place it so that units can easily exit the front>. It will turn red if you try to place it on uneven terrain.]],
		}
	}, --end en
	--I let this part between quote because I never used a ' in it.
	fr = {
		tasks = {
			descs = { 
				'Introduction',
				'Restaurez votre interface',
				'Construire un extracteur de métal',
				'Construire un collecteur solaire',
				'Constuire une tourelle laser légère LLT',
				'Construire un autre extracteur sur un autre point de minerai',
				'Construire un autre collecteur solaire',
				'Construire une usine',
				'Construire un radar',
				'Construire un constructeur',
				'Utilisez le Constructeur pour assister une usine',
				'Construire des Robots Pilleurs dans une usine',
				'Félicitations!',
			},
			tips = { --made this part between [[]] because I used some ' in it.
				nil,
				nil,
				nil,
				[[Les structures générant de l'énergie font fonctionner vos extracteurs et vos usines]],
				nil,
				[[Essayez d'acquérir toujours plus de point de minerai pour construire plus d'extracteurs.]],
				[[Essayez de construire toujours plus de structures énergétiques pour garder une économie forte.]],
				nil,
				[[La couverture radar vous indiquer les ennemis en tant que points radars.]],
				[[Tout comme votre commandeur, votre constructeur peut construire et assister les constructions.]],
				[[Les usines assistées par des constructeurs construisent plus vite.]],
				[[Les unités de combat sont utilisées pour attaquer et détruire vos ennemis.]],
				nil,
			},
		},
		steps = {
			intro = [[Bonjour! Je suis Nubtron, votre amical compagnon robot multilingue! Je vais vous apprendre à jouer a Zero-K. <(Cliquez ici pour continuer)>]],
			intro2 = [[Vous n'avez qu'à suivre mes instructions. Vous pouvez déplacer cette fenêtre en cliquant autour de ma tête. <(Cliquez ici pour continuer)>]],
			intro3 = [[Entrainez-vous à zoomer avec la camera en utilisant la molette de la souris <(Cliquez ici pour continuer)>]],
			intro4 = [[Vous pouvez déplacer la caméra en utilisant les flèches du clavier, ou en approchant les bords de l'écran avec le curseur. <(Cliquez ici pour continuer)>]],
			intro5 =  [[Choisissez votre position de départ en cliquant sur le sol. Prenons un endroit plat et large pour commencer. Cliquez ensuite sur le bouton <Ready>]],
			selectComm = [[Sélectionnez votre commandeur en cliquant sur lui ou en pressant <ctrl+c>.]],
			showMetalMap = [[Vous pouvez voir la présence de métal sur le sol en pressant <F4>.]],
			hideMetalMap = [[Rappuyez sur <F4> pour cacher l'affichage du metal sur le sol et ainsi revenir à la vue normale.]],
			selectBotLab = [[Selectionnez votre Usine de Robots en cliquant sur elle. (Le cercle bleu vous aidera à la trouver).]], 
			selectCon = [[Selectionnez un constructeur en cliquant sur lui. (Le cercle bleu vous aidera à le trouver).]], 
			guardFac = [[Ordonnez à votre constructeur de garder votre Usine de Robots en cliquant avec le bouton droit dessus. Le constructeur assistera la production de celle-ci jusqu'à ce que vous lui donniez un autre ordre ou que celle-ci finisse sa file de production.]],
			tutorialEnd = [[C'est la fin de ce tutoriel, je n'ai plus rien à vous apprendre. Vous pouvez éteindre Nubtron et reprendre une activité guerrière normale. Merci et au revoir! (Cliquez pour redémarrer le tutoriel)]],
			
			selectBuild_m = [[Selectionnez #replace# depuis le menu de construction (l'icône est montrée ici).]],
			build_m = [[Vous êtes désormais en train de construire un(e) #replace#. <Patientez jusqu'à son achèvement>]],
			
			finish = [[Vous avez un #replace# non terminé, signalé par des cercles rouges. <Cliquez à l'aide du bouton droit pour le finir.>. ]],
			selectBuild = [[Sélectionnez le #replace# depuis votre menu de construction.]];
			start = [[<Placez-le à proximité d'autres structures.> Il deviendra rouge si vous le placez sur un terrain inaproprié, et vous devrez le re-sélectionner.]],
			build = [[ Bon travail! Vous construisez désormais un(e) #replace#. <Attendez qu'il/elle se termine>]],
			
			startMex = [[Placez-le sur une tâche verte représentant un point de minerai.]],
			selectBuildMex = [[L'icône de construction pour l'Extracteur de metal (Mex) est à droite dans le menu de construction qui lui, est à gauche. Vous suivez toujours ?]],
			startBotLab = [[Avant de la placer, vous pouvez tourner une structure avec les touches <)> et <0>.<Tournez-la et placez-la de sorte que les unités puissent sortir en sortir facilement.>. Elle deviendra rouge si vous tentez de la placer sur un terrain inaproprié.]],
		}
	}, --end fr

	fi = {
		tasks = {
			descs = {
				'Perehdytys',
				'Palauta käyttöliittymä',
				'Rakenna metallikaivos (mex)',
				'Rakenna aurinkovoimala',
				'Rakenna kevyt laaseritorni (LLT)',
				'Rakenna toinen metallikaivos toiseen metalliesiintymään',
				'Rakenna toinen aurinkovoimala',
				'Tehtaan rakentaminen',
				'Tutkan rakentaminen',
				'Rakentajayksikön rakentaminen',
				'Käytä rakentaja-yksikköä avustaaksesi tehdastasi',
				'Hyökkääjä-robottien rakentaminen tehtaassasi',
				'Onneksi olkoon!',
			},
			tips = {
				nil,
				nil,
				nil,
				'Energiaa tuottavat rakennukset pitävät tukikohtasi toimintakuntoisena.',
				nil,
				'Koita aina vallata mahdollisimman monta metalliesiintymää pystyäksesi rakentamaan niihin metallikaivoksia.',
				'Koita aina rakentaa lisää energiaa tuottavia yksiköitä varmistaaksesi resurssiesi kasvun varmistumisen.',
				nil,
				'Tutkat varoittavat vihollisten hyökkäyksistä kauan ennenkuin he ovat päässeet tukikohtaasi.',
				'Aivan kuten komentajasi, myös rakentajat pystyvät rakentamaan taloja',
				'Jos rakentaja avustaa tehdasta, valmistuvat yksiköt nopeammin',
				'Taisteluyksikköjä käytetään vihollisten murskaamiseen, joka on ainoa tapa saavuttaa voitto.',
				nil,
			},
		},
		steps = {
			intro = [[Terve! Minä olen Nubtron, ystävällinen robottiapurisi. Minä opetan sinua pelaamaan Zero-K:ia opastetun harjoittelun avulla. <(Paina tästä jatkaaksesi)>]],
			intro2 = [[Seuraa vain ohjeitani. Voit liikutella tätä ikkunaa tarttumalla kuvastani hiiren kursorilla. <(Paina tästä jatkaaksesi)>]],
			intro3 = [[Harjoittele näkymän lähentämistä ja loitontamista käyttämällä hiiren rullaa. <(Paina tästä jatkaaksesi)>]],
			intro4 = [[Harjoittele näkymän vierittämistä ylös, alas, vasemmalle sekä oikealle nuolinäppäimien avulla. <(Paina tästä jatkaaksesi)>]],
			intro5 =  [[Aseta aloituskohtasi klikkaamalla kursorilla pelikenttää. Valitse tasainen kohta ja paina <Ready> nappia kun olet valmis aloittamaan pelin.]],
			selectComm = [[Valitse komentajasi kursorin avulla tai painamalla <ctrl+c>.]],
			showMetalMap = [[Avaa metalliesiintymä-näkymä painamalla <F4>.]],
			hideMetalMap = [[Sulje metalliesiintymä-näkymä painamalla <F4>.]],
			selectBotLab = [[Valitse robottitehtaasi vasenta hiiren painiketta käyttäen. (Siniset ympyrät auttavat sinua löytämään sen).]],
			selectCon = [[Valitse yksi rakentaja kursorin avulla (Siniset ympyrät auttavat sinua löytämään sen).]],
			guardFac = [[Aseta rakentaja vartioimaan robottitehdastasi painamalla oikeaa hiiren painiketta tehtan kohdalla. Rakentaja avustaa nyt tehdasta kunnes annat sille toisen komennon.]],
			tutorialEnd = [[Olet läpäissyt Nubtron-harjoittelun! Voit sulkea nubtronin ja jatkaa pelaamista. (Paina tästä käynnistääksesi harjoittelun uudelleen)]],
			
			selectBuild_m = [[Valitse #replace# valikostasi. (Rakennuskuvake näkyy tässä).]],
			build_m = [[Rakennat: #replace#. <Odota kunnes se on valmis.>]],
			
			finish = [[Sinulla on valmistumaton rakennus: #replace# jota punaiset ympyrät osoittavat. <Paina oikealla hiiren painikkeella rakennuksen yllä jatkaaksesi rakentamista>. ]],
			selectBuild = [[Valitse #replace# valikosta (Rakennuskuvake näkyy tässä). ]],
			start = [[<Aseta se muiden rakennustesi lähettyville.> Rakennuskuvake muuttuu punaiseksi, mikäli yrität antaa komennon maastoon johon kyseistä yksikköä ei pysty rakentamaan.]],
			build = [[Hyvin tehty! Rakennat: #replace#. <Odota kunnes se on valmis.>]],
			
			startMex = [[Aseta se metalliesiintymä-näkymässä näkyvään vihreään kohtaan.]],
			selectBuildMex = [[Oikealla puolella tässä ikkunassa näkyy metallikaivoksen rakennuskuvake. Rakentaaksesi sen, vaitse se vasemmalla olevasta rakennusvalikosta.]],
			startBotLab = [[Ennen rakennuskomennon antamista voit kääntää rakennuksen suuntaa käyttämällä <Å> sekä <´> näppäimiä. <Käännä ja aseta rakennus niin, että yksiköt pääsevät helposti poistumaan rakennuksesta>. Rakennuskuvake muuttuu punaiseksi, mikäli yrität antaa komennon maastoon johon kyseistä yksikköä ei pysty rakentamaan.]],
		}
	}, --end fi

	my = {
		tasks = {
			descs = {
				'Pengenalan',
				'Mengembalikan "interface" anda',
				'Membina sebuah penggali logam (mex)',
				'Membina sebuah Pengumpul Suria ("Solar Collector")',
				'Membina sebuah Menara Laser Ringan ("Light Laser Tower")',
				'Membina sebuah lagi mex di tempat lain.',
				'Membina sebuah lagi Pengumpul Suria',
				'Membina sebuah Kilang',
				'Membina sebuah Radar',
				'Membina sebuah Jurubina',
				'Mengunakan sebuah Jurubina untuk membantu kilang anda',
				'Membina robot serangan ringan di kilang',
				'Tahniah!',
			},
			tips = {
				nil,
				nil,
				nil,
				'Bangunan tenaga membekalkan tenaga kepada unit dan kilang anda.',
				nil,
				'Anda harus sentiasa menguasai lebih banyak pusat logam untuk membina lebih penggali logam.',
				'Wajar anda sentiasa berusaha membina lebih bangunan tenaga bagi mengembankan ekonomi anda.',
				nil,
				'Unit-unit musuh di dalam kawasan radar ditunjukkan sebagai bintik-bintik.',
				'Seperti Komander awak, jurubina menghasilkan (dan membantu membina) bangunan.',
				'Kilang yang dibantu oleh jurubina mengeluarkan unit dengan lebih cepat.',
				'Unit ketenteraan bertujuan menentang dan menghapuskan musuh anda.',
				nil,
			},
		},
		steps = {
			intro = [[Selamat datang! Saya ialah Nubtron, sahabat robot anda yang berbilang bahasa. Saya akan mengajar anda cara bermain Zero-K. <(Klik Next untuk teruskan)>]],
			intro2 = [[Anda hanya perlu menurti arahan saya. Anda boleh mengerakkan kotak di sekelliling mukaku ini. <(Klik Next untuk teruskan)>]],
			intro3 = [[Berlatih menatal kamera dekat dan jauh dengan roda tatal tetikus anda. <(Klik Next untuk teruskan)>]],
			intro4 = [[Berlatih menarik kamera ke atas, bawah, kiri dan kanan dengan kekunci anak panah. <(Klik Next untuk teruskan)>]],
			intro5 =  [[Pilih tempat mula anda dengan mengeklik pada suatu kawasan lapang di peta, kemudian klick butang <Ready> (bersedia).]],
			selectComm = [[Pilih hanya komander awak dengan mengeklik padanya ataupun menekan <ctrl+c>.]],
			showMetalMap = [[Lihat peta logam ("metal map") dengan menekan <F4>.]],
			hideMetalMap = [[Keluar dari peta logam ("metal map") dengan menekan <F4>.]],
			selectBotLab = [[Pilih Kilang Bot anda sahaja dengan mengekliknya (bulatan biru dapat membantu kamu mencarinya).]],
			selectCon = [[Pilih satu pembina dengan mengekliknya (bulatan biru dapat membantu kamu mencarinya).]],
			guardFac = [[Arahkan pembina ini menjaga Kilang Bot anda dengan mengeklik kanan atas Kilang. Pembina berkenaan akan menolong kilang sehingga anda memberinya arahan lain.]],
			tutorialEnd = [[ (Klik di sini untuk mengulangi tutorial)]],
			
			selectBuild_m = [[Pilih #replace#  daripada senarai binaan anda (imej binaan digambarkan di sini).]],
			build_m = [[Anda sedang membina sebuah #replace#. <Tunggu sehingga ia siap.>]],
			
			finish = [[Anda mempunyai sebuah #replace# yang terabai di bulatan merah. <Klik kanan padanya untuk meneruskan kerja>. ]],
			selectBuild = [[Pilih #replace# daripada senarai binaan anda (imej binaan digambarkan di sini). ]],
			start = [[<Letakkannya berhampiran bangunan-bangunan lain anda.> Ia akan menjadi merah jika anda cuba meletakkanya pada tanah yang tidak rata.]],
			build = [[Syabas! Anda kini membina sebuah #replace#. <Tunggu sehingga ia siap.>]],
			
			startMex = [[Letakkannya pada tompok hijau.]],
			selectBuildMex = [[Imej binaan untuk penggali logam (mex) ditunjukkan di kanan. Pilihkannya dari senarai binaan anda di kiri.]],
			startBotLab = [[Sebelum membina sesuatu bangunan, anda boleh menukar arah hadapannya dengan kekunci <[> and <]>. <Pusingkannya supaya unit mudah keluar melalui hadapan kilang>. Ia akan menjadi merah jika anda cuba meletakkanya pada tanah yang tidak rata.]],
		}
	}, --end my

	pl = {
		tasks = {
			descs = {
				'Wprowadzenie',
				'Odnowienei interfejsu',
				[[Zbudowanie kopalni (mex'a)]],
				'Zbudowanie elektrowni slonecznej (Solar Collector)',
				'Zbudowanie lekkiej wiezyczki (LLT)',
				[[Zbudowanie kolejnego mex'a na innej latce metalu.]],
				'Zbudowanie kolejnej elektrowni slonecznej',
				'Zbudowanie fabryki',
				'Zbudowanie radaru',
				'Zbudowanie konstruktora',
				'Uzycie konstruktora do wspomagania fabryki',
				'Budowanie jednostek w fabryce.',
				'Gratulacje!',
			},
			tips = {
				nil,
				nil,
				nil,
				[[Elektrownie dostarczaja prad do mex'ow oraz fabryk.]],
				nil,
				[[Zawsze walcz o dodatkowe latki metalu do budowy kolejnych mex'ow.]],
				[[Zawsze staraj sie budowac wiecej elektrowni dla zasilania ekonomii.]],
				nil,
				'Radar pokazuje odlegle jednostki wroga jako kropki.',
				'Tak jak Commander, konsruktorzy buduja i wspomagaja budowe.',
				'Wspomagane fabryki buduja szybciej.',
				'Jednostki bojowe uzywane sa do atakowania przeciwnika.',
				nil,
			},
		},
		steps = {
			intro = [[Dzien dobry! Jestem Nubtron, wielojezyczny, przyjacielski robot. Naucze cie jak grac w Zero-K. <(Nacisnij tutaj aby kontynuowac)>]],
			intro2 = [[Wykonuj moje instrukcje. Mozesz przesuwac to okienko lapiac za moja twarz. <(Nacisnij tutaj aby kontynuowac)>]],
			intro3 = [[Sprobuj przyblizac i oddalac obraz uzywajac kulki/pokretla myszy. <(Nacisnij tutaj aby kontynuowac)>]],
			intro4 = [[Sprobuj przesuwac obraz uzywajac strzalek. <(Nacisnij tutaj aby kontynuowac)>]],
			intro5 =  [[Wybierz pozycje startowa poprzez klikniecie na plaskim terenie, po czym nacisnik przycisk <Ready>.]],
			selectComm = [[Zaznacz samego Commandera poprzez kombinacje <ctrl+c>.]],
			showMetalMap = [[Pokaz metal-mape, naciskajac <F4>.]],
			hideMetalMap = [[Schowaj metal-mape, naciskajac <F4>.]],
			selectBotLab = [[Zaznacz fabryke robotow poprzez nacisniecie jej (niebieskie kolka pomoga Ci ja znalezc).]],
			selectCon = [[Zaznacz konstruktora klikajac go (niebieskie kolka pomoga Ci go znalezc).]],
			guardFac = [[Kaz konstruktorowi wsomagac fabryke, naciskajac ja prawym przyciskiem myszy lub dajac komende Guard. Bedzie ja wspomagac dopoki nie wydasz innego rozkazu.]],
			tutorialEnd = [[To juz koniec samouczka. Mozesz teraz wylaczyc Nubtrona. Do widzenia! (Nacisnij tutaj aby zrestartowac samouczek)]],
				
			selectBuild_m = [[Zaznacz #replace# z menu budowy (ikonka budowy pokazana tutaj).]],
			build_m = [[Budujesz teraz #replace#. <Poczekaj az skonczy sie budowac.>]],
			
			finish = [[Masz niedokonczona budowe: #replace#, zaznaczona czerwonymi kolkami. <Nacisnij na nia prawym przyciskiem aby ja dokonczyc>. ]],
			selectBuild = [[Zaznacz #replace# z menu budowy (ikonka budowy pokazana tutaj). ]],
			start = [[<Postaw go obok innych budowli.> Bedzie czerwona jesli postawisz ja na nierownym terenie i bedziesz musial ustawiac ja od poczatku.]],
			build = [[Dobra robota! Budujesz wlasnie #replace#. <Poczekaj na zakonczenie budowy.>]],
			
			startMex = [[Postaw go na zielonej latce.]],
			selectBuildMex = [[Ikonka mex'a jest pokazana na prawo. Zaznacz ja w menu po lewej.]],
			startBotLab = [[Zanim ja ulokujesz, mozesz obracac budowe klawiszami <[> oraz <]> . <Obroc ja tak, aby jednostki mogly swobodnei wychodzic>. Bedzie czerwona jesli postawisz ja na nierownym terenie i bedziesz musial ustawiac ja od poczatku.]],
		}
	}, --end pl
	
} -- end text
