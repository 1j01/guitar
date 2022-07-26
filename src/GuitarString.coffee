
PLAYING_DECAY = 0.00001
RELEASED_DECAY = PLAYING_DECAY * 20

notes = ['A', 'A#', 'B', 'C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#']

getFrequency = (noteN)->
	440 * 2 ** ((noteN - 49) / notes.length)

getNoteN = (noteStr)->
	i = notes.indexOf noteStr[0...-1]
	octave = parseInt noteStr[-1..]
	octave -= 1 if i >= notes.indexOf 'C'
	octave * notes.length + i + 1

# PLAYING_DECAY = 0.1
# RELEASED_DECAY = 0.8

class GuitarString
	constructor: (@base_note_str)->
		@label = @base_note_str[0]
		@base_note_n = getNoteN(@base_note_str)
		@base_freq = getFrequency(@base_note_n)
		
		@node = new AudioWorkletNode(actx, "guitar-string-processor", {processorOptions: {baseNote: @base_note_str}})
		@node.connect(pre)

		@data = [0]
		
		@started = no
		@playing = no
		
		@freq = @base_freq
		@fret = 0
	
	play: (@fret)->
		note_n = @base_note_n + @fret
		@decay = (note_n / 80) + 0.1
		@setFrequency(getFrequency(note_n), note_n)
		@node.parameters.get("fret").value = @fret
		@node.parameters.get("playing").value = 1
		return
	
	setFrequency: (freq)->
		# @node.parameters.get("frequency").value = freq
	
	bend: (bend)->
		# FIXME/TODO: should be a smooth glissando
		# maybe make the @period the max that it needs to be (either in general for all time, or during a transition)
		# and transition between treating it one length to a new length?
		note_n = @base_note_n + @fret
		@setFrequency(getFrequency(note_n) + bend, note_n)
		return
	
	release: ->
		@playing = no
		@node.parameters.get("playing").value = 0
	
	stop: ->
		@playing = no
		@started = no
		@node.parameters.get("playing").value = 0


if registerProcessor?
	class GuitarStringProcessor extends AudioWorkletProcessor
		@parameterDescriptors = [
			# {
			# 	name: "baseNote"
			# 	defaultValue: "A4"
			# 	automatable: false
			# 	type: "string"
			# }
			{
				name: "pitchBend"
				defaultValue: 0
				automatable: true
				type: "number"
			}
			{
				name: "fret"
				defaultValue: 0
				minValue: 0
				maxValue: 100
				automatable: true
				type: "number"
			}
			{
				name: "playing"
				defaultValue: 0.5
				minValue: 0
				maxValue: 1
				automatable: true
				type: "number"
			}
		]

		constructor: ({processorOptions})->
			super()
			@base_note_str = processorOptions.baseNote
			@base_note_n = getNoteN(@base_note_str)
			@base_freq = getFrequency(@base_note_n)
			
			@data = [0]
			
			@started = no
			@playing = no
			
			@freq = @base_freq
			@fret = 0
			# to init some stuff like periodIndex
			@setFrequency(@base_freq)
			@play(0)
			@decay = 0
			@playing = no
			@started = no

		process: (inputs, outputs, parameters) ->
			output = outputs[0]
			if parameters.playing > 0.5 and not @playing
				# TODO: handle buffer better; for now, take the latest sample
				@play(parameters.fret[parameters.fret.length - 1])
			# console.log "playing", @playing, parameters.playing
			for channel in output
				for i in [0..channel.length]
					channel[i] = @nextSample()
			return true

		play: (@fret)->
			note_n = @base_note_n + @fret
			@started = yes
			@playing = yes
			@periodIndex = 0
			@cumulativeIndex = 0
			@decay = (note_n / 80) + 0.1
			@current = 0
			@setFrequency(getFrequency(note_n), note_n)
			return
		
		setFrequency: (freq)->
			@freq = freq
			@N = Math.round(sampleRate / @freq)
			unless @period?.length is @N
				old_period = @period
				@period = new Float32Array(@N)
				@periodIndex %= @N #+ 1
				@cumulativeIndex %= @N #+ 1
				# @periodIndex = 0
				# @cumulativeIndex = 0
				if old_period?
					@period.set(old_period.subarray(0, @N))
			# @decay = (note_n / 80) + 0.1
			# @current = 0
			return
		
		nextSample: ->
			if @periodIndex is @N
				@periodIndex = 0

			if @cumulativeIndex < @N
				@period[@periodIndex] += (Math.random() - Math.random()) / 4

			@current += (@period[@periodIndex] - @current) * @decay
			@period[@periodIndex] = @current
			# @period[@periodIndex] = @current * (1 - @decay * Math.random())
			# @period[@periodIndex] = @current * (1 - @decay/5 * Math.random())
			# @period[@periodIndex] = if Math.random() < 0.5 then @current else -@current

			++@periodIndex
			++@cumulativeIndex

			@decay *= if @playing then (1 - PLAYING_DECAY) else (1 - RELEASED_DECAY)
			# @decay = if @playing then (1 - PLAYING_DECAY) else (1 - RELEASED_DECAY)

			unless isFinite @current
				throw new Error("@current is #{@current}")
			
			return @current
		

	registerProcessor('guitar-string-processor', GuitarStringProcessor)
else
	@GuitarString = GuitarString

# class GuitarStringProcessor extends AudioWorkletProcessor