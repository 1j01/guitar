
@actx = if AudioContext? then new AudioContext else new webkitAudioContext
tuna = new Tuna(actx)

connect = (nodes...)->
	for node, i in nodes when next = nodes[i+1]
		node.connect next.input ? next.destination ? next

# # # # # # # # # # # #

@pre = actx.createGain()
pre.gain.value = 0.2 # guitar volume
@post = actx.createGain()
post.gain.value = 0.3 # master volume

# slap = new SlapbackDelay()

drive = new tuna.Overdrive
	outputGain: 0.5          # 0 to 1+
	drive: 0.7               # 0 to 1
	curveAmount: 1           # 0 to 1
	algorithmIndex: 0        # 0 to 5, selects one of the drive algorithms
	bypass: 0

wahwah = new tuna.WahWah
	automode: off                # on/off
	baseFrequency: 0.5           # 0 to 1
	excursionOctaves: 1          # 1 to 6
	sweep: 0.2                   # 0 to 1
	resonance: 2                 # 1 to 100
	sensitivity: 0.3             # -1 to 1
	bypass: 0

phaser = new tuna.Phaser
	rate: 1.2                      # 0.01 to 8 is a decent range, but higher values are possible
	depth: 0.3                     # 0 to 1
	feedback: 0.9                  # 0 to 1+
	stereoPhase: 30                # 0 to 180
	baseModulationFrequency: 700   # 500 to 1500
	bypass: 0

chorus = new tuna.Chorus
	rate: 1.5          # 0.01 to 8+
	feedback: 0.2      # 0 to 1+
	delay: 0.0045      # 0 to 1
	bypass: 0

###
tremolo = new tuna.Tremolo
	intensity: 1        # 0 to 1
	rate: 0.01          # 0.001 to 8
	stereoPhase: 50     # 0 to 180
	bypass: 0

###
###
convolver = new tuna.Convolver
	highCut: 22050                          # 20 to 22050
	lowCut: 20                              # 20 to 22050
	dryLevel: 1                             # 0 to 1+
	wetLevel: 1                             # 0 to 1+
	level: 1                                # 0 to 1+, adjusts total output of both wet and dry
	impulse: "impulses/impulse_guitar.wav"     # the path to your impulse response
	bypass: 0

###

###
noiseConvolver = do ->
	convolver = actx.createConvolver()
	noiseBuffer = actx.createBuffer(2, 0.5 * actx.sampleRate, actx.sampleRate)
	left = noiseBuffer.getChannelData(0)
	right = noiseBuffer.getChannelData(1)
	for i in [0..noiseBuffer.length]
		left[i] = Math.random() * 2 - 1
		right[i] = Math.random() * 2 - 1
	
	convolver.buffer = noiseBuffer
	convolver
###

# connect pre, wahwah, phaser, drive, chorus, post
connect pre, wahwah, chorus, post

splitter = actx.createChannelSplitter(2)
merger = actx.createChannelMerger(2)
post.connect(splitter)
splitter.connect(merger)
merger.connect(actx.destination)
# merger = actx.createChannelMerger(2)
# post.connect(merger, 0, 0)
# post.connect(merger, 0, 1)
# merger.connect(actx.destination)

