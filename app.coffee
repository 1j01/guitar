
@song =
	clear: ->
		@notes = []
		@tuning = "eBGDAE" # backwards
		@strings = ("#{string_name}|-" for string_name in @tuning)
		@pos = 0
	
	toJSON: -> @notes
	toString: -> song.strings.join("\n")
	
	addNote: (rec_note)->
		song.notes.push(rec_note)
		
		# @TODO: go through Tablature.stringify()
		
		dashes = ["","-","--","---","----"]["#{rec_note.f}".length]
		for string, s in song.strings
			song.strings[s] += if s is rec_note.s then rec_note.f else dashes
			song.strings[s] += "-" # additional dash to space notes apart
		
		$tablature_error.dismiss()
		
		tablature_editor.editor.setValue("#{song}", 1)
		
		if song.notes.length is 1
			tablature_editor.showPlaybackPosition(song.pos)

song.clear()

@fretboard = new Fretboard
$(fretboard.canvas).appendTo(".fretboard-area")

$tablature_error = $(".tablature-error")
$tablature_error.dismiss = -> @hide().attr("aria-hidden", "true").text("")
$tablature_error.message = (message)-> @show().attr("aria-hidden", "false").text(message)

tablature_editor = new TablatureEditor($(".tablature-editor")[0])
tablature_editor.showPlaybackPosition(song.pos)


$$ = $(window)

$$.on "keyup", (e)->
	if e.keyCode is 32 # Spacebar
		sustain = off
		for string in fretboard.strings
			string.release()

$$.on "keydown", (e)->
	key = e.keyCode
	console?.log? key if e.altKey
	
	if e.ctrlKey and key is 65 # Ctrl+A
		tablature_editor.editor.focus()
		tablature_editor.editor.selection.selectAll()
	
	return if e.ctrlKey or e.shiftKey or e.altKey or key is 9 or key > ~~100
	
	if key is 36 # Home
		song.pos = 0
		tablature_editor.showPlaybackPosition(song.pos)
	else if key is 32 # Spacebar
		sustain = on
	else
		unless e.target.tagName.match /textarea|input/i
			
			return if fretboard.playing_notes[key] # prevent repeat
			play = song.notes[song.pos]
			return unless play
			
			chord = if play.length then play else [play]
			
			fretboard.playing_notes[key] = chord
			chord_pos = song.pos
			song.pos = (song.pos+1) % song.notes.length
			
			PLAYING_ID = Math.random()
			for chord_note in chord
				str = fretboard.strings[chord_note.s]
				str.PLAYING_ID = PLAYING_ID
				str.play(chord_note.f)
				tablature_editor.showPlayingNote(chord_pos, chord_note)
			
			$$.on "keyup", onkeyup = (e)->
				if e.keyCode is key
					for chord_note in chord
						str = fretboard.strings[chord_note.s]
						str.release() if str.PLAYING_ID is PLAYING_ID
						tablature_editor.removePlayingNote(chord_pos, chord_note)
					
					delete fretboard.playing_notes[key]
					$$.off "keyup", onkeyup
					
					tablature_editor.showPlaybackPosition(song.pos)

$$.on "blur", ->
	string.stop() for string in fretboard.strings

# @TODO: maybe listen for change and indicate that you need to unfocus it to update
# or better yet just conditionally show a button

tablature_editor.editor.on "blur", ->
	text = tablature_editor.editor.getValue()
	if text isnt "#{song}" and text
		try
			res = Tablature.parse(text.replace(/\ <</g, ""))
		catch error
			if error.blocks
				$tablature_error.message(error.message_only)
				tablature_editor.editor.setValue(error.blocks, -1)
				index = error.blocks.indexOf(error.misaligned_block)
				unless index is -1
					position = tablature_editor.editor.getSession().getDocument().indexToPosition(index)
					tablature_editor.editor.scrollToRow(position.row)
			else
				$tablature_error.message(error.message)
		
		if res
			song.clear()
			song.notes = res
			song.strings = Tablature.stringify(res).split("\n")
			
			$tablature_error.dismiss()
			tablature_editor.editor.setValue("#{song}", -1)
			tablature_editor.showPlaybackPosition(song.pos)
	else
		$tablature_error.dismiss()
