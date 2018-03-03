
class @CircularTransitionEffect
	constructor: (@container)->
		@container ?= document.createElement("div")
		@container.classList.add("circular-transition-effect-container")
		@_transitions = []
		# @_animationFrameID = null
		# @_time = performance.now() / 1000

	animate: =>
		previousTime = @_time
		@_time = performance.now() / 1000
		deltaTime = @_time - previousTime

		shouldContinueAnimating = no
		for transition in @_transitions
			{element, circleX, circleY, radiusSpeedPercentPerSecond} = transition
			transition.sizePercent += radiusSpeedPercentPerSecond * deltaTime
			
			element.style.clipPath =
				"circle(#{transition.sizePercent}% at #{circleX}px #{circleY}px)"
			
			# console.log "transition.sizePercent", transition.sizePercent

			if transition.sizePercent <= 150
				shouldContinueAnimating = yes
			# else
				# TODO: remove any elements beneath that are done (not animating)
				# (we could remove the animationFrameID prop when its done and use the existence of that)
		
		# console.log "shouldContinueAnimating", shouldContinueAnimating

		if shouldContinueAnimating
			@_animationFrameID = requestAnimationFrame @animate
		else
			@_animationFrameID = null

	endTransition: =>
		# cancelAnimationFrame @_animationFrameID
		# @_animationFrameID = null

	transitionTo: (element, circleX, circleY, radiusSpeedPercentPerSecond)=>

		for transition, index in @_transitions
			if transition.element is element
				@_transitions.splice(index, 1)
				@endTransition(transition)

		@container.appendChild element

		@_transitions.push({element, circleX, circleY, radiusSpeedPercentPerSecond, sizePercent: 0})
		
		unless @_animationFrameID?
			@_time = performance.now() / 1000
			@animate()

### Example:

effect = new CircularTransitionEffect(container)

currentImgIndex = 0

effect.container.onmousedown = (e)->
	e.preventDefault()

	img = imgs[currentImgIndex]
	
	effect.transitionTo(img, e.offsetX, e.offsetY, 400)

	currentImgIndex = (currentImgIndex + 1) % imgs.length

###
