
{@abs, @sin, @cos} = Math
@tau = 2*Math.PI

notes = ['A', 'A#', 'B', 'C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#']

@getFrequency = (noteN)->
	440 * 2 ** ((noteN - 49) / notes.length)

@getNoteN = (noteStr)->
	i = notes.indexOf noteStr[0...-1]
	octave = parseInt noteStr[-1..]
	octave -= 1 if i >= notes.indexOf 'C'
	octave * notes.length + i + 1

