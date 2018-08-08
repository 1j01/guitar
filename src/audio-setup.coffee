
@actx = new AudioContext
tuna = new Tuna(actx)

connect = (nodes...)->
	for node, i in nodes when next = nodes[i+1]
		node.connect next.input ? next.destination ? next
	return

# # # # # # # # # # # #

@pre = actx.createGain()
pre.gain.value = 0.2 # guitar volume
@post = actx.createGain()
post.gain.value = 1 # master volume

# slap = new SlapbackDelay()

drive = new tuna.Overdrive
	outputGain: 0.5          # 0 to 1+
	drive: 0.1               # 0 to 1
	curveAmount: 0.6         # 0 to 1
	algorithmIndex: 2        # 0 to 5, selects one of the drive algorithms
	bypass: 1

wahwah = new tuna.WahWah
	automode: off                # on/off
	baseFrequency: 0.4           # 0 to 1
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
	bypass: 1

chorus = new tuna.Chorus
	rate: 1.5          # 0.01 to 8+
	feedback: 0.2      # 0 to 1+
	delay: 0.0045      # 0 to 1
	bypass: 1

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

cabinet = new tuna.Cabinet
	makeupGain: 1                                 # 0 to 20
	impulsePath: "impulses/impulse_guitar.wav"    # path to your speaker impulse
	bypass: 0


# noiseConvolver = do ->
# 	convolver = actx.createConvolver()
# 	noiseBuffer = actx.createBuffer(2, 0.5 * actx.sampleRate, actx.sampleRate)
# 	left = noiseBuffer.getChannelData(0)
# 	right = noiseBuffer.getChannelData(1)
# 	for i in [0..noiseBuffer.length]
# 		# left[i] = Math.random() * 2 - 1 + Math.sin(i/noiseBuffer.length*3)
# 		# right[i] = Math.random() * 2 - 1 + Math.cos(i/noiseBuffer.length*3)
# 		left[i] = Math.sin(i/noiseBuffer.length*2600)
# 		right[i] = Math.sin(i/noiseBuffer.length*2600)
# 		# left[i] = Math.sin(i/actx.sampleRate*440*4) * 3 / noiseBuffer.length
# 		# right[i] = Math.cos(i/actx.sampleRate*440*4) * 3 / noiseBuffer.length
# 		# left[i] = Math.sin(i*i/5000) * 3 / noiseBuffer.length
# 		# right[i] = Math.cos(i*i/5000) * 3 / noiseBuffer.length
# 		# left[i] = #Math.sin(i/44)
# 		# right[i] = #Math.cos(i/44)
# 	
# 	convolver.buffer = noiseBuffer
# 	convolver

# connect pre, wahwah, phaser, drive, chorus, post

connect pre, chorus, wahwah, drive, cabinet, post
# connect pre, chorus, drive, noiseConvolver, cabinet, post

# allow clean sound straight through to the speaker
#connect chorus, cabinet/post?


# splitter = actx.createChannelSplitter(2)
# merger = actx.createChannelMerger(2)
# post.connect(splitter)
# splitter.connect(merger)
# merger.connect(actx.destination)

merger = actx.createChannelMerger(2)
post.connect(merger, 0, 0)
post.connect(merger, 0, 1)
merger.connect(actx.destination)

