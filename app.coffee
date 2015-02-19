
{abs, sin, cos} = Math
tau = 2*Math.PI

song =
	clear: ->
		@notes = []
		# @tuning = "EBGDAE"
		@tabs = ["E|","B|","G|","D|","A|","E|"]
		@pos = 0
	
	toJSON: -> @notes # not used ever
	toString: -> song.tabs.join("\n")

song.clear()

interpretTabs = (str)->
	
	noteStrings = {E:"",A:"",D:"",G:"",B:"",e:""}
	tuning = "eBGDAE"
	
	# @TODO: avoid using regular expressions as they can't hardly be optimized
	# and they can crash on some inputs (@FIXME)
	# (This code could also be DRYed quite a bid)
	
	# find sections of lines prefixed by string names
		# (minimum of one dash in each line)
	EBGDAE = ///
		E([^\n]*-[^\n]*)\n
		B([^\n]*-[^\n]*)\n
		G([^\n]*-[^\n]*)\n
		D([^\n]*-[^\n]*)\n
		A([^\n]*-[^\n]*)\n
		E([^\n]*-[^\n]*)
	///gim
	str.replace EBGDAE, (block)->
		console.log "EBGDAE block found:\n#{block}"
		lines = block.split("\n")
		for line, i in lines
			# if line.length != lines[0].length
				# @TODO
			
			m = line.match(/^\s*(\w)\s*(.*)$/)
			stringName = m[1].toUpperCase()
			someNotes = m[2].trim()
			
			if stringName is "E" and i is 0
				stringName = "e"
			
			console.log noteStrings[stringName], someNotes
			noteStrings[stringName] += someNotes # STRING the notes together HAHAHAHAHAHAHAHA um
		
		"{...}"
	
	# fallback to ....wait won't @ play incorrectly anyways? uhhh hmmm
	if noteStrings.B.length is 0
		# (minimum of three dashes in each line)
		AnyBlocks = ///
			((\w)([^\n]*-[^\n]*-[^\n]*-[^\n]*)\n){2,5}
			(\w)([^\n]*-[^\n]*-[^\n]*-[^\n]*)
		///gim
		str.replace AnyBlocks, (block)->
			console.log "Music block found:\n#{block}"
			lines = block.split("\n")
			for line, i in lines
				m = line.match(/^\s*(\w)\s*(.*)$/)
				stringName = m[1].toUpperCase()
				someNotes = m[2].trim()
				
				if stringName is "E" and i is 0
					stringName = "e"
				
				if noteStrings[stringName]?
					# noteStrings["eBGDAE".indexOf(stringName)] += someNotes # STRING the notes together HAHAHAHAHAHAHAHA um
					noteStrings[stringName] += someNotes # STRING the notes together HAHAHAHAHAHAHAHA um
				else
					console.log("Your guitar is out of tune. #maybe")
					console.debug(AnyBlocks.exec(block))
					return "{...fail...}"
			
			"{....}"
		
		if noteStrings.B.length > 0
			alert("Playing blocks of music that don't look like the right tuning. (Alternate tunings aren't supported.)")
	
	
	# fallback for blocks that have no string names
	if noteStrings.B.length is 0
		# (minimum of three dashes in each line)
		NamelessBlock = ///
			(([^\n]*-[^\n]*-[^\n]*-[^\n]*)\n){5}
			([^\n]*-[^\n]*-[^\n]*-[^\n]*)*
		///gim
		str.replace NamelessBlock, (block)->
			console.log("block found with no string names:\n"+block)
			lines = block.split("\n")
			for line, i in lines
				someNotes = line.trim()
				noteStrings["eBGDAE"[i]] += "+" + someNotes # STRING the notes together HAHAHAHAHAHAHAHA um
			
			"{.....}"
	
	# @TODO: alert (more) problems with the tabs
	if noteStrings.B.length is 0
		console.log("Tabs interpretation failed (no music blocks found?)")
		return "Tabs interpretation failed."
	
	for s, noteString of noteStrings
		if noteString.length isnt noteStrings.e.length
			console.log "Tabs interpretation failed due to misalignment."
			alignment_marker = "<< (@ text must line up)"
			return """
					Tabs interpretation failed due to misalignment:
					
					
					#{noteStrings.e} #{alignment_marker}
					#{noteStrings.B} #{alignment_marker}
					#{noteStrings.G} #{alignment_marker}
					#{noteStrings.D} #{alignment_marker}
					#{noteStrings.A} #{alignment_marker}
					#{noteStrings.E} #{alignment_marker}
					
					
					(Any music blocks found were merged together above.)
				"""
				# @TODO: show individual blocks that were uneven instead of the entire concatenated block
	
	notes = []
	
	# address ambiguity (---12--- = 1,2 or 12)
	certainlySquishy = not not str.match /[03-9]\d[^\n*]-/
	if certainlySquishy
		# ASSUME --12-- = one two
		pos = 0
		cont = yes
		while cont
			cont = no
			for s, noteString of noteStrings
				ch = noteString[pos]
				if ch
					cont = true
					if ch.match /\d/
						notes.push
							f: +ch
							s: tuning.indexOf(s)
						
			pos++
	
	else
		# ASSUME --12-- = twelve
		# also, group chords[]
		pos = 0
		cont = yes
		while cont
			cont = no
			chord = []
			for s, noteString of noteStrings
				ch = noteString[pos]
				ch2 = noteString[pos+1]
				if ch
					cont = yes
					if ch.match /\d/
						if ch2?.match /\d/
							isProbablyMultiDigit = yes
							### old js
							for _s, _noteString of noteStrings
								if (_noteString[pos+1] and # when a note starts on the supposed second "digit"
								not noteString[pos+1]) # it can't be a second digit (or someone's absolutely horrible at writing guitar tabs)
									# wait, this just checks if there's a digit in another row
									# this wouldn't work would it
									isProbablyMultiDigit = no # don't mess up
									console.log("@ is uncommon, however. ", ch,ch2)
									break
							###
							if isProbablyMultiDigit
								chord.push
									f: parseInt(ch+ch2)
									s: tuning.indexOf(s)
								
								pos++
							else
								chord.push
									f: parseInt(ch)
									s: tuning.indexOf(s)
							
						else
							chord.push
								f: parseInt(ch)
								s: tuning.indexOf(s)
				
				### old js
				if note
					if note_or_chord
						if typeof note_or_chord === "array" # warning: typeof new Array() === "object"
							node_or_chord.push(note)
						else
							node_or_chord
					else
						note_or_chord = note
				###
			
			if chord.length > 0
				notes.push(chord)
			
			pos++
	
	
	if notes.length is 0
		return "No notes?!?!?!?!?!?? >:("
	
	for s, noteString of noteStrings
		console.log s, song.tabs.indexOf(s)
		if song.tabs.indexOf(s) >= 0
			song.tabs[tuning.indexOf(s)] += noteStrings[s]
		else
			console.log "UUHUHHH :/"
	
	return notes



$ ->
	
	recNote = null
	playingNotes = {}
	
	$canvas = $("<canvas tabindex=0/>").appendTo("body")
	canvas = $canvas[0]
	
	$textarea = $("<textarea tabindex=1 autofocus/>").appendTo("body")
	
	
	ctx = canvas.getContext("2d")
	actx = if AudioContext? then new AudioContext else new webkitAudioContext
	tuna = new Tuna(actx)
	
	getFrequency = (noten)->
		440 * (2 ** ((noten - 49) / 12))
	
	getNoteN = (notestr)->
		notes = ['A', 'A#', 'B', 'C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#']
		octave = Number(notestr.charAt(if notestr.length is 3 then 2 else 1))
		noten = notes.indexOf(notestr.slice(0, -1))
		if noten < 3
			noten += ((octave) * 12) + 1 
		else
			noten += ((octave - 1) * 12) + 1 
		noten


	connect = (nodes...)->
		# <= length - 2!?
		i=0
		while i <= nodes.length-2
			n1 = nodes[i]
			n2 = nodes[i+1]
			n1.connect n2.input ? n2.destination ? n2
			i++
	
	# # # # # # # # # # # #
	
	pre = actx.createGain()
	pre.gain.value = 0.2# guitar volume
	post = actx.createGain()
	post.gain.value = 0.3# master volume
	
	# slap = new SlapbackDelay()
	
	drive = new tuna.Overdrive
		outputGain: 0.5          # 0 to 1+
		drive: 0.7               # 0 to 1
		curveAmount: 1           # 0 to 1
		algorithmIndex: 0        # 0 to 5, selects one of the drive algorithms
		bypass: 0
	
	wahwah = new tuna.WahWah
		automode: off                # on/off
		baseFrequency: 0.5           # 0 to 1
		excursionOctaves: 1          # 1 to 6
		sweep: 0.2                   # 0 to 1
		resonance: 2                 # 1 to 100
		sensitivity: 0.3             # -1 to 1
		bypass: 0
	
	phaser = new tuna.Phaser
		rate: 1.2                      # 0.01 to 8 is a decent range, but higher values are possible
		depth: 0.3                     # 0 to 1
		feedback: 0.9                  # 0 to 1+
		stereoPhase: 30                # 0 to 180
		baseModulationFrequency: 700   # 500 to 1500
		bypass: 0
	
	chorus = new tuna.Chorus
		rate: 1.5          # 0.01 to 8+
		feedback: 0.2      # 0 to 1+
		delay: 0.0045      # 0 to 1
		bypass: 0
	
	###
	tremolo = new tuna.Tremolo
		intensity: 1        # 0 to 1
		rate: 0.01          # 0.001 to 8
		stereoPhase: 50     # 0 to 180
		bypass: 0
	
	###
	###
	convolver = new tuna.Convolver
		highCut: 22050                          # 20 to 22050
		lowCut: 20                              # 20 to 22050
		dryLevel: 1                             # 0 to 1+
		wetLevel: 1                             # 0 to 1+
		level: 1                                # 0 to 1+, adjusts total output of both wet and dry
		impulse: "impulses/impulse_guitar.wav"     # the path to your impulse response
		bypass: 0
	
	###

	###
	noiseConvolver = do ->
		convolver = actx.createConvolver()
		noiseBuffer = actx.createBuffer(2, 0.5 * actx.sampleRate, actx.sampleRate)
		left = noiseBuffer.getChannelData(0)
		right = noiseBuffer.getChannelData(1)
		for i in [0..noiseBuffer.length]
			left[i] = Math.random() * 2 - 1
			right[i] = Math.random() * 2 - 1
		
		convolver.buffer = noiseBuffer
		convolver
	###
	
	# connect pre, wahwah, phaser, drive, chorus, post
	connect pre, wahwah, chorus, post
	
	splitter = actx.createChannelSplitter(2)
	merger = actx.createChannelMerger(2)
	post.connect(splitter)
	splitter.connect(merger)
	merger.connect(actx.destination)
	# merger = actx.createChannelMerger(2)
	# post.connect(merger, 0, 0)
	# post.connect(merger, 0, 1)
	# merger.connect(actx.destination)
	
	sustain = off
	class GuitarString
		constructor: (@notestr)->
			@text = @notestr[0]
			@basenoten = getNoteN(@notestr)
			@basefreq = getFrequency(@basenoten)
			
			@volume = actx.createGain()
			@volume.gain.value = 0.0
			@volume.connect(pre)
			
			@osc = actx.createOscillator()
			@osc.frequency.value = @basefreq
			@osc.type = "custom" # sine, square, sawtooth, triangle, custom
			
			# ignore the above osc.type, use a custom wavetable instead
			curveLength = 10
			curve1 = new Float32Array(curveLength)
			curve2 = new Float32Array(curveLength)
			f = 1 # "frequency" ...
			for i in [0..curveLength]
				curve2[i] = cos(tau / 2 * i / curveLength/20)
				curve1[i] = sin(tau / 2 * i / curveLength/20)
				# t = i/10
				# curve1[i] = (sin( 1.26*f/2 * tau*t ) ** 15) * ((1-t) ** 3) * (sin( 1.26*f/10 * tau*t ) ** 3) * 10
				# curve1[i] = (sin( 1.26*f/2 * tau*t ) ** 15) * ((1-t) ** 3) * (sin( 1.26*f/10 * tau*t ) ** 3) * 10
			
			# waveTable = actx.createWaveTable(curve1, curve2)
			# osc.setWaveTable(waveTable)
			waveTable = actx.createPeriodicWave(curve1, curve2)
			@osc.setPeriodicWave(waveTable)
			
			@osc.connect(@volume)
			@osc.start(0)
			
			@attack = 0.0 # this attack doesn't work, just makes it slow. @TODO
			@freq = @basefreq
			@fret = 0
		
		play: (@fret)->
			noten = @basenoten + @fret
			now = actx.currentTime
			@freq = getFrequency(noten)
			@osc.frequency.exponentialRampToValueAtTime(@freq, now+0.001)
			@volume.gain.cancelScheduledValues(now)
			@volume.gain.linearRampToValueAtTime(1.50,now+@attack)
			@volume.gain.exponentialRampToValueAtTime(0.50,now+@attack+0.29)
			# @volume.gain.linearRampToValueAtTime(0.004,now+@attack+1.00)
			@volume.gain.linearRampToValueAtTime(0.00,now+@attack+4.00)
			noten
		
		bend: (bend)->
			noten = @basenoten + @fret
			now = actx.currentTime
			@freq = getFrequency(noten) + bend
			@osc.frequency.linearRampToValueAtTime(@freq, now)
			noten
		
		release: ->
			now = actx.currentTime
			@volume.gain.cancelScheduledValues(now)
			@volume.gain.linearRampToValueAtTime(0.0,now+0.33+(sustain*1))
		
		stop: ->
			now = actx.currentTime
			@volume.gain.cancelScheduledValues(now)
			@volume.gain.linearRampToValueAtTime(0.0,now+0.5)
			@osc.frequency.linearRampToValueAtTime(@freq/50, now+0.4)
	
	
	# Open Strings area Width (left of the fretboard)
	OSW = 60
	
	mouseX = 0
	mouseY = 0
	mouseDown = off
	mouseOpen = off # override mouseFret to be open
	mouseBend = off
	
	mouseFret = 0 # 0 = open string
	mouseFretX = 0
	mouseFretW = -OSW*1.8
	mouseString = 0
	mouseStringY = 0
	
	line = (x1,y1,x2,y2,ss,lw)->
		ctx.strokeStyle = ss if ss?
		ctx.lineWidth = lw if lw?
		ctx.beginPath()
		ctx.moveTo(x1,y1)
		ctx.lineTo(x2,y2)
		ctx.stroke()
	
	window.fretboard =
	fretboard =
		x: OSW
		y: 60
		w: 31337
		h: 300
		num_frets: 40
		scale: 1716
		strings: []
		# inlays: [0,0,0,0,1,0,1,0,0,1,0,1,190,0,0,0,0,0,0,0,0,0,0,0,3] # <--
		inlays: [0,0,1,0,1,0,1,0,1,0,0,2,0,0,1,0,1,0,1,0,1,0,0,2] # most common
		# inlays: [0,0,1,0,1,0,1,0,0,1,0,2,0,0,1,0,1,0,1,0,0,1,0,2] # less common
		draw: (ctx)->
			ctx.save()
			ctx.translate(@x,@y)
			mX = mouseX - @x
			mY = mouseY - @y
			
			unless mouseBend
				mouseFret = 0 # = OPEN
				mouseFretX = 0
				mouseFretW = -OSW*1.8
			
			# draw board
			ctx.fillStyle = "#FFF7B2"
			ctx.fillRect(0,@h*0.1,@w,@h)
			ctx.fillStyle = "#F3E08C"
			ctx.fillRect(0,0,@w,@h)
			
			# check if mouse is over the fretboard (or Open Strings area)
			ctx.beginPath()
			ctx.rect(-OSW,0,@w+OSW,@h)
			mouseOverFB = ctx.isPointInPath(mouseX, mouseY)
			
			# draw frets
			fretXs = [mouseFretX]
			fretWs = [mouseFretW]
			x = 0
			xp = 0
			fret = 1
			while fret < @num_frets
				x += (@scale - x) / 17.817
				mx = (x + xp) / 2
				
				if not mouseBend and not mouseOpen and mX < x and mX >= xp
					mouseFret = fret
					mouseFretX = x
					mouseFretW = xp-x
				
				fretXs[fret] = x
				fretWs[fret] = xp-x
				
				line(x,0,x,@h,"#444",2)
				
				ctx.fillStyle = "#FFF"
				n_inlays = @inlays[fret-1]
				for i in [0..n_inlays]
					# i for inlay of course
					ctx.beginPath()
					ctx.arc(mx,(i+1/2)/n_inlays*@h,7,0,tau,no)
					ctx.fill()
					# ctx.fillRect(mx, Math.random()*@h,5,5)
				
				xp = x
				fret++
			
			# draw strings
			sh = @h/@strings.length
			unless mouseBend # (don't switch strings while bending)
				mouseString = mY // sh
				mouseStringY = (mouseString+1/2) * sh
			
			for str, s in @strings
				sy = (s+1/2)*sh
				
				if mouseOverFB and s is mouseString
					if mouseDown and mouseBend
						line(0,sy,mouseFretX,mY,"#555",s/3+1)
						line(mouseFretX,mY,@w,sy,"rgba(150,255,0,0.8)",(s/3+1)*2)
					else
						line(0,sy,mouseFretX,sy,"#555",s/3+1)
						line(mouseFretX,sy,@w,sy,"rgba(150,255,0,0.8)",(s/3+1)*2)
				else
					line(0,sy,@w,sy,"#555",s/3+1)
				
				ctx.font = "25px Helvetica"
				ctx.textAlign = "center"
				ctx.textBaseline = "middle"
				ctx.fillStyle = "#000"
				ctx.fillText(str.text,-OSW/2,sy)
			
			# console.log(mouseOverFB, mouseFret, mouseString)
			if mouseOverFB and 0 <= mouseString < @strings.length
				if mouseDown
					ctx.fillStyle = "rgba(0,255,0,0.5)"
					if (not recNote or
					recNote.f isnt mouseFret or
					recNote.s isnt mouseString)
						recNote =
							s: mouseString
							f: mouseFret
						
						song.notes.push(recNote)
						
						fretName = "#{mouseFret}"
						dashes = ["ERROR )","-","--","---","----"][fretName.length]
						for _, s in song.tabs
							song.tabs[s] += if s is mouseString then fretName else dashes
							song.tabs[s] += "-"
						
						$textarea.val(song)
						$textarea[0].scrollLeft = $textarea[0].scrollWidth
						
						@strings[mouseString].play(mouseFret)
						
					else if mouseBend
						@strings[mouseString].bend(abs(mY-mouseStringY))
					
				else
					ctx.fillStyle = "rgba(0,255,0,0.2)"
					recNote = null
				
				b = 5
				ctx.fillRect(mouseFretX+b,mouseStringY-sh/2+b,mouseFretW,sh-b-b) # mouseFretW-b*2
			
			# draw recorded notes playing back from keyboard
			for key, chord of playingNotes
				for i, note of chord
					b = 5
					y = note.s*sh
					sy = (note.s+1/2)*sh
					
					ctx.fillStyle = "rgba(0,255,255,0.2)"
					ctx.fillRect(fretXs[note.f]+b,y+b,fretWs[note.f],sh-b-b) # fretWs[note.f]-b*2
				
					line(
						fretXs[note.f],sy
						@w,sy
						"rgba(0,255,255,0.8)"
						(note.s/3+1)*2
					)
			
			ctx.restore()
	
	fretboard.strings.push new GuitarString "E4"
	fretboard.strings.push new GuitarString "B3"
	fretboard.strings.push new GuitarString "G3"
	fretboard.strings.push new GuitarString "D3"
	fretboard.strings.push new GuitarString "A2"
	fretboard.strings.push new GuitarString "E2"
	
	###for(s=0s<fretboard.strings.lengths++){
		song.tabs.push(..)
	}###
	
	render = ->
		ctx.clearRect(0,0,canvas.width,canvas.height)
		fretboard.draw(ctx)
	
	do animate = ->
		render()
		requestAnimationFrame(animate)
	
	
	# # # # # # # # # # # # # # # # # # # # # # 
	

	$$ = $(window)
	
	prevent = (e)->
		e.preventDefault()
		no
	
	$$.on "mousemove mousedown", (e)->
		offset = $canvas.offset()
		mouseX = e.pageX - offset.left
		mouseY = e.pageY - offset.top
	
	$canvas.on "mousedown", (e)->
		mouseDown = on
		mouseOpen = on if e.button is 2
		mouseBend = on if e.button is 1
		$$.on "mousemove", prevent # make it so you don't select text in the textarea when dragging from the canvas
	
	$$.on "mouseup blur", (e)->
		$$.off "mousemove", prevent # but let you drag other times
		mouseDown = off
		mouseOpen = off
		mouseBend = off
		
		# stop strings' rings
		for string in fretboard.strings
			string.release()
		
		if e.keyCode is 32 # Spacebar
			sustain = off
	
	$canvas.on "contextmenu", prevent
	
	$$.on "keydown", (e)->
		key = e.keyCode
		console?.log? key
		
		if e.keyCode is 17 # Ctrl
			$textarea.focus() # just so Ctrl+A works outside the textarea
		
		return if e.ctrlKey or e.shiftKey or e.altKey or key > ~~100
		
		if key is 36 # Home
			song.pos = 0
		else if key is 32 # Spacebar
			sustain = on
		else
			unless e.target.tagName.match /textarea|input/i
				
				return if playingNotes[key] # prevent repeat
				play = song.notes[song.pos]
				return unless play
				
				chord = if play.length then play else [play]
				
				playingNotes[key] = chord
				song.pos = (song.pos+1) % song.notes.length
				
				PLAYING_ID = Math.random()
				for chord_note in chord
					str = fretboard.strings[chord_note.s]
					str.PLAYING_ID = PLAYING_ID
					str.play(chord_note.f)
				
				$$.on "keyup", (e)->
					if e.keyCode is key
						for chord_note in chord
							str = fretboard.strings[chord_note.s]
							if str.PLAYING_ID is PLAYING_ID
								str.release()
						
						delete playingNotes[key]
	
	$$.on "blur", ->
		string.stop() for string in fretboard.strings
	
	$textarea.on "change", ->
		text = $textarea.val()
		if text isnt "#{song}"
			res = interpretTabs(text)
			if typeof res is "string"
				$textarea.val("[!] #{res}").select()
			else
				song.clear()
				song.notes = res
				$textarea.val(song)
	
	resize = ->
		canvas.width = document.body.clientWidth
		canvas.height = fretboard.h + fretboard.y*2
	
	$$.on "resize", resize
	resize()


# @TODO: mobile support

