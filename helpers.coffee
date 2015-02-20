
{@abs, @sin, @cos} = Math
@tau = 2*Math.PI

notes = ['A', 'A#', 'B', 'C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#']

@getFrequency = (noten)->
	440 * 2 ** ((noten - 49) / notes.length)

@getNoteN = (notestr)->
	i = notes.indexOf notestr[0...-1]
	octave = parseInt notestr[-1..]
	octave -= 1 if i >= notes.indexOf 'C'
	octave * notes.length + i + 1

