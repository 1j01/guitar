
@song =
	clear: ->
		@notes = []
		@tuning = "eBGDAE" # backwards
		@strings = ("#{string_name}|-" for string_name in @tuning)
		@pos = 0
	
	toJSON: -> @notes
	toString: -> song.strings.join("\n")
	
	addNote: (recNote)->
		song.notes.push(recNote)
		
		# @TODO: go through Tablature.stringify()
		
		dashes = ["ERROR )","-","--","---","----"]["#{recNote.f}".length]
		for string, s in song.strings
			song.strings[s] += if s is recNote.s then recNote.f else dashes
			song.strings[s] += "-" # additional dash to space notes apart
		
		tablature_editor.editor.setValue("#{song}", 1)
		# tablature_editor.editor.scrollToX(Infinity)

song.clear()

@playingNotes = {}

$canvas = $("<canvas tabindex=0 touch-action=pan-y/>").appendTo("body")
canvas = $canvas[0]

$tablature_editor = $("<div class='tablature-editor'/>").appendTo("body")
tablature_editor = new TablatureEditor($tablature_editor[0])

ctx = canvas.getContext("2d")

@fretboard = new Fretboard

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

update_pointer_position = (e)->
	offset = $canvas.offset()
	fretboard.pointerX = e.pageX - offset.left
	fretboard.pointerY = e.pageY - offset.top

$$.on "pointermove", update_pointer_position

$canvas.on "pointerdown", (e)->
	fretboard.pointerDown = on
	fretboard.pointerOpen = on if e.button is 2
	fretboard.pointerBend = on if e.button is 1
	update_pointer_position(e)
	prevent(e)
	$$.on "pointermove", prevent # make it so you don't select text in the textarea when dragging from the canvas

$$.on "pointerup blur", (e)->
	$$.off "pointermove", prevent # but let you drag other times
	fretboard.pointerDown = off
	fretboard.pointerOpen = off
	fretboard.pointerBend = off
	string.release() for string in fretboard.strings

# @TODO: pointercancel/blur/Esc

$canvas.on "contextmenu", prevent

$$.on "keyup", (e)->
	if e.keyCode is 32 # Spacebar
		sustain = off
		for string in fretboard.strings
			string.release()

$$.on "keydown", (e)->
	key = e.keyCode
	console?.log? key
	
	if e.keyCode is 17 # Ctrl
		tablature_editor.editor.focus() # just so Ctrl+A works outside the textarea
	
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
			
			$$.on "keyup", onkeyup = (e)->
				if e.keyCode is key
					for chord_note in chord
						str = fretboard.strings[chord_note.s]
						if str.PLAYING_ID is PLAYING_ID
							str.release()
					
					delete playingNotes[key]
					$$.off "keyup", onkeyup

$$.on "blur", ->
	string.stop() for string in fretboard.strings

tablature_editor.editor.on "blur", ->
	text = tablature_editor.editor.getValue()
	if text isnt "#{song}"
		try
			res = Tablature.parse(text)
		catch err
			# @TODO: errors should be displayed separately
			tablature_editor.editor.setValue("[!] #{err}")
		
		if res
			song.clear()
			song.notes = res
			song.strings = Tablature.stringify(res).split("\n")
			
			tablature_editor.editor.setValue("#{song}", 1)

resize = ->
	canvas.width = document.body.clientWidth
	canvas.height = fretboard.h + fretboard.y*2

$$.on "resize", resize
resize()


