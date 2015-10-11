
sustain = off # @FIXME (or remove me)

class @GuitarString
	constructor: (@notestr)->
		@text = @notestr[0]
		@basenoten = getNoteN(@notestr)
		@basefreq = getFrequency(@basenoten)
		
		@volume = actx.createGain()
		@volume.gain.value = 0.0
		@volume.connect(pre)
		
		@osc = actx.createOscillator()
		@osc.frequency.value = @basefreq
		# @osc.type = "" # sine, square, sawtooth, triangle
		
		# let's make a custom wavetable...
		curveLength = 10
		curve1 = new Float32Array(curveLength)
		curve2 = new Float32Array(curveLength)
		f = 1 # "frequency" ...
		for i in [0..curveLength]
			curve2[i] = cos(tau / 2 * i / curveLength/20)
			curve1[i] = sin(tau / 2 * i / curveLength/20)
			# t = i/10
			# curve1[i] = (sin( 1.26*f/2 * tau*t ) ** 15) * ((1-t) ** 3) * (sin( 1.26*f/10 * tau*t ) ** 3) * 10
			# curve1[i] = (sin( 1.26*f/2 * tau*t ) ** 15) * ((1-t) ** 3) * (sin( 1.26*f/10 * tau*t ) ** 3) * 10
		
		# waveTable = actx.createWaveTable(curve1, curve2)
		# osc.setWaveTable(waveTable)
		waveTable = actx.createPeriodicWave(curve1, curve2)
		@osc.setPeriodicWave(waveTable)
		
		@osc.connect(@volume)
		@osc.start(0)
		
		@attack = 0.0 # this attack doesn't work, just makes it slow. @TODO
		@freq = @basefreq
		@fret = 0
	
	play: (@fret)->
		noten = @basenoten + @fret
		now = actx.currentTime
		@freq = getFrequency(noten)
		@osc.frequency.exponentialRampToValueAtTime(@freq, now+0.001)
		@volume.gain.cancelScheduledValues(now)
		@volume.gain.linearRampToValueAtTime(1.50,now+@attack)
		@volume.gain.exponentialRampToValueAtTime(0.50,now+@attack+0.29)
		# @volume.gain.linearRampToValueAtTime(0.004,now+@attack+1.00)
		@volume.gain.linearRampToValueAtTime(0.00,now+@attack+4.00)
		noten
	
	bend: (bend)->
		noten = @basenoten + @fret
		now = actx.currentTime
		@freq = getFrequency(noten) + bend
		@osc.frequency.linearRampToValueAtTime(@freq, now)
		noten
	
	release: ->
		now = actx.currentTime
		@volume.gain.linearRampToValueAtTime(0.0,now+0.33+(sustain*1))
	
	stop: ->
		now = actx.currentTime
		@volume.gain.cancelScheduledValues(now)
		@volume.gain.linearRampToValueAtTime(0.0,now+0.5)
		@osc.frequency.linearRampToValueAtTime(@freq/50, now+0.4)
