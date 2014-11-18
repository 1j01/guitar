(function (Context) {
    var isFunction = function (f) {
            return Object.prototype.toString.call(f) === "[object Function]" ||
                Object.prototype.toString.call(f) === "[object AudioContextConstructor]";
        },
        contextMethods = [
            ["createGainNode", "createGain"],
            ["createDelayNode", "createDelay"],
            ["createJavaScriptNode", "createScriptProcessor"]
        ],
        proto,
        instance,
        sourceProto;

    if (!isFunction(Context)) {
        return;
    }
    instance = new Context();
    if (!instance.destination || !instance.sampleRate) {
        return;
    }
    proto = Context.prototype;
    sourceProto = Object.getPrototypeOf(instance.createBufferSource());

    if (!isFunction(sourceProto.start)) {
        if (isFunction(sourceProto.noteOn)) {
            sourceProto.start = function (when, offset, duration) {
                switch (arguments.length) {
                    case 0:
                        throw new Error("Not enough arguments.");
                    case 1:
                        this.noteOn(when);
                        break;
                    case 2:
                        if (this.buffer) {
                            this.noteGrainOn(when, offset, this.buffer.duration - offset);
                        } else {
                            throw new Error("Missing AudioBuffer");
                        }
                        break;
                    case 3:
                        this.noteGrainOn(when, offset, duration);
                }
            };
        }
    }

    if (!isFunction(sourceProto.noteOn)) {
        sourceProto.noteOn = sourceProto.start;
    }

    if (!isFunction(sourceProto.noteGrainOn)) {
        sourceProto.noteGrainOn = sourceProto.start;
    }

    if (!isFunction(sourceProto.stop)) {
        sourceProto.stop = sourceProto.noteOff;
    }

    if (!isFunction(sourceProto.noteOff)) {
        sourceProto.noteOff = sourceProto.stop;
    }

    contextMethods.forEach(function (names) {
        var name,
            name2;
        while (names.length) {
            name = names.pop();
            if (isFunction(this[name])) {
                this[names.pop()] = this[name];
            } else {
                name2 = names.pop();
                this[name] = this[name2];
            }
        }
    }, proto);
})(this.webkitAudioContext || this.AudioContext);