
class @Fretboard
	
	OSW = 60 # Open Strings area Width (left of the fretboard)
	
	x: OSW
	y: 60
	w: 31337
	h: 300
	num_frets: 40
	scale: 1716
	# inlays: [0,0,0,0,1,0,1,0,0,1,0,1,190,0,0,0,0,0,0,0,0,0,0,0,3] # <--
	inlays: [0,0,1,0,1,0,1,0,1,0,0,2,0,0,1,0,1,0,1,0,1,0,0,2] # most common
	# inlays: [0,0,1,0,1,0,1,0,0,1,0,2,0,0,1,0,1,0,1,0,0,1,0,2] # less common
	
	recNote = null
	
	constructor: ->
		@strings = [
			new GuitarString "E4"
			new GuitarString "B3"
			new GuitarString "G3"
			new GuitarString "D3"
			new GuitarString "A2"
			new GuitarString "E2"
		]
		
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
	
	draw: (ctx)->
		
		line = (x1,y1,x2,y2,ss,lw)->
			ctx.strokeStyle = ss if ss?
			ctx.lineWidth = lw if lw?
			ctx.beginPath()
			ctx.moveTo(x1,y1)
			ctx.lineTo(x2,y2)
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
		ctx.fillRect(0,@h*0.1,@w,@h)
		ctx.fillStyle = "#F3E08C"
		ctx.fillRect(0,0,@w,@h)
		
		# check if @pointer is over the fretboard (or Open Strings area)
		ctx.beginPath()
		ctx.rect(-OSW,0,@w+OSW,@h)
		@pointerOverFB = ctx.isPointInPath(@pointerX, @pointerY)
		
		# draw frets
		fretXs = [@pointerFretX]
		fretWs = [@pointerFretW]
		x = 0
		xp = 0
		fret = 1
		while fret < @num_frets
			x += (@scale - x) / 17.817
			mx = (x + xp) / 2
			
			if not @pointerBend and not @pointerOpen and mX < x and mX >= xp
				@pointerFret = fret
				@pointerFretX = x
				@pointerFretW = xp-x
			
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
		unless @pointerBend # (don't switch strings while bending)
			@pointerString = mY // sh
			@pointerStringY = (@pointerString+1/2) * sh
		
		for str, s in @strings
			sy = (s+1/2)*sh
			
			if @pointerOverFB and s is @pointerString
				if @pointerDown and @pointerBend
					line(0,sy,@pointerFretX,mY,"#555",s/3+1)
					line(@pointerFretX,mY,@w,sy,"rgba(150,255,0,0.8)",(s/3+1)*2)
				else
					line(0,sy,@pointerFretX,sy,"#555",s/3+1)
					line(@pointerFretX,sy,@w,sy,"rgba(150,255,0,0.8)",(s/3+1)*2)
			else
				line(0,sy,@w,sy,"#555",s/3+1)
			
			ctx.font = "25px Helvetica"
			ctx.textAlign = "center"
			ctx.textBaseline = "middle"
			ctx.fillStyle = "#000"
			ctx.fillText(str.text,-OSW/2,sy)
		
		if @pointerOverFB and 0 <= @pointerString < @strings.length
			if @pointerDown
				ctx.fillStyle = "rgba(0,255,0,0.5)"
				unless recNote?.f is @pointerFret and recNote?.s is @pointerString
					
					song.addNote recNote =
						s: @pointerString
						f: @pointerFret
					
					@strings[@pointerString].play(@pointerFret)
					
				else if @pointerBend
					@strings[@pointerString].bend(abs(mY-@pointerStringY))
				
			else
				ctx.fillStyle = "rgba(0,255,0,0.2)"
				recNote = null
			
			b = 5
			ctx.fillRect(@pointerFretX+b,@pointerStringY-sh/2+b,@pointerFretW,sh-b-b) # @pointerFretW-b*2
		
		# draw notes being played back from keyboard
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


