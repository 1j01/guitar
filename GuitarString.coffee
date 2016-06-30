
sustain = off # @FIXME (or remove me)
DECAY_CONSTANT = 0.00001
NO_SOUND_THRESHOLD = 0.1

class @GuitarString
	constructor: (@base_note_str)->
		@label = @base_note_str[0]
		@base_note_n = getNoteN(@base_note_str)
		@base_freq = getFrequency(@base_note_n)
		
		# @volume = actx.createGain()
		# @volume.gain.value = 0.0
		# @volume.connect(pre)
		
		# @osc = actx.createOscillator()
		# @osc.frequency.setValueAtTime(@base_freq, 0)
		# @osc.type = "sine" # sine, square, sawtooth, triangle
		# 
		# # let's make a custom wavetable...
		# # curveLength = 10
		# # curve1 = new Float32Array(curveLength)
		# # curve2 = new Float32Array(curveLength)
		# # f = 1 # "frequency" ...
		# # for i in [0..curveLength]
		# # 	curve2[i] = cos(tau / 2 * i / curveLength/20)
		# # 	curve1[i] = sin(tau / 2 * i / curveLength/20)
		# # 	# t = i/10
		# # 	# curve1[i] = (sin( 1.26*f/2 * tau*t ) ** 15) * ((1-t) ** 3) * (sin( 1.26*f/10 * tau*t ) ** 3) * 10
		# # 	# curve1[i] = (sin( 1.26*f/2 * tau*t ) ** 15) * ((1-t) ** 3) * (sin( 1.26*f/10 * tau*t ) ** 3) * 10
		# 
		# # waveTable = actx.createWaveTable(curve1, curve2)
		# # osc.setWaveTable(waveTable)
		# # waveTable = actx.createPeriodicWave(curve1, curve2)
		# # @osc.setPeriodicWave(waveTable)
		# 
		# @osc.connect(@volume)
		# @osc.start(0)
		# 
		# @attack = 0 # this attack doesn't work, just makes it slow. @TODO
		
		@script_processor = actx.createScriptProcessor(1024, 1, 1)
		@script_processor.onaudioprocess = (e)=>
			data = e.outputBuffer.getChannelData(0)
			for i in [0..data.length]
				data[i] = @getSampleData()
		# @script_processor.connect(actx.destination)
		@script_processor.connect(pre)
		
		@started = no
		@playing = no
		
		@freq = @base_freq
		@fret = 0
		
		@attack = 0 # TODO
	
	getSampleData: ->
		unless @started
			return 0

		if @periodIndex is @N
			@periodIndex = 0

		if @cumulativeIndex < @N
			@period[@periodIndex] += (Math.random() - Math.random()) / 4

		@current += (@period[@periodIndex] - @current) * @decay
		@period[@periodIndex] = @current

		++@periodIndex
		++@cumulativeIndex

		# @decay *= DECAY_CONSTANT
		@decay *= if @playing then (1 - DECAY_CONSTANT) else (1 - DECAY_CONSTANT * 20)

		# if @decay < NO_SOUND_THRESHOLD
		# 	@stop()

		return @current
	
	play: (@fret)->
		note_n = @base_note_n + @fret
		# now = actx.currentTime
		@freq = getFrequency(note_n)
		# @osc.frequency.exponentialRampToValueAtTime(@freq, now+0.001)
		
		@N = Math.round(actx.sampleRate / @freq)
		@period = new Float32Array(@N)
		@periodIndex = 0
		@cumulativeIndex = 0
		@decay = (note_n / 80) + .1
		@current = 0
		@started = yes
		@playing = yes
		
		# @volume.gain.cancelScheduledValues(now)
		# # @volume.gain.linearRampToValueAtTime(0.01,now+0.001)
		# @volume.gain.linearRampToValueAtTime(1.50,now+@attack)
		# @volume.gain.exponentialRampToValueAtTime(0.50,now+@attack+0.29)
		# # @volume.gain.linearRampToValueAtTime(0.004,now+@attack+1.00)
		# @volume.gain.linearRampToValueAtTime(0.00,now+@attack+4.00)
		note_n
	
	bend: (bend)->
		note_n = @base_note_n + @fret
		# now = actx.currentTime
		@freq = getFrequency(note_n) + bend
		# @osc.frequency.linearRampToValueAtTime(@freq, now)
		note_n
	
	release: ->
		# now = actx.currentTime
		@playing = no
		# @volume.gain.linearRampToValueAtTime(0.0,now+0.33+(sustain*1))
	
	stop: ->
		# now = actx.currentTime
		# @volume.gain.cancelScheduledValues(now)
		# @volume.gain.linearRampToValueAtTime(0.0,now+0.5)
		# @osc.frequency.linearRampToValueAtTime(@freq/50, now+0.4)
		@playing = no
		@started = no
