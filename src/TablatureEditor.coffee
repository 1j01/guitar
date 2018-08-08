
{Range} = ace.require 'ace/range'
event = require 'ace/lib/event'

class @TablatureEditor
	constructor: (element)->
		@multi_row_selection_mode = on
		
		@editor = ace.edit(element)
		@editor.getSession().setMode 'ace/mode/ocaml'
		@editor.setOption 'highlightActiveLine', off
		@editor.setOption 'showPrintMargin', off
		@editor.setOption 'showGutter', off
		# setAnimatedScroll
		
		@editor.commands.bindKey 'Tab', null
		@editor.commands.bindKey 'Shift-Tab', null
		
		@editor.$blockScrolling = Infinity
		
		# tuning = "eBGDAE"
		
		# @editor.session.gutterRenderer =
		# 	getWidth: (session, lastLineNumber, config)->
		# 		config.characterWidth
		# 	getText: (session, row)->
		# 		tuning[row] ? ""
		
		@column_highlight_markers = []
		@playing_note_highlight_markers = {}
		
		@positions = []
		
		get_lines = =>
			tablature = @editor.getValue()
			lines = tablature.split(/\r?\n/)
		
		lines_are_uneven = (lines)=>
			lines.some (line)->
				line.length isnt lines[0].length
		
		@editor.on "change", =>
			@positions = []
			
			lines = get_lines()
			
			if lines_are_uneven(lines)
				@hidePlaybackPosition()
				return
			
			last_column_had_digit = no
			column = 0
			while column < lines[0].length
				column_has_digit = lines.some (line)->
					line[column].match(/\d/)
				if column_has_digit and not last_column_had_digit
					@positions.push column
				last_column_had_digit = column_has_digit
				column++
			
			return
		
		# The following is based on the default multi-selection block selection code:
		# https://github.com/ajaxorg/ace/blob/master/lib/ace/mouse/multi_select_handler.js
		# @TODO: move this somewhere? there's more interesting code after it
		
		isSamePoint = (p1, p2)->
			p1.row is p2.row and p1.column is p2.column
		
		rectSel = []
		
		{selection} = @editor
		
		@editor.on "mousedown", (e)=>
			button = e.getButton()
			return unless button is 0 and @multi_row_selection_mode
			
			return if lines_are_uneven(get_lines())
			
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
				return

			
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
				return

			onSelectionInterval = blockSelect

			event.capture(@editor.container, onMouseSelection, onMouseSelectionEnd)
			timerId = setInterval(onSelectionInterval, 20)

			e.preventDefault()
			return
	
	showPlayingNote: (pos, note)->
		@removePlayingNote(pos, note)
		key = "#{note.s}:#{pos}"
		
		column = @positions[pos]
		
		range = new Range(note.s, column, note.s, column+1)
		marker = @editor.getSession().addMarker(range, "playing-note", "text") # text?
		@playing_note_highlight_markers[key] = marker
		return
	
	removePlayingNote: (pos, note)->
		key = "#{note.s}:#{pos}"
		existing_marker = @playing_note_highlight_markers[key]
		@editor.getSession().removeMarker existing_marker if existing_marker
		return
	
	showPlaybackPosition: (pos)->
		column = @positions[pos]
		
		@hidePlaybackPosition()
		
		@column_highlight_markers =
			for i in [0..6]
				range = new Range(i, column-1, i, column)
				marker = @editor.getSession().addMarker(range, "playback-position", "text") # text?
				marker
		
		# @TODO: scroll the playback position into view
		# @editor.revealRange range
		# pageX_1 = @editor.renderer.textToScreenCoordinates(0, 0).pageX
		# pageX_2 = @editor.renderer.textToScreenCoordinates(column, 0).pageX
		# console.log pageX_1, pageX_2
		# delta_pageX = pageX_2 - pageX_1
		# @editor.renderer.scrollToX column * delta_pageX
		# @editor.renderer.scrollToX column * 7
		return
	
	hidePlaybackPosition: ->
		for marker in @column_highlight_markers
			@editor.getSession().removeMarker marker
		
		@column_highlight_markers = []
		return
