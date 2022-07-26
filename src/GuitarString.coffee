
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
		
		@node = new AudioWorkletNode(actx, "white-noise-processor", {processorOptions: {baseNote: @base_note_str}})
		@node.connect(pre)

		@data = [0]
		
		@started = no
		@playing = no
		
		@freq = @base_freq
		@fret = 0
	
	getSampleData: ->
		return 0 unless @started

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

		return @current
	
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
		@N = Math.round(actx.sampleRate / @freq)
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
	
	bend: (bend)->
		# FIXME/TODO: should be a smooth glissando
		# maybe make the @period the max that it needs to be (either in general for all time, or during a transition)
		# and transition between treating it one length to a new length?
		note_n = @base_note_n + @fret
		@setFrequency(getFrequency(note_n) + bend, note_n)
		return
	
	release: ->
		@playing = no
	
	stop: ->
		@playing = no
		@started = no


if registerProcessor?
	class WhiteNoiseProcessor extends AudioWorkletProcessor
		process: (inputs, outputs, parameters) ->
			output = outputs[0]
			for channel in output
				for i in [0..channel.length]
					channel[i] = Math.random() * 2 - 1
			return true

	registerProcessor('white-noise-processor', WhiteNoiseProcessor)
else
	@GuitarString = GuitarString

# class GuitarStringProcessor extends AudioWorkletProcessor