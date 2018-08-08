###
Note: this file should be kept in sync with tablature-parser

https://github.com/1j01/tablature-parser/blob/master/tablature-parser.coffee
###

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
	
	lines = tablature.split(/\r?\n/)
	blocks = []
	current_block = null
	
	end_current_block = ->
		if current_block
			current_block.tuning = ""
			for block_line in current_block.lines
				m = block_line.match(/^\s*([A-G])/i)
				if m?
					current_block.tuning += m[1]
				else
					current_block.tuning = tuning
			if current_block.tuning.toUpperCase() is tuning.toUpperCase()
				current_block.tuning = tuning
			current_block = null
		return
	
	for line in lines
		if line.match(/[-–—]/)
			unless current_block
				current_block = {lines: []}
				blocks.push current_block
			current_block.lines.push line
		else
			end_current_block()
	
	end_current_block()
	
	# console.log "blocks found:\n", blocks
	
	for block in blocks when block.lines.length > 1
		
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
					alignment_marker = " <<"
					misaligned = (
						for line in lines
							if line[min_length] is " "
								"#{line.slice(0, min_length)}#{alignment_marker}#{line.slice(min_length)}"
							else
								"#{line}#{alignment_marker}"
					).join("\n")
					message_only = "Tab interpretation failed due to misalignment"
					error = new Error """
						#{message_only}:
						
						#{misaligned}
					"""
					error.message_only = message_only
					error.misaligned_block = misaligned
					error.blocks = (
						for _block in blocks
							if _block is block
								misaligned
							else
								_block.lines.join("\n")
					).join("\n\n")
					throw error
		
		lines =
			for line in lines
				line.slice(0, min_length)
		
		for line, i in lines
			
			m = line.match(/^\s*([A-G])\s*(.*)$/i)
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
	# TODO: look only within matched blocks
	squishy = tablature.match(/[03-9]\d/)?
	
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
						f: if ch?.match(/\d/) then parseInt(ch + ch2) else parseInt(ch2)
						s: tuning.indexOf(s)
				else
					chord.push
						f: parseInt(ch)
						s: tuning.indexOf(s)
		
		if chord.length > 0
			notes.push(chord)
		
		pos++
		pos++ if multi_digit
	
	return notes


paddingLeft = (string="", character, length)->
	(Array(length + 1).join(character) + string).slice(-length)

paddingRight = (string="", character, length)->
	(string + Array(length + 1).join(character)).slice(0, length)


stringifyTabs = (notes, tuning = "eBGDAE")->
	strings = ("#{string_name}|-" for string_name in tuning)
	
	for chord in notes
		notes_here = (null for string_name in tuning)
		max_length = 1
		for note in chord
			notes_here[note.s] = note.f
			max_length = Math.max(max_length, "#{note.f}".length)
		for string, i in strings
			strings[i] += "#{paddingRight(notes_here[i], "-", max_length)}-"
	
	strings.join "\n"

Tablature =
	parse: parseTabs
	stringify: stringifyTabs

if module?
	module.exports = Tablature
else
	@Tablature = Tablature
