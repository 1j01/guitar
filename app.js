
var song = {
	clear: function(){
		this.notes = [];
		//this.tuning = "EBGDAE";
		this.tabs = ["E:","B:","G:","D:","A:","E:"];
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
	
	//find sections of lines prefixed by string names
		//(minimum of one dash in each line)
	var EBGDAE = /E([^\n]*-[^\n]*)\nB([^\n]*-[^\n]*)\nG([^\n]*-[^\n]*)\nD([^\n]*-[^\n]*)\nA([^\n]*-[^\n]*)\nE([^\n]*-[^\n])*/gim;
	str.replace(EBGDAE, function(block){
		console.log("EBGDAE block found:\n",block);
		var lines = block.split("\n");
		for(var i=0;i<lines.length;i++){
			var m = lines[i].match(/^\s*(\w)\s*(.*)$/);
			var stringName = m[1].toUpperCase();
			var someNotes = m[2];
			if(stringName === "E" && i===0){
				stringName = "e";
			}
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
				var someNotes = m[2];
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
	}
	
	//fallback for blocks that have no string names
	if(noteStrings.B.length === 0){
		//(minimum of three dashes in each line)
		var NamelessBlock = /(([^\n]*-[^\n]*-[^\n]*-[^\n]*)\n){5}([^\n]*-[^\n]*-[^\n]*-[^\n]*)*/gim;
		str.replace(NamelessBlock, function(block){
			console.log("block found with no string names:\n",block);
			var lines = block.split("\n");
			for(var i=0;i<lines.length;i++){
				var someNotes = lines[i];
				noteStrings["eBGDAE"[i]] += "+"+someNotes; // STRING the notes together HAHAHAHAHAHAHAHA Uh
			}
			return "{...}";
		});
	}
	
	//@TODO: alert problems with the tabs
	if(noteStrings.B.length === 0){
		console.log("Tabs interpretation failed (no music blocks found?)");
		return "Tabs interpretation failed.";
	}
	
	
	//console.log(noteStrings.e+"\n"+noteStrings.B+"\n"+noteStrings.G+"\n"+noteStrings.D+"\n"+noteStrings.A+"\n"+noteStrings.E);
	
	//@TODO: address ambiguity (-12- = 1,2 or 12)
	var notes = [];
	
	if(false){
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
							s: "eBGDAE".indexOf(s)
						});
					}
				}
			}
			pos++;
		}
	}else{
		//ASSUME --12-- = twelve
		var pos = 0, cont = true;
		while(cont){
			cont = false;
			for(var s in noteStrings){
				var ch = noteStrings[s][pos];
				var ch2 = noteStrings[s][pos+1];
				if(ch){
					cont = true;
					if(ch.match(/\d/)){
						if(ch2 && ch2.match(/\d/)){
							var isProbablyMultiDigit = true;
							for(var _s in noteStrings){
								if(noteStrings[_s][pos+1]//when a note starts on the supposed second "digit"
								&&!noteStrings[s][pos+1]){//it can't be a second digit (or someone's absolutely horrible at writing guitar tabs)
									isProbablyMultiDigit = false;//don't mess up
									break;
								}
							}
							if(isProbablyMultiDigit){
								notes.push({
									f: Number(ch+ch2),
									s: "eBGDAE".indexOf(s)
								});
								pos++;
							}else{
								notes.push({
									f: +(ch),
									s: "eBGDAE".indexOf(s)
								});
							}
						}else{
							notes.push({
								f: +(ch),
								s: "eBGDAE".indexOf(s)
							});
						}
					}
				}
			}
			pos++;
		}
	}
	
	if(notes.length === 0){
		return "No notes?!?!?!?!?!?? >:(";
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
	/** **
	var SlapbackDelay = function(){
		//create the nodes we’ll use
		this.input = actx.createGain();
		var output = actx.createGain();
		var delay = actx.createDelay();
		var feedback = actx.createGain();
		var wetLevel = actx.createGain();
	
		//set some decent values
		delay.delayTime.value = 0.150; //150 ms delay
		feedback.gain.value = 0.25;
		wetLevel.gain.value = 0.15;
	
		//set up the routing
		this.input.connect(delay);
		this.input.connect(output);
		delay.connect(feedback);
		delay.connect(wetLevel);
		feedback.connect(delay);
		wetLevel.connect(output);
	
		this.connect = function(target){
			output.connect(target);
		};
	};
	*/
	
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
		algorithmIndex: 0,       //[0,1,2,3,4,5]
		bypass: 0
	});
	/*var wahwah = new tuna.WahWah({
		automode: true,                //true/false
		baseFrequency: 0.5,            //0 to 1
		excursionOctaves: 5,           //1 to 6
		sweep: 0.2,                    //0 to 1
		resonance: 100,                 //1 to 100
		sensitivity: 0.5,              //-1 to 1
		bypass: 0
	});
	var tremolo = new tuna.Tremolo({
		intensity: 1,    //0 to 1
		rate: 0.01,         //0.001 to 8
		stereoPhase: 50,    //0 to 180
		bypass: 0
	});
	var phaser = new tuna.Phaser({
		rate: 1.2,                     //0.01 to 8 is a decent range, but higher values are possible
		depth: 0.3,                    //0 to 1
		feedback: 0.2,                 //0 to 1+
		stereoPhase: 30,               //0 to 180
		baseModulationFrequency: 700,  //500 to 1500
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
	pre.connect(drive.input);
	//tremolo.connect(phaser.input);
	//phaser.connect(drive.input);
	drive.connect(post);
	post.connect(actx.destination);
	
	var GuitarString = function(notestr){
		this.text = notestr[0];
		var basenoten = getNoteN(notestr);
		var basefreq = getFrequency(basenoten);
		
		var volume = actx.createGain();
		volume.gain.value = 0.0;
		volume.connect(pre);
		
		var osc = actx.createOscillator();
		osc.frequency.value = basefreq;
		/*--------------------*\
		|_Type_|_Waveform______|
		|   0  | Sine wave     |
		|   1  | Square wave   |
		|   2  | Sawtooth wave |
		|   3  | Triangle wave |
		\*--------------------*/
		osc.type = 3;
		/*var curveLength = 100;
		var curve1 = new Float32Array(curveLength);
		var curve2 = new Float32Array(curveLength);
		for (var i = 0; i < curveLength; i++)
			curve1[i] = Math.sin(Math.PI * i / curveLength);
		 
		for (var i = 0; i < curveLength; i++)
			curve2[i] = Math.cos(Math.PI * i / curveLength);
		 
		var waveTable = actx.createWaveTable(curve1, curve2);
		osc.type = 4;
		osc.setWaveTable(waveTable);*/
	
	
		/* connections */
		/*osc.connect(vol);
		vol.connect(slap.input);
		slap.connect(actx.destination);*/
		
		osc.connect(volume);
		osc.start(0);
		
		this.play = function(fret, bend){
			var noten = basenoten + fret;
			osc.frequency.value = getFrequency(noten) + bend;
			volume.gain.value = 1.0;
			return noten;
		};
		this.stop = function(){
			volume.gain.value = 0.0;
		};
		this.step = function(){
			volume.gain.value *= 0.7;
		};
	
	};
	var mouseX = 0;
	var mouseY = 0;
	var mouseDown = false;
	var mouseOpen = false;//override mouseFret to -1 (OPEN)
	var mouseBend = false;
	
	var line = function(x1,y1,x2,y2,ss,w){
		if(w)ctx.strokeStyle = ss;
		if(w)ctx.lineWidth = w;
		ctx.beginPath();
		ctx.moveTo(x1,y1);
		ctx.lineTo(x2,y2);
		ctx.stroke();
	};
	
	var fretboard = {
		x: 60,
		y: 60,
		w: 1552,
		h: 300,
		num_frets: 40,
		scale: 1716,
		strings: [],
		//inlays: [0,0,0,0,1,0,1,0,0,1,0,1,90,0,0,0,0,0,0,0,0,0,0,0,3],//le aucoustic guit'r s'tt'n to m'h left
		inlays: [0,0,1,0,1,0,1,0,1,0,0,2,0,0,1,0,1,0,1,0,1,0,0,2],//most common
		//inlays: [0,0,1,0,1,0,1,0,0,1,0,2,0,0,1,0,1,0,1,0,0,1,0,2],//less common
		draw: function(ctx){
			ctx.save();
			ctx.translate(this.x,this.y);
			var mX = mouseX - this.x;
			var mY = mouseY - this.y;
			
			
			var OSW = this.x;//Open Strings area Width
			
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
			var mouseFret = 0;//= OPEN;
			var mouseFretX = 0;
			var mouseFretW = -OSW*1.8;
			
			var fretXs = [mouseFretX];
			var fretWs = [mouseFretW];
			for(var x=0, xp=0, fret = 1; fret < this.num_frets; fret++){
				x += (this.scale - x) / 17.817;
				var mx = (x+xp)/2;
				
				if(!mouseOpen && mX < x && mX >= xp){
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
					ctx.arc(mx,(i+1/2)/ni*this.h,7,0,Math.PI*2,false);
					ctx.fill();
					//ctx.fillRect(mx, Math.random()*this.h,5,5);
				}
				
				xp = x;
			}
			//draw strings
			var sh = this.h/this.strings.length;
			var mouseString = Math.floor(mY/sh);
			var mouseStringY = (mouseString+1/2) * sh;
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
				
				str.step();
			}
			
			//console.log(mouseOverFB, mouseFret, mouseString);
			if(mouseOverFB && mouseString>=0 && mouseString<this.strings.length){
				if(mouseDown){
					ctx.fillStyle = "rgba(0,255,0,0.5)";
					var noten = this.strings[mouseString].play(
						mouseFret,
						(mouseBend) ? Math.abs(mY-mouseStringY)*3 : 0
					);
					if(!recNote
					|| recNote.f != mouseFret
					|| recNote.s != mouseString){
						recNote = {
							s: mouseString,
							f: mouseFret
						};
						song.notes.push(recNote);
						
						var fretName = String(mouseFret);
						var dashes = ["ERROR ;)","-","--","---","----"][fretName.length];
						for(var s=0; s<song.tabs.length; s++){
							song.tabs[s] += (s===mouseString) ? fretName : dashes;
							song.tabs[s] += "-";
						}
						
						//console.log(song.tabs.join("\n"));
					}
				}else{
					ctx.fillStyle = "rgba(0,255,0,0.2)";
					recNote = null;
				}
				var b = 5;
				ctx.fillRect(mouseFretX+b,mouseStringY-sh/2+b,mouseFretW/*-b*2*/,sh-b-b);
				
			}
			
			//draw recorded notes playing back from keyboard
			for(var i in playingNotes){
				var note = playingNotes[i];
				var b = 5;
				ctx.fillStyle = "rgba(0,255,255,0.2)";
				var y = note.s*sh;
				var sy = (note.s+1/2)*sh;
				ctx.fillRect(fretXs[note.f]+b,y+b,fretWs[note.f]/*-b*2*/,sh-b-b);
			
				line(
					fretXs[note.f],sy,
					this.w,sy,
					"rgba(0,255,255,0.8)",
					(note.s/3+1)*2
				);
			}
			
			ctx.restore();
		}
	};
	
	fretboard.strings.push(new GuitarString("E5"));
	fretboard.strings.push(new GuitarString("B4"));
	fretboard.strings.push(new GuitarString("G4"));
	fretboard.strings.push(new GuitarString("D4"));
	fretboard.strings.push(new GuitarString("A3"));
	fretboard.strings.push(new GuitarString("E3"));
	
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
		//render();
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
				$textarea.val(song.tabs.join("\n")).show();
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
		}else{
			
			if(playingNotes[key])return;//prevent repeat
			var playNote = song.notes[song.pos];
			if(!playNote)return;
			
			playingNotes[key] = playNote;
			song.pos = (song.pos+1) % song.notes.length;
			
			var iid = setInterval(function(){
				fretboard.strings[playNote.s].play(playNote.f,0);
			});
			$$.on("keyup",function(e){
				if(e.keyCode == key){
					delete playingNotes[key];
					clearInterval(iid);
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