
class @CircularTransitionEffect
	constructor: (@container)->
		@container ?= document.createElement("div")
		@container.classList.add("circular-transition-effect-container")
		# @imgs = []
		# @transitions = []

	transitionTo: (element, circleX, circleY, radiusSpeedPercentPerSecond)->
		@container.appendChild element

		time = Date.now() / 1000
		# @transitions.push({element, circleX, circleY, radiusSpeedPercentPerSecond, time})

		sizePercent = 0
		
		# TODO: use a single requestAnimationFrame loop for all active animations
		
		animate = ->
			previousTime = time
			time = Date.now() / 1000
			deltaTime = time - previousTime
			sizePercent += radiusSpeedPercentPerSecond * deltaTime
			
			element.style.clipPath =
				"circle(#{sizePercent}% at #{circleX}px #{circleY}px)"
			# console.log "circle(#{sizePercent}% at #{circleX}px #{circleY}px)"
			
			if sizePercent <= 150
				element.animationFrameID = requestAnimationFrame animate
			# else
				# TODO: remove any elements beneath that are done (not animating)
				# (we could remove the animationFrameID prop when its done and use the existence of that)
		
		cancelAnimationFrame element.animationFrameID
		animate()

### Example:

effect = new CircularTransitionEffect(container)

currentImgIndex = 0

effect.container.onmousedown = (e)->
	e.preventDefault()

	img = imgs[currentImgIndex]
	
	effect.transitionTo(img, e.offsetX, e.offsetY, 400)

	currentImgIndex = (currentImgIndex + 1) % imgs.length

###
