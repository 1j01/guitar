
parseTabs = (tablature)->
	
	# this goes against the convention of left=low (i.e. EADGBE)
	# and then it has to be reversed below, so I should probably change this
	tuning = "eBGDAE"
	
	# strings as in both things
	strings = {}
	for string_name in tuning by -1
		strings[string_name] = ""
	
	# find sections of lines prefixed by string names
		# (minimum of one dash in each line)
	
	lines = tablature.split("\n")
	blocks = []
	current_block = null
	
	end_current_block = ->
		if current_block
			current_block.tuning = ""
			for block_line in current_block.lines
				m = block_line.match(/^\s*(\w)/)
				if m?
					current_block.tuning += m[1]
				else
					current_block.tuning = tuning
			if current_block.tuning.toUpperCase() is tuning.toUpperCase()
				current_block.tuning = tuning
			current_block = null
	
	for line in lines
		if line.indexOf("-") isnt -1
			unless current_block
				current_block = {lines: []}
				blocks.push current_block
			current_block.lines.push line
		else
			end_current_block()
	
	end_current_block()
	
	# console.log "blocks found:\n", blocks
	
	for block in blocks
		
		{lines} = block
		
		if lines.length is 4
			throw new Error "Bass tablature is not supported (yet)"
		
		if lines.length isnt 6
			throw new Error "#{lines.length}-string tablature is not supported (yet)"
		
		if block.tuning isnt tuning
			throw new Error "Alternate tunings such as #{block.tuning} are not supported (yet)"
		
		min_length = Infinity
		for line in lines
			if line.length < min_length
				min_length = line.length
		
		for line in lines
			if line.length > min_length
				unless line[min_length] is " "
					alignment_marker = "<<"
					throw new Error """
						Tab interpretation failed due to misalignment:
						
						#{(
							for line in lines
								if line[min_length] is " "
									"#{line.slice(0, min_length)} #{alignment_marker}#{line.slice(min_length)}"
								else
									"#{line} #{alignment_marker}"
						).join("\n")}
					"""
		
		lines =
			for line in lines
				line.slice(0, min_length)
		
		for line, i in lines
			
			m = line.match(/^\s*(\w)\s*(.*)$/)
			if m?
				string_name = m[1].toUpperCase()
				some_notes = m[2].trim()
				
				if string_name is "E" and i is 0
					string_name = "e"
			else
				string_name = tuning[i]
				some_notes = line
			
			strings[string_name] += some_notes
	
	unless blocks[0]?
		throw new Error "Tab interpretation failed: no music blocks found"
	
	# heuristically address the ambiguity where
	# e.g. --12-- can mean either twelve or one then two
	squishy = tablature.match(/[03-9]\d[^\n*]-/)?
	
	pos = 0
	cont = yes
	notes = []
	while cont
		cont = no
		multi_digit = no
		chord = []
		
		for s, string of strings
			ch = string[pos]
			ch2 = string[pos+1]
			cont = yes if ch?
			multi_digit = yes if ch?.match(/\d/) and ch2?.match(/\d/) unless squishy
		
		for s, string of strings
			ch = string[pos]
			ch2 = string[pos+1]
			if ch?.match(/\d/) or (multi_digit and ch2?.match(/\d/))
				if ch2?.match(/\d/) and not squishy
					chord.push
						# @TODO: this should probably use if ch?.match(/\d/)
						f: if ch is "-" then parseInt(ch2) else parseInt(ch + ch2)
						s: tuning.indexOf(s)
				else
					chord.push
						f: parseInt(ch)
						s: tuning.indexOf(s)
		
		if chord.length > 0
			notes.push(chord)
		
		pos++
		pos++ if multi_digit
	
	# for s, string of strings
	# 	console.log s, song.tabs.indexOf(s)
	# 	if song.tabs.indexOf(s) >= 0
	# 		song.tabs[tuning.indexOf(s)] += strings[s]
	# 	else
	# 		console.log "UUHUHHH :/"
	
	return notes


# @TODO: parse and stringify?

if module?
	module.exports = parseTabs
else
	@parseTabs = parseTabs
