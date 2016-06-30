
Guitar
======

It's a virtual guitar record-a-synthesize-amatronic web application.

You can copy and paste entire webpages containing guitar tabs and it'll try to load all it can.

Uses [tuna][] audio effects library.
The guitar synthesis algorithm is from [guitar-synth](https://github.com/getinstinct/guitar-synth).

The tablature parser is available as separately as a module [here][tablature-parser].


## TODO

* Better mobile support

    - Play back recorded notes with a button
    
    - Multitouch

* Make web application self-explanatory and test accessibility

* Make bending (MMB) less ridiculous

* Maybe add scale highlighting like I did with [Tri-Chromatic Keyboard][]

* Record chords
  (with multitouch or a modifier key, maybe also have some sort of toggle)

* Record, parse, and play back articulations
  such as slides, bends, vibratos, hammer-ons, and pull-offs

* Different sound for sliding than for pressing

* Support for different tunings

* Allow configuring the effects chain
  (at least toggle distortion on/off)

* Include demo tabs (probably in a dropdown)

* Tablature editor
    
    - Scroll with the playback position
    
    - Make the playback position indicator different while playing
    
    - Handle multi-digit numbers when highlighting stuff
    
    - Set the position in the song when you click in the tablature editor
    
    - Insert and overwrite notes with the guitar
    
    - Shift+click to select
    
    - Disable or override double-click and triple-click
    
    - Toggle custom selection behavior
    
    - Maybe have a button to toggle insert/overwrite too
    
    - Custom syntax highlighting
        
        + Highlight tablature with articulations and everything
        
        + Highlight `<<` misalignment markers as erroneous
    
    - Why does the selection style change on mouseup?
    
    - Maybe add some padding with `renderer.setPadding`?

* MusicXML? MIDI?


[tuna]: https://github.com/Dinahmoe/tuna
[tablature-parser]: https://github.com/1j01/tablature-parser
[Tri-Chromatic Keyboard]: https://github.com/1j01/tri-chromatic-keyboard
