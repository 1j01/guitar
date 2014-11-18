
var song = {
	clear: function(){
		this.notes = [];
		//this.tuning = "EBGDAE";
		this.tabs = ["E|","B|","G|","D|","A|","E|"];
		this.pos = 0;
	},
	toJSON: function(){ //not used
		return this.notes; //ever
	}
};
song.clear();
//{notes:[],tabs:["E ","B ","G ","D ","A ","E "],pos:0};

var interpretTabs = function(str){
	
	var noteStrings = {E:"",A:"",D:"",G:"",B:"",e:""};
	var tuning = "eBGDAE";
	
	//find sections of lines prefixed by string names
		//(minimum of one dash in each line)
	var EBGDAE = /E([^\n]*-[^\n]*)\nB([^\n]*-[^\n]*)\nG([^\n]*-[^\n]*)\nD([^\n]*-[^\n]*)\nA([^\n]*-[^\n]*)\nE([^\n]*-[^\n]*)/gim;
	str.replace(EBGDAE, function(block){
		console.log("EBGDAE block found:\n"+block);
		var lines = block.split("\n");
		var ll = lines[0].length;
		for(var i=0;i<lines.length;i++){
			if(ll != lines[i].length){
				
			}
			var m = lines[i].match(/^\s*(\w)\s*(.*)$/);
			var stringName = m[1].toUpperCase();
			var someNotes = m[2].trim();
			if(stringName === "E" && i===0){
				stringName = "e";
			}
			console.log(noteStrings[stringName], someNotes);
			noteStrings[stringName] += someNotes; // STRING the notes together HAHAHAHAHAHAHAHA Uh
		}
		return "{...}";
	});
	//fallback to ....wait won't this play incorrectly anyways? uhhh hmmm
	if(noteStrings.B.length === 0){
		//(minimum of three dashes in each line)
		var AnyBlocks = /((\w)([^\n]*-[^\n]*-[^\n]*-[^\n]*)\n){2,5}(\w)([^\n]*-[^\n]*-[^\n]*-[^\n]*)/gim;
		str.replace(AnyBlocks, function(block){
			console.log("Music block found:\n"+block);
			var lines = block.split("\n");
			for(var i=0;i<lines.length;i++){
				var m = lines[i].match(/^\s*(\w)\s*(.*)$/);
				var stringName = m[1].toUpperCase();
				var someNotes = m[2].trim();
				if(stringName === "E" && i===0){
					stringName = "e";
				}
				if(noteStrings[stringName] !== undefined){
					//noteStrings["eBGDAE".indexOf(stringName)] += someNotes; // STRING the notes together HAHAHAHAHAHAHAHA Uh
					noteStrings[stringName] += someNotes; // STRING the notes together HAHAHAHAHAHAHAHA Uh
				}else{
					console.log("Your guitar is out of tune. #maybe");
					console.debug(AnyBlocks.exec(block));
					return "{...fail...}";
				}
			}
			return "{....}";
		});
		if(noteStrings.B.length > 0){
			alert("Playing blocks of music that don't look like the right tuning. (Alternate tunings aren't supported.)");
		}
	}
	
	//fallback for blocks that have no string names
	if(noteStrings.B.length === 0){
		//(minimum of three dashes in each line)
		var NamelessBlock = /(([^\n]*-[^\n]*-[^\n]*-[^\n]*)\n){5}([^\n]*-[^\n]*-[^\n]*-[^\n]*)*/gim;
		str.replace(NamelessBlock, function(block){
			console.log("block found with no string names:\n"+block);
			var lines = block.split("\n");
			for(var i=0;i<lines.length;i++){
				var someNotes = lines[i].trim();
				noteStrings["eBGDAE"[i]] += "+"+someNotes; // STRING the notes together HAHAHAHAHAHAHAHA Uh
			}
			return "{.....}";
		});
	}
	
	//@TODO: alert (more) problems with the tabs
	if(noteStrings.B.length === 0){
		console.log("Tabs interpretation failed (no music blocks found?)");
		return "Tabs interpretation failed.";
	}
	
	var l = noteStrings.e.length;
	for(var s in noteStrings){
		if(noteStrings[s].length !== l){
			console.log("Tabs interpretation failed due to misalignment.");
			var tt123 = " << (this text must line up)\n";
			return "Tabs interpretation failed due to misalignment:\n\n"
				+noteStrings.e+tt123
				+noteStrings.B+tt123
				+noteStrings.G+tt123
				+noteStrings.D+tt123
				+noteStrings.A+tt123
				+noteStrings.E+tt123
				+"\n\n(Any music blocks found were/are merged together like above.)";
		}
	}
	
	
	//console.log(noteStrings.e+"\n"+noteStrings.B+"\n"+noteStrings.G+"\n"+noteStrings.D+"\n"+noteStrings.A+"\n"+noteStrings.E);
	
	var notes = [];
	
	//address ambiguity (---12--- = 1,2 or 12)
	var certainlySquishy = !!str.match(/[03-9]\d[^\n*]-/);
	if(certainlySquishy){
		//ASSUME --12-- = one two
		var pos = 0, cont = true;
		while(cont){
			cont = false;
			for(var s in noteStrings){
				var ch = noteStrings[s][pos];
				if(ch){
					cont = true;
					if(ch.match(/\d/)){
						notes.push({
							f: +ch,
							s: tuning.indexOf(s)
						});
					}
				}
			}
			pos++;
		}
	}else{
		//ASSUME --12-- = twelve
		//also, group chords[]
		var pos = 0, cont = true;
		while(cont){
			cont = false;
			var chord = [];
			for(var s in noteStrings){
				var ch = noteStrings[s][pos];
				var ch2 = noteStrings[s][pos+1];
				if(ch){
					cont = true;
					if(ch.match(/\d/)){
						if(ch2 && ch2.match(/\d/)){
							var isProbablyMultiDigit = true;
							/*for(var _s in noteStrings){
								if(noteStrings[_s][pos+1]//when a note starts on the supposed second "digit"
								&&!noteStrings[s][pos+1]){//it can't be a second digit (or someone's absolutely horrible at writing guitar tabs)
									isProbablyMultiDigit = false;//don't mess up
									console.log("this is uncommon, however. ", ch,ch2);
									break;
								}
							}*/
							if(isProbablyMultiDigit){
								chord.push({
									f: Number(ch+ch2),
									s: tuning.indexOf(s)
								});
								pos++;
							}else{
								chord.push({
									f: +(ch),
									s: tuning.indexOf(s)
								});
							}
						}else{
							chord.push({
								f: +(ch),
								s: tuning.indexOf(s)
							});
						}
					}
				}
				/*if(note){
					if(note_or_chord){
						if(typeof note_or_chord === "array"){//warning: typeof new Array() === "object"
							node_or_chord.push(note);
						}else{
							node_or_chord
						}
					}else{
						note_or_chord = note;
					}
				}*/
			}
			if(chord.length > 0){
				notes.push(chord);
			}
			pos++;
		}
	}
	
	if(notes.length === 0){
		return "No notes?!?!?!?!?!?? >:(";
	}
	
	for(var s in noteStrings){
		console.log(s,song.tabs.indexOf(s));
		if(~song.tabs.indexOf(s)){
			song.tabs[tuning.indexOf(s)] += noteStrings[s];
		}else{
			console.log("UUHUHHH :/");
		}
	}
	
	return notes;
};


$(function(){
	
	var recNote = null;
	var playingNotes = {};
	
	var $canvas = $("<canvas/>").appendTo("body");
	var canvas = $canvas[0];
	
	var $textarea = $("<textarea/>").appendTo("body").hide();
	
	
	var ctx = canvas.getContext("2d");
	var actx = typeof AudioContext !== "undefined"?
		new AudioContext() : new webkitAudioContext();
	var tuna = new Tuna(actx);
	
	var getFrequency = function(noten){
		return 440 * Math.pow(2, (noten - 49) / 12);
	};
	var getNoteN = function(notestr){
		var notes = ['A', 'A#', 'B', 'C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#'];
		var octave;
	
		if(notestr.length === 3){
			octave = Number(notestr.charAt(2));
		}else{
			octave = Number(notestr.charAt(1));
		}
	
		var noten = notes.indexOf(notestr.slice(0, -1));
	
		if(noten < 3){
			noten += ((octave) * 12) + 1; 
		}else{
			noten += ((octave - 1) * 12) + 1; 
		}
		
		return noten;
	};


	var connect = function(nodes){
		// <= length - 2!?
		for(var i=0; i<=nodes.length-2; i++){
			var n1 = nodes[i], n2 = nodes[i+1];
			n1.connect(n2.input || n2.destination || n2);
		}
	};

	/////////////////////////
	
	var pre = actx.createGain();
	pre.gain.value = 0.2;//guitar volume
	var post = actx.createGain();
	post.gain.value = 0.3;//master volume
	
	//var slap = new SlapbackDelay();
	
	var drive = new tuna.Overdrive({
		outputGain: 0.5,         //0 to 1+
		drive: 0.7,              //0 to 1
		curveAmount: 1,          //0 to 1
		algorithmIndex: 0,       //0 to 5, selects one of our drive algorithms
		bypass: 0
	});
	var wahwah = new tuna.WahWah({
		automode: false,                //true/false
		baseFrequency: 0.5,            //0 to 1
		excursionOctaves: 1,           //1 to 6
		sweep: 0.2,                    //0 to 1
		resonance: 2,                //1 to 100
		sensitivity: 0.3,              //-1 to 1
		bypass: 0
	});
	var phaser = new tuna.Phaser({
		rate: 1.2,                     //0.01 to 8 is a decent range, but higher values are possible
		depth: 0.3,                    //0 to 1
		feedback: 0.9,                 //0 to 1+
		stereoPhase: 30,               //0 to 180
		baseModulationFrequency: 700,  //500 to 1500
		bypass: 0
	});
	var chorus = new tuna.Chorus({
		rate: 1.5,         //0.01 to 8+
		feedback: 0.2,     //0 to 1+
		delay: 0.0045,     //0 to 1
		bypass: 0
	});
	/*var tremolo = new tuna.Tremolo({
		intensity: 1,    //0 to 1
		rate: 0.01,         //0.001 to 8
		stereoPhase: 50,    //0 to 180
		bypass: 0
	});
	/*var convolver = new tuna.Convolver({
		highCut: 22050,                         //20 to 22050
		lowCut: 20,                             //20 to 22050
		dryLevel: 1,                            //0 to 1+
		wetLevel: 1,                            //0 to 1+
		level: 1,                               //0 to 1+, adjusts total output of both wet and dry
		impulse: "impulses/impulse_guitar.wav",    //the path to your impulse response
		bypass: 0
	});*/

	/*var noiseConvolver = (function(){
		var convolver = actx.createConvolver(),
		noiseBuffer = actx.createBuffer(2, 0.5 * actx.sampleRate, actx.sampleRate),
		left = noiseBuffer.getChannelData(0),
		right = noiseBuffer.getChannelData(1);
		for(var i = 0; i < noiseBuffer.length; i++){
			left[i] = Math.random() * 2 - 1;
			right[i] = Math.random() * 2 - 1;
		}
		convolver.buffer = noiseBuffer;
		return convolver;
	})();*/
	
	//connect([ pre, wahwah, phaser, drive, chorus, post ]);
	connect([ pre, wahwah, chorus, post ]);
	
	var splitter = actx.createChannelSplitter(2)
	var merger = actx.createChannelMerger(2);
	post.connect(splitter);
	splitter.connect(merger);
	merger.connect(actx.destination);
	//var merger = actx.createChannelMerger(2);
	//post.connect(merger, 0, 0);
	//post.connect(merger, 0, 1);
	//merger.connect(actx.destination);
	
	var pow = Math.pow, sin = Math.sin, cos = Math.cos, tau=2*Math.PI; Math.PI="useless";
	var sustain = false;
	var GuitarString = function(notestr){
		this.text = notestr[0];
		var basenoten = getNoteN(notestr);
		var basefreq = getFrequency(basenoten);
		
		var volume = actx.createGain();
		volume.gain.value = 0.0;
		volume.connect(pre);
		
		var osc = actx.createOscillator();
		osc.frequency.value = basefreq;
		osc.type = "custom"; // sine, square, sawtooth, triangle, custom
		
		// ignore the above, use a custom wavetable instead
		var curveLength = 10;
		var curve1 = new Float32Array(curveLength);
		var curve2 = new Float32Array(curveLength);
		var f = 1;//"frequency" ...
		for(var i = 0; i < curveLength; i++){
			curve2[i] = Math.cos(Math.PI * i / curveLength/20);
			curve1[i] = Math.sin(Math.PI * i / curveLength/20);
			//var t = i/10;
			//curve1[i] = pow(sin( 1.26*f/2 * tau*t ),15)*pow((1-t),3) * pow(sin( 1.26*f/10 * tau*t ),3)*10;
			//curve1[i] = pow(sin( 1.26*f/2 * tau*t ),15)*pow((1-t),3) * pow(sin( 1.26*f/10 * tau*t ),3)*10;
		}
		
		//var waveTable = actx.createWaveTable(curve1, curve2);
		//osc.setWaveTable(waveTable);
		var waveTable = actx.createPeriodicWave(curve1, curve2);
		osc.setPeriodicWave(waveTable);
		
		osc.connect(volume);
		osc.start(0);
		
		var attack = 0.0;//this attack doesn't work, just makes it slow. @TODO
		this.freq = basefreq;
		this.fret = 0;
		this.play = function(fret){
			var noten = basenoten + (this.fret = fret);
			var now = actx.currentTime;
			this.freq = getFrequency(noten);
			osc.frequency.exponentialRampToValueAtTime(this.freq, now+0.001);
			volume.gain.cancelScheduledValues(now);
			volume.gain.linearRampToValueAtTime(1.50,now+attack);
			volume.gain.exponentialRampToValueAtTime(0.50,now+attack+0.29);
			//volume.gain.linearRampToValueAtTime(0.004,now+attack+1.00);
			volume.gain.linearRampToValueAtTime(0.00,now+attack+4.00);
			return noten;
		};
		this.bend = function(bend){
			var noten = basenoten + this.fret;
			var now = actx.currentTime;
			this.freq = getFrequency(noten) + bend;
			osc.frequency.linearRampToValueAtTime(this.freq, now);
			return noten;
		};
		this.release = function(){
			var now = actx.currentTime;
			volume.gain.cancelScheduledValues(now);
			volume.gain.linearRampToValueAtTime(0.0,now+0.33+(sustain*1));
		};
		this.stop = function(){
			var now = actx.currentTime;
			volume.gain.cancelScheduledValues(now);
			volume.gain.linearRampToValueAtTime(0.0,now+0.5);
			osc.frequency.linearRampToValueAtTime(this.freq/50, now+0.4);
		};
	};
	
	//Open Strings area Width (left of the fretboard)
	var OSW = 60;
	
	var mouseX = 0;
	var mouseY = 0;
	var mouseDown = false;
	var mouseOpen = false;//override mouseFret to -1 (OPEN)
	var mouseBend = false;
	
	var mouseFret = 0;// 0 = open string
	var mouseFretX = 0;
	var mouseFretW = -OSW*1.8;
	var mouseString = 0;
	var mouseStringY = 0;
	
	var line = function(x1,y1,x2,y2,ss,w){
		if(w)ctx.strokeStyle = ss;
		if(w)ctx.lineWidth = w;
		ctx.beginPath();
		ctx.moveTo(x1,y1);
		ctx.lineTo(x2,y2);
		ctx.stroke();
	};
	
	var fretboard = {
		x: OSW,
		y: 60,
		w: 1552,
		h: 300,
		num_frets: 40,
		scale: 1716,
		strings: [],
		//inlays: [0,0,0,0,1,0,1,0,0,1,0,1,190,0,0,0,0,0,0,0,0,0,0,0,3],//<--
		inlays: [0,0,1,0,1,0,1,0,1,0,0,2,0,0,1,0,1,0,1,0,1,0,0,2],//most common
		//inlays: [0,0,1,0,1,0,1,0,0,1,0,2,0,0,1,0,1,0,1,0,0,1,0,2],//less common
		draw: function(ctx){
			ctx.save();
			ctx.translate(this.x,this.y);
			var mX = mouseX - this.x;
			var mY = mouseY - this.y;
			
			if(!mouseBend){
				mouseFret = 0;//= OPEN;
				mouseFretX = 0;
				mouseFretW = -OSW*1.8;
			}
			
			//draw board
			ctx.fillStyle = "#FFF7B2";
			ctx.fillRect(0,this.h*0.1,this.w,this.h);
			ctx.fillStyle = "#F3E08C";
			ctx.fillRect(0,0,this.w,this.h);
			
			//check if mouse is over the fretboard (or Open Strings area)
			ctx.beginPath();
			ctx.rect(-OSW,0,this.w+OSW,this.h);
			var mouseOverFB = ctx.isPointInPath(mouseX, mouseY);
			
			//draw frets
			
			var fretXs = [mouseFretX];
			var fretWs = [mouseFretW];
			for(var x=0, xp=0, fret = 1; fret < this.num_frets; fret++){
				x += (this.scale - x) / 17.817;
				var mx = (x+xp)/2;
				
				if(!mouseBend && !mouseOpen && mX < x && mX >= xp){
					mouseFret = fret;
					mouseFretX = x;
					mouseFretW = xp-x;
				}
				
				fretXs[fret] = x;
				fretWs[fret] = xp-x;
				
				line(x,0,x,this.h,"#444",2);
				
				ctx.fillStyle = "#FFF";
				for(var i=0, ni=this.inlays[fret-1]; i<ni; i++){
					//i for inlay of course
					ctx.beginPath();
					ctx.arc(mx,(i+1/2)/ni*this.h,7,0,tau,false);
					ctx.fill();
					//ctx.fillRect(mx, Math.random()*this.h,5,5);
				}
				
				xp = x;
			}
			//draw strings
			var sh = this.h/this.strings.length;
			if(!mouseBend){//(don't switch strings while bending)
				mouseString = Math.floor(mY/sh);
				mouseStringY = (mouseString+1/2) * sh;
			}
			for(var s=0;s<this.strings.length;s++){
				var str = this.strings[s];
				var sy = (s+1/2)*sh;
	
				if(mouseOverFB && s==mouseString){
					if(mouseDown && mouseBend){
						line(0,sy,mouseFretX,mY,"#555",s/3+1);
						line(mouseFretX,mY,this.w,sy,"rgba(150,255,0,0.8)",(s/3+1)*2);
					}else{
						line(0,sy,mouseFretX,sy,"#555",s/3+1);
						line(mouseFretX,sy,this.w,sy,"rgba(150,255,0,0.8)",(s/3+1)*2);
					}
				}else{
					line(0,sy,this.w,sy,"#555",s/3+1);
				}
				
				ctx.font = "25px Helvetica";
				ctx.textAlign = "center";
				ctx.textBaseline = "middle";
				ctx.fillStyle = "#000";
				ctx.fillText(str.text,-OSW/2,sy);
				
			}
			
			//console.log(mouseOverFB, mouseFret, mouseString);
			if(mouseOverFB && mouseString>=0 && mouseString<this.strings.length){
				if(mouseDown){
					ctx.fillStyle = "rgba(0,255,0,0.5)";
					if(!recNote
					|| recNote.f != mouseFret
					|| recNote.s != mouseString){
						recNote = {
							s: mouseString,
							f: mouseFret
						};
						song.notes.push(recNote);
						
						var fretName = ""+mouseFret;
						var dashes = ["ERROR ;)","-","--","---","----"][fretName.length];
						for(var s=0; s<song.tabs.length; s++){
							song.tabs[s] += (s===mouseString) ? fretName : dashes;
							song.tabs[s] += "-";
						}
						
						this.strings[mouseString].play(mouseFret);
						
						//console.log(song.tabs.join("\n"));
					}else if(mouseBend){
						this.strings[mouseString].bend(Math.abs(mY-mouseStringY));
					}
				}else{
					ctx.fillStyle = "rgba(0,255,0,0.2)";
					recNote = null;
				}
				var b = 5;
				ctx.fillRect(mouseFretX+b,mouseStringY-sh/2+b,mouseFretW/*-b*2*/,sh-b-b);
				
			}
			
			//draw recorded notes playing back from keyboard
			for(var key in playingNotes){
				var chord = playingNotes[key];
				for(var i in chord){
					var note = chord[i];
					var b = 5;
					var y = note.s*sh;
					var sy = (note.s+1/2)*sh;
					
					ctx.fillStyle = "rgba(0,255,255,0.2)";
					ctx.fillRect(fretXs[note.f]+b,y+b,fretWs[note.f]/*-b*2*/,sh-b-b);
				
					line(
						fretXs[note.f],sy,
						this.w,sy,
						"rgba(0,255,255,0.8)",
						(note.s/3+1)*2
					);
				}
			}
			
			ctx.restore();
		}
	};
	
	fretboard.strings.push(new GuitarString("E4"));
	fretboard.strings.push(new GuitarString("B3"));
	fretboard.strings.push(new GuitarString("G3"));
	fretboard.strings.push(new GuitarString("D3"));
	fretboard.strings.push(new GuitarString("A2"));
	fretboard.strings.push(new GuitarString("E2"));
	
	/*for(var s=0;s<fretboard.strings.length;s++){
		song.tabs.push(..);
	}*/
	
	var render = function(){
		ctx.clearRect(0,0,canvas.width,canvas.height);
		fretboard.draw(ctx);
	};
	var animate = function(){requestAnimationFrame(animate);render();};animate();
	
	
	////////////////////////////////////////////
	

	var $$ = $(window);

	$$.on("mousemove", function(e){
		mouseX = e.offsetX;
		mouseY = e.offsetY;
	});
	$canvas.on("mousedown", function(e){
		if(e.button === 0){
			mouseOpen = true;
		}
		if(e.button === 1){
			mouseBend = true;
		}
		mouseDown = true;
	});
	$$.on("mouseup", function(e){
		mouseDown = false;
		mouseOpen = false;
		mouseBend = false;
		//stop strings' rings
		for(var s=0;s<fretboard.strings.length;s++){
			fretboard.strings[s].release();
		}
		if(e.keyCode === 32){//Spacebar
			sustain = false;
		}
	});
	$$.on("contextmenu", function(e){
		e.preventDefault();
		return false;
	});

	$$.on("keydown", function(e){
		var key = e.keyCode;
		
		if(e.ctrlKey || e.shiftKey || e.altKey || key > 100){
			return;
		}
		
		console.log(key);
		if(key === 27){//Escape
			if($textarea.is(":hidden")){
				$textarea.val(song.tabs.join("\n")).show().select();
			}else{
				if($textarea.value !== song.tabs.join("\n")){
					if($textarea.val().match(/\[!\]/)){
						$textarea.hide();
					}else{
						var res = interpretTabs($textarea.val());
						if(typeof res == "string"){
							$textarea.val("[!] "+res).select();
						}else{
							song.clear();
							song.notes = res;
							$textarea.hide();
						}
					}
				}else{
					$textarea.hide();
				}
				window.getSelection().removeAllRanges();
			}
		}else if(key === 36){//Home
			song.pos = 0;
		}else if(key === 32){//Spacebar
			sustain = true;
		}else{
			
			if(playingNotes[key])return;//prevent repeat
			var play = song.notes[song.pos];
			if(!play)return;
			
			var chord = play.length ? play : [play];
			
			playingNotes[key] = chord;
			song.pos = (song.pos+1) % song.notes.length;
			
			var PLAYING_ID = Math.random();
			for(var i=0;i<chord.length;i++){
				var str = fretboard.strings[chord[i].s];
				str.PLAYING_ID = PLAYING_ID;
				str.play(chord[i].f);
			}
			
			$$.on("keyup",function(e){
				if(e.keyCode == key){
					for(var i=0;i<chord.length;i++){
						var str = fretboard.strings[chord[i].s];
						if(str.PLAYING_ID == PLAYING_ID){
							str.release();
						}
					}
					delete playingNotes[key];
				}
			});
			
		}
	});
	$$.on("blur", function(){
		for(var s=0; s<fretboard.strings.length; s++){
			fretboard.strings[s].stop();
		}
	});
	
	var resize = function(){
		canvas.width = innerWidth;
		canvas.height = innerHeight;
	};
	$$.on("resize", resize);
	resize();

});