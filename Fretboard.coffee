
class @Fretboard
	
	OSW = 60 # Open Strings area Width (left of the fretboard)
	$$ = $(window)
	
	num_frets: 40
	# inlays: (~~(Math.random() * 4) for [0..40])
	# inlays: [3, 0, 1, 1, 1, 1, 0, 3, 0, 3, 3, 1, 3, 2, 1, 2, 0, 0, 3, 0, 2, 1, 0, 0, 2, 0, 2, 1, 2, 2, 3, 0, 2, 0, 1, 1, 2, 2, 2, 0, 1]
	# inlays: [2, 3, 1, 0, 1, 2, 3, 2, 1, 0, 0, 5, 0, 0, 1, 2, 0, 3, 0, 2, 1, 0, 0, 5, 0, 0, 1, 2, 0, 3, 0, 2, 1, 0, 0] # rad dots, yo
	inlays: [0, 0, 1, 0, 1, 0, 1, 0, 1, 0, 0, 2, 0, 0, 1, 0, 1, 0, 1, 0, 1, 0, 0, 2] # most common
	# inlays: [0, 0, 1, 0, 1, 0, 1, 0, 0, 1, 0, 2, 0, 0, 1, 0, 1, 0, 1, 0, 0, 1, 0, 2] # less common
	
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
		
		@pointerX = 0
		@pointerY = 0
		@pointerDown = off
		@pointerOpen = off # override @pointerFret to be open
		@pointerBend = off
		
		@pointerFret = 0
		@pointerFretX = 0
		@pointerFretW = -OSW*1.8
		@pointerString = 0
		@pointerStringY = 0
		
		@rec_note = null
		
		@playing_notes = {}
		
		$canvas = $("<canvas tabindex=0 touch-action=pan-y/>")
		@canvas = $canvas[0]
		
		ctx = @canvas.getContext("2d")
		
		prevent = (e)->
			e.preventDefault()
			no
		
		update_pointer_position = (e)=>
			offset = $canvas.offset()
			@pointerX = e.pageX - offset.left
			@pointerY = e.pageY - offset.top
		
		$$.on "pointermove", update_pointer_position
		
		$canvas.on "pointerdown", (e)=>
			@pointerDown = on
			@pointerOpen = on if e.button is 2
			@pointerBend = on if e.button is 1
			update_pointer_position(e)
			prevent(e)
			$canvas.focus()
			$$.on "pointermove", prevent # make it so you don't select text in the textarea when dragging from the canvas
		
		$$.on "pointerup blur", (e)=>
			$$.off "pointermove", prevent # but let you drag other times
			@pointerDown = off
			@pointerOpen = off
			@pointerBend = off
			string.release() for string in @strings
		
		# @TODO: pointercancel/blur/Esc
		
		$canvas.on "contextmenu", prevent
		
		do animate = =>
			ctx.clearRect(0, 0, @canvas.width, @canvas.height)
			@draw(ctx)
			requestAnimationFrame(animate)
		
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
	
	draw: (ctx)->
		
		line = (x1, y1, x2, y2, ss, lw)->
			ctx.strokeStyle = ss if ss?
			ctx.lineWidth = lw if lw?
			ctx.beginPath()
			ctx.moveTo(x1, y1)
			ctx.lineTo(x2, y2)
			ctx.stroke()
		
		ctx.save()
		ctx.translate(@x, @y)
		mX = @pointerX - @x
		mY = @pointerY - @y
		
		unless @pointerBend
			@pointerFret = 0
			@pointerFretX = 0
			@pointerFretW = -OSW*1.8
		
		# draw board
		ctx.fillStyle = "#FFF7B2"
		ctx.fillRect(0, @h*0.1, @w, @h)
		ctx.fillStyle = "#F3E08C"
		ctx.fillRect(0, 0, @w, @h)
		
		# check if @pointer is over the fretboard (or Open Strings area)
		ctx.beginPath()
		ctx.rect(-OSW, 0, @w+OSW, @h)
		@pointerOverFB = ctx.isPointInPath(@pointerX, @pointerY)
		
		# draw frets
		fretXs = [@pointerFretX]
		fretWs = [@pointerFretW]
		x = 0
		xp = 0
		fret = 1
		while fret < @num_frets
			x += (@fret_scale - x) / 17.817
			mx = (x + xp) / 2
			
			if not @pointerBend and not @pointerOpen and mX < x and mX >= xp
				@pointerFret = fret
				@pointerFretX = x
				@pointerFretW = xp-x
			
			fretXs[fret] = x
			fretWs[fret] = xp - x
			
			line(x, 0, x, @h, "#444", 2)
			
			ctx.fillStyle = "#FFF"
			n_inlays = @inlays[fret-1]
			for i in [0..n_inlays]
				# i for inlay of course
				ctx.beginPath()
				ctx.arc(mx, (i+1/2)/n_inlays*@h, 7, 0, tau, no)
				ctx.fill()
				# ctx.fillRect(mx, Math.random()*@h, 5, 5)
			
			xp = x
			fret++
		
		# draw strings
		sh = @h/@strings.length
		unless @pointerBend # (don't switch strings while bending)
			@pointerString = mY // sh
			@pointerStringY = (@pointerString+1/2) * sh
		
		for str, s in @strings
			sy = (s+1/2)*sh
			
			if @pointerOverFB and s is @pointerString
				if @pointerDown and @pointerBend
					line(0, sy, @pointerFretX, mY, "#555", s/3+1)
					line(@pointerFretX, mY, @w, sy, "rgba(150, 255, 0, 0.8)", (s/3+1)*2)
				else
					line(0, sy, @pointerFretX, sy, "#555", s/3+1)
					line(@pointerFretX, sy, @w, sy, "rgba(150, 255, 0, 0.8)", (s/3+1)*2)
			else
				line(0, sy, @w, sy, "#555", s/3+1)
			
			ctx.font = "25px Helvetica"
			ctx.textAlign = "center"
			ctx.textBaseline = "middle"
			ctx.fillStyle = "#000"
			ctx.fillText(str.text, -OSW/2, sy)
		
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
			
			b = 5
			ctx.fillRect(@pointerFretX+b, @pointerStringY-sh/2+b, @pointerFretW, sh-b-b) # @pointerFretW-b*2
		
		# draw notes being played back from keyboard
		for key, chord of @playing_notes
			for i, note of chord
				b = 5
				y = note.s*sh
				sy = (note.s+1/2)*sh
				
				ctx.fillStyle = "rgba(0, 255, 255, 0.2)"
				ctx.fillRect(fretXs[note.f]+b, y+b, fretWs[note.f], sh-b-b) # fretWs[note.f]-b*2
			
				line(
					fretXs[note.f], sy
					@w, sy
					"rgba(0, 255, 255, 0.8)"
					(note.s/3+1)*2
				)
		
		ctx.restore()


