
{Range} = ace.require 'ace/range'
event = require 'ace/lib/event'

class @TablatureEditor
	constructor: (element)->
		
		@editor = ace.edit(element)
		@editor.getSession().setMode 'ace/mode/ocaml'
		@editor.setOption 'highlightActiveLine', off
		@editor.setOption 'showPrintMargin', off
		@editor.setOption 'showGutter', off
		
		@editor.commands.bindKey 'Tab', null
		@editor.commands.bindKey 'Shift-Tab', null
		
		# tuning = "eBGDAE"
		
		# @editor.session.gutterRenderer =
		# 	getWidth: (session, lastLineNumber, config)->
		# 		config.characterWidth
		# 	getText: (session, row)->
		# 		tuning[row] ? ""
		
		@column_highlight_markers = []
		@playing_note_highlight_markers = {}
		
		@positions = []
		
		@editor.on "change", =>
			tablature = @editor.getValue()
			lines = tablature.split(/\r?\n/)
			
			@positions = []
			last_had_digit = no
			x = 0
			while x < lines[0].length
				has_digit = no
				for line in lines
					has_digit = yes if line[x].match(/\d/)
				if has_digit and not last_had_digit
					@positions.push x
				last_had_digit = has_digit
				x++
		
		# The following is based on the default multi-selection block selection code:
		# https://github.com/ajaxorg/ace/blob/master/lib/ace/mouse/multi_select_handler.js
		
		isSamePoint = (p1, p2)->
			p1.row is p2.row and p1.column is p2.column
		
		rectSel = []
		
		{selection} = @editor
		
		@editor.on "mousedown", (e)=>
			button = e.getButton()
			return unless button is 0
			
			e.stop()
			
			pos = e.getDocumentPosition()
			
			[mouseX, mouseY] = [e.x, e.y]
			onMouseSelection = (e)=>
				mouseX = e.clientX
				mouseY = e.clientY

			
			session = @editor.getSession()
			
			screenAnchor = @editor.renderer.pixelToScreenCoordinates(mouseX, mouseY)
			screenAnchor.row = 0 # tablature!
			cursor = session.screenToDocumentPosition(screenAnchor.row, screenAnchor.column)
			
			screenCursor = screenAnchor
			
			@editor.inVirtualSelectionMode = true        
			initialRange = null
			rectSel = []
			blockSelect = =>
				newCursor = @editor.renderer.pixelToScreenCoordinates(mouseX, mouseY)
				newCursor.row = 5 # tablature!
				cursor = session.screenToDocumentPosition(newCursor.row, newCursor.column)

				return if (isSamePoint(screenCursor, newCursor) and isSamePoint(cursor, selection.lead))
				
				screenCursor = newCursor

				@editor.$blockScrolling++
				@editor.selection.moveToPosition(cursor)
				@editor.renderer.scrollCursorIntoView()

				@editor.removeSelectionMarkers(rectSel)
				rectSel = selection.rectangularRangeBlock(screenCursor, screenAnchor)
				if @editor.$mouseHandler.$clickSelection and rectSel.length is 1 and rectSel[0].isEmpty()
					rectSel[0] = @editor.$mouseHandler.$clickSelection.clone()
				rectSel.forEach(@editor.addSelectionMarker, @editor)
				@editor.updateSelectionMarkers()
				@editor.$blockScrolling--

			
			@editor.$blockScrolling++
			@editor.selection.moveToPosition(cursor)
			@editor.renderer.scrollCursorIntoView()
			
			@editor.removeSelectionMarkers(rectSel)
			rectSel = selection.rectangularRangeBlock(screenCursor, screenAnchor)
			if @editor.$mouseHandler.$clickSelection and rectSel.length is 1 and rectSel[0].isEmpty()
				rectSel[0] = @editor.$mouseHandler.$clickSelection.clone()
			
			rectSel.forEach(@editor.addSelectionMarker, @editor)
			@editor.updateSelectionMarkers()
			@editor.$blockScrolling--
			
			
			screenCursor = {row: -1, column: -1}
			
			onMouseSelectionEnd = (e)=>
				clearInterval(timerId)
				@editor.removeSelectionMarkers(rectSel)
				unless rectSel.length
					rectSel = [selection.toOrientedRange()]
				@editor.$blockScrolling++
				if initialRange
					@editor.removeSelectionMarker(initialRange)
					selection.toSingleRange(initialRange)
				
				selection.addRange range for range in rectSel
				@editor.inVirtualSelectionMode = false
				@editor.$mouseHandler.$clickSelection = null
				@editor.$blockScrolling--

			onSelectionInterval = blockSelect

			event.capture(@editor.container, onMouseSelection, onMouseSelectionEnd)
			timerId = setInterval(onSelectionInterval, 20)

			return e.preventDefault()
	
	highlightPlayingNote: (pos, note)->
		@removePlayingNote(pos, note)
		key = "#{note.s}:#{pos}"
		
		column = @positions[pos]
		
		range = new Range(note.s, column, note.s, column+1)
		marker = @editor.getSession().addMarker(range, "playing-note", "text") # text?
		@playing_note_highlight_markers[key] = marker
	
	removePlayingNote: (pos, note)->
		key = "#{note.s}:#{pos}"
		existing_marker = @playing_note_highlight_markers[key]
		@editor.getSession().removeMarker existing_marker if existing_marker
	
	highlightSongPosition: (pos)->
		column = @positions[pos]
		
		for marker in @column_highlight_markers
			@editor.getSession().removeMarker marker
		
		@column_highlight_markers =
			for i in [0..6]
				range = new Range(i, column-1, i, column)
				marker = @editor.getSession().addMarker(range, "playback-position", "text") # text?
				marker
