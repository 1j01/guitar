
{Range} = ace.require 'ace/range'

class @TablatureEditor
	constructor: (element)->
		
		@editor = ace.edit(element)
		@editor.getSession().setMode 'ace/mode/ocaml'
		@editor.setOption 'highlightActiveLine', off
		@editor.setOption 'showPrintMargin', off
		@editor.setOption 'showGutter', off
		
		# console.log @editor.keyBinding, @editor.commands
		
		# @editor.commands.addCommand
		# 	name: "tab"
		# 	bindKey: "Shift-Tab|Tab" # {win: "Tab", mac: "Tab"}
		# 	command: "passKeysToBrowser"
		# 	exec: ->
		
		@editor.commands.bindKey 'Tab', null
		@editor.commands.bindKey 'Shift-Tab', null
		
		# tuning = "eBGDAE"
		
		# @editor.session.gutterRenderer =
		# 	getWidth: (session, lastLineNumber, config)->
		# 		config.characterWidth
		# 	getText: (session, row)->
		# 		tuning[row] ? ""
		
		@multi_selection = null
		
		# @select 15, 50
		
		@editor.on 'changeSelection', (e)=>
			# console.log @editor.selection
			# console.log @editor.getSelectionRange()
			# console.log window.e = e
			# e.preventDefault()
			# @editor.selection.setSelectionRange
			# 	start:
			# 		row: 0
			# 		column: 0
			# 	end:
			# 		row: 0
			# 		column: 0
		
	select: (columnStart, columnEnd) ->
		if @multi_selection
			i = 0
			while i < @multi_selection.length
				@editor.getSession().removeMarker @multi_selection[i].markerId
				i++
		
		@multi_selection =
			for i in [0..6]
				range = new Range(i, columnStart, i, columnEnd)
				marker = @editor.addSelectionMarker(range)
				marker
