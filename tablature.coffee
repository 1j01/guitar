
@interpretTabs = (str)->
	
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
	
	# fallback to ....wait won't this play incorrectly anyways? uhhh hmmm
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
					console.log "Your guitar is out of tune. #maybe"
					console.debug AnyBlocks.exec(block)
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
			console.log "block found with no string names:\n#{block}"
			lines = block.split("\n")
			for line, i in lines
				someNotes = line.trim()
				noteStrings["eBGDAE"[i]] += "+" + someNotes # STRING the notes together HAHAHAHAHAHAHAHA um
			
			"{.....}"
	
	# @TODO: alert (more) problems with the tabs
	if noteStrings.B.length is 0
		console.log "Tabs interpretation failed (no music blocks found?)"
		return "Tabs interpretation failed."
	
	for s, noteString of noteStrings
		if noteString.length isnt noteStrings.e.length
			console.log "Tabs interpretation failed due to misalignment."
			alignment_marker = "<< (this text must line up)"
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
	
	# address ambiguity (---12--- = "one, two" or "twelve")
	certainlySquishy = not not str.match /[03-9]\d[^\n*]-/
	if certainlySquishy
		# ASSUME --12-- means "one, two"
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
		# ASSUME --12-- means a note on the twelth fret
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

