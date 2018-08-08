
class @Fretboard
	
	OSW = 60 # Open Strings area Width (left of the fretboard)
	$$ = $(window)
	
	num_frets: 40
	# inlays: (~~(Math.random() * 4) for [0..40])
	# inlays: [3, 0, 1, 1, 1, 1, 0, 3, 0, 3, 3, 1, 3, 2, 1, 2, 0, 0, 3, 0, 2, 1, 0, 0, 2, 0, 2, 1, 2, 2, 3, 0, 2, 0, 1, 1, 2, 2, 2, 0, 1]
	# inlays: [2, 3, 1, 0, 1, 2, 3, 2, 1, 0, 0, 5, 0, 0, 1, 2, 0, 3, 0, 2, 1, 0, 0, 5, 0, 0, 1, 2, 0, 3, 0, 2, 1, 0, 0] # rad dots, yo
	inlays: [0, 0, 1, 0, 1, 0, 1, 0, 1, 0, 0, 2, 0, 0, 1, 0, 1, 0, 1, 0, 1, 0, 0, 2] # most common
	# inlays: [0, 0, 1, 0, 1, 0, 1, 0, 0, 1, 0, 2, 0, 0, 1, 0, 1, 0, 1, 0, 0, 1, 0, 2] # less common
	
	@themes:
		"Tan Classic":
			fretboard: "#F3E08C"
			fretboard_side: "#FFF7B2"
			inlays: "#FFF"
			frets: "#444"
			strings: "#555"
			shadow: off
			scale_highlight_note_background: "green"
			scale_highlight_note_text: "white"
		"Tan":
			fretboard: "#F3E08C"
			fretboard_side: "#FFF7B2"
			inlays: "#FFF"
			frets: "#ddd"
			strings: "#555"
			scale_highlight_note_background: "green"
			scale_highlight_note_text: "white"
		"Orange":
			fretboard: "#E8B16B"
			fretboard_side: "#F7CC97"
			inlays: "#FFF"
			frets: "#ddd"
			strings: "#555"
			scale_highlight_note_background: "orangered"
			scale_highlight_note_text: "white"
		"Dark Gray":
			fretboard: "#333"
			fretboard_side: "#222"
			inlays: "#FFF"
			frets: "lightgray"
			strings: "#777"
			scale_highlight_note_background: "#555"
			scale_highlight_note_text: "white"
		"Tinted Dark":
			fretboard: "#433"
			fretboard_side: "#322"
			inlays: "#FFF"
			frets: "lightgray"
			strings: "#777"
			scale_highlight_note_background: "black"
			scale_highlight_note_text: "white"
		"Gilded Dark":
			fretboard: "#381411"
			fretboard_side: "#1C0000"
			inlays: "#FFF"
			frets: "#EAE8C2"
			strings: "#E0DC98"
			scale_highlight_note_background: "black"
			scale_highlight_note_text: "#FFFFAA"
	
	constructor: ->
		@strings = [
			new GuitarString "E4"
			new GuitarString "B3"
			new GuitarString "G3"
			new GuitarString "D3"
			new GuitarString "A2"
			new GuitarString "E2"
		]
		
		@fret_scale = 1716
		@x = OSW
		# @TODO: balance visual weight vertically
		@y = 60
		@w = 1920 # not because it's my screen width
		@h = 300

		# NOTE: frets are defined as an X of the fret, but the width of the space between it and the *previous* fret
		# (the width of the space you can press down on to hold the string against a given fret)
		@openFretW = OSW#*1.8
		@openFretX = 0

		@pointerX = 0
		@pointerY = 0
		@pointerDown = off
		@pointerOpen = off # override @pointerFret to be open
		@pointerBend = off
		
		@pointerFret = 0
		@pointerFretX = @openFretX # TODO: clean up redundant information/state
		@pointerFretW = @openFretW
		@pointerString = 0
		@pointerStringY = 0
		
		@theme = Fretboard.themes["Dark Gray"]
		
		@rec_note = null
		
		@playing_notes = {}
		
		$canvas = $("<canvas tabindex=0 touch-action=pan-y/>")
		@canvas = $canvas[0]
		
		prevent = (e)->
			e.preventDefault()
			return false
		
		update_pointer_position = (e)=>
			offset = $canvas.offset()
			@pointerX = e.pageX - offset.left
			@pointerY = e.pageY - offset.top
			return
		
		$$.on "pointermove", update_pointer_position
		
		$canvas.on "pointerdown", (e)=>
			@pointerDown = on
			@pointerOpen = on if e.button is 2
			@pointerBend = on if e.button is 1
			update_pointer_position(e)
			prevent(e)
			$canvas.focus()
			$$.on "pointermove", prevent # make it so you don't select text in the textarea when dragging from the canvas
			return
		
		$$.on "pointerup blur", (e)=>
			$$.off "pointermove", prevent # but let you drag other times
			@pointerDown = off
			@pointerOpen = off
			@pointerBend = off
			string.release() for string in @strings
			return
		
		# @TODO: pointercancel/blur/Esc
		
		$canvas.on "contextmenu", prevent
		
		$$.on "resize", @resize # :)
		setTimeout @resize # :/
		setTimeout @resize # :(
	
	resize: =>
		@canvas.width = @canvas.parentElement.clientWidth
		@canvas.height = @h + @y*2
		# @fret_scale = @canvas.width * 1.11
		# @fret_scale = Math.sqrt(@canvas.width) * 50
		@fret_scale = Math.min(Math.sqrt(@canvas.width) * 50, 2138)
		# @x = OSW + Math.max(0, (@canvas.width - @w)/2) # to center it
		return
	
	draw: =>
		ctx = @canvas.getContext("2d")
		
		ctx.clearRect(0, 0, @canvas.width, @canvas.height)
		
		drawLine = (x1, y1, x2, y2, ss, lw)=>
			ctx.strokeStyle = ss if ss?
			ctx.lineWidth = lw if lw?
			ctx.beginPath()
			ctx.moveTo(x1, y1)
			ctx.lineTo(x2, y2)
			ctx.stroke()
			return
		
		drawBentLine = (x1, y1, x2, y2, controlPointXOffset, controlPointYOffset, ss, lw)=>
			ctx.strokeStyle = ss if ss?
			ctx.lineWidth = lw if lw?
			ctx.beginPath()
			ctx.moveTo(x1, y1)
			ctx.quadraticCurveTo(
				(x1+x2)/2 + controlPointXOffset
				(y1+y2)/2 + controlPointYOffset
				x2, y2
			)
			ctx.stroke()
			return

		drawVibratingString = (x1, y1, x2, y2, stringAmplitudeData, ss, lw)=>
			amplitudeToPixels = 3
			# limit the amplitude it's considered to be at, to keep it physically plausible,
			# especially since we're using a wah-wah effect to make it sound smoother at the starts of plucks,
			# which isn't part of the audio/PCM/amplitude data we're using, because it's straight from the synthesizer
			maxAmplitude = 0.005
			# could do the limit in pixels instead (which could be nicer)
			ctx.save()
			numRenders = 21 # could probably afford to be smaller
			# also, my intuition here is that an odd number might avoid lining up with harmonics somewhat (when not using random sampling)
			# but it might just scale *where* it lines up / affect what frequencies resonate
			ctx.globalAlpha = 1 / numRenders # is this technically accurate? would it be if we used additive blending?
			for i in [0...numRenders]
				xLength = x2 - x1

				# index = ~~(Math.random() * stringAmplitudeData.length)
				index = ~~(i / numRenders * stringAmplitudeData.length)
				nextIndex = (index + 1) % stringAmplitudeData.length
				# TODO: try using not-right-next-to-each-other indexes
				# to try to make it fuller looking

				deltaAmplitude = (stringAmplitudeData[nextIndex] - stringAmplitudeData[index])
				deltaAmplitude = (stringAmplitudeData[nextIndex] - stringAmplitudeData[index])
				# amplitude difference / delta, or an amplitude of sound but not the *modeled* 'position of the string' *in the synth*?

				yBend = Math.min(Math.max(deltaAmplitude, -maxAmplitude), maxAmplitude) * amplitudeToPixels * xLength

				drawBentLine(x1, y1, x2, y2, 0, yBend, ss, lw)
			ctx.restore()
			return

		drawFingerHoldOrOpenNote = (fretX, fretW, stringY, stringHeight, stringBendY=0)=>
			ctx.beginPath()
			unless fretX is @openFretX
				# ctx.ellipse(
				# 	fretX - fretW/2 # center x
				# 	stringY + stringBendY # center y
				# 	stringHeight*0.5 # radius x
				# 	stringHeight*0.4 # radius y
				# 	0 # rotation
				# 	0, Math.PI * 2 # start, end
				# )
				ctx.fillRect(fretX + 5 - fretW, stringY - stringHeight/2, fretW - 5, stringHeight)
			ctx.fillRect(fretX - 5, stringY - stringHeight/2, 10, stringHeight)
			ctx.fill()
			return

		ctx.save()
		ctx.translate(@x, @y)
		mX = @pointerX - @x
		mY = @pointerY - @y
		
		unless @pointerBend
			@pointerFret = 0
			@pointerFretX = @openFretX
			@pointerFretW = @openFretW
		
		# draw board
		ctx.fillStyle = @theme.fretboard_side
		ctx.fillRect(0, @h*0.1, @w, @h)
		ctx.fillStyle = @theme.fretboard
		ctx.fillRect(0, 0, @w, @h)
		
		# check if @pointer is over the fretboard (or Open Strings area)
		ctx.beginPath()
		ctx.rect(-OSW, 0, @w+OSW, @h)
		@pointerOverFB = ctx.isPointInPath(@pointerX, @pointerY)
		
		# draw frets
		fretXs = [@openFretX]
		fretWs = [@openFretW]
		x = 0
		xp = 0
		fret = 1
		while fret < @num_frets
			x += (@fret_scale - x) / 17.817
			mx = (x + xp) / 2
			
			if not @pointerBend and not @pointerOpen and mX < x and mX >= xp
				@pointerFret = fret
				@pointerFretX = x
				@pointerFretW = x - xp
			
			fretXs[fret] = x
			fretWs[fret] = x - xp
			
			unless @theme.shadow is off
				drawLine(x+0.5, 0, x+0.5, @h, "rgba(0, 0, 0, 0.8)", 5)
			drawLine(x, 0, x, @h, @theme.frets, 3)
			
			ctx.fillStyle = @theme.inlays
			n_inlays = @inlays[fret-1]
			for i in [0..n_inlays]
				# i for inlay of course
				ctx.beginPath()
				ctx.arc(mx, (i+1/2)/n_inlays*@h, 7, 0, tau, no)
				ctx.fill()
				# ctx.fillRect(mx, Math.cos(mx)*@h, 5, 5) # faux microtonal aesthetic
			
			xp = x
			fret++
		
		# TODO: base the drawing of the strings off of the state of the strings only
		# vibrating only after the furthest to the right finger hold
		# so playback visualization makes physical sense (esp. when playing back and playing via the fretboard at the same time and bending)
		# (and possibly model multiple finger holds in the string state so that it can draw between bent holds before the rightmost finger hold even tho they'd be ineffectual)
		# and TODO: change the pitch of the synth when you release a note (to open, or the nearest remaining finger hold) (without reactuating, i.e. a pull-off (and not a flick-off))

		# draw strings
		sh = @h/@strings.length
		unless @pointerBend # (don't switch strings while bending)
			@pointerString = mY // sh
			@pointerStringY = (@pointerString+1/2) * sh
		
		for str, s in @strings
			sy = (s+1/2)*sh
			
			if @pointerOverFB and s is @pointerString
				midpointY = (if @pointerDown and @pointerBend then mY else sy)
				drawLine(0, sy, @pointerFretX, midpointY, @theme.strings, s/3+1)
				drawVibratingString(@pointerFretX, midpointY, @w, sy, str.data, "rgba(150, 255, 0, 0.8)", (s/3+1)*2)
			else
				drawLine(0, sy, @w, sy, @theme.strings, s/3+1)
			
			ctx.font = "25px Helvetica"
			ctx.textAlign = "center"
			ctx.textBaseline = "middle"
			ctx.fillStyle = "#000"
			ctx.fillText(str.label, -OSW/2, sy)
		
		if @pointerOverFB and 0 <= @pointerString < @strings.length
			if @pointerDown
				ctx.fillStyle = "rgba(0, 255, 0, 0.5)"
				unless @rec_note?.f is @pointerFret and @rec_note?.s is @pointerString
					
					song.addNote @rec_note =
						s: @pointerString
						f: @pointerFret
					
					@strings[@pointerString].play(@pointerFret)
					
				else if @pointerBend
					@strings[@pointerString].bend(abs(mY-@pointerStringY))
				
			else
				ctx.fillStyle = "rgba(0, 255, 0, 0.2)"
				@rec_note = null
			
			drawFingerHoldOrOpenNote(@pointerFretX, @pointerFretW, @pointerStringY, sh, (if @pointerBend then mY-@pointerStringY else 0))
		
		# draw notes being played back from the tablature / recorded song
		for key, chord of @playing_notes
			for i, note of chord
				sy = (note.s+1/2)*sh
				
				ctx.fillStyle = "rgba(0, 255, 255, 0.2)"
				drawFingerHoldOrOpenNote(fretXs[note.f], fretWs[note.f], sy, sh)
			
				drawVibratingString(
					fretXs[note.f], sy
					@w, sy
					@strings[note.s].data
					"rgba(0, 255, 255, 0.8)"
					(note.s/3+1)*2
				)
		
		for scale_highlight_layer in ["background", "text"]
			for str, s in @strings
				sy = (s+1/2)*sh
				for fret_i in [0..fretXs.length]
					note_n = str.base_note_n + fret_i
					fret_x = fretXs[fret_i]
					fret_w = fretWs[fret_i]
					if is_midi_value_in_scale(note_n)
						switch scale_highlight_layer
							when "background"
								ctx.beginPath()
								radius = sh * (if fret_i < 20 then 0.3 else 0.25)
								ctx.arc(fret_x - fret_w/2, sy, radius, 0, Math.PI * 2)
								ctx.fillStyle = @theme.scale_highlight_note_background or "white"
								ctx.fill()
							when "text"
								ctx.beginPath()
								font_size = if fret_i is 0 then 25 else if fret_i < 20 then 20 else 15
								ctx.font = "#{font_size}px Helvetica"
								ctx.textAlign = "center"
								ctx.textBaseline = "middle"
								ctx.fillStyle = @theme.scale_highlight_note_text or "black"
								# TODO: investigate, why is it fromKey that works, rather than fromMIDI?
								note_name =
									teoria.note.fromKey(note_n).toString(true)
										.replace(/^[a-g]/, ((m)-> m.toUpperCase()))
										.replace("#", "♯")
										.replace("b", "♭")
								ctx.fillText(note_name, fret_x - fret_w/2, sy)

		ctx.restore()


