
Guitar
======

It's a virtual guitar record-a-synthsize-amatronic web application.

You can copy and paste entire webpages containing guitar tabs and it'll try to load all it can.

Uses [tuna][] audio effects library.

The tablature parser is available as separately as a module [here][tablature-parser].


## TODO

* Re-implement tab stringification

* FIXME: first note clicked is played as if it were open
  (but recorded normally)

* Better mobile support
  (You can't even play back notes!)

* Self-explanatory web application

* Record chords
  (with multitouch or a modifier key, maybe also have some toggle)

* Record, parse, and playback articulations
  such as slides, bends, vibratos, hammer-ons, and pull-offs

* Support for different tunings

* Improve synth

    - Try to make it actually sound like a guitar
    
    - Fade out a master gain to zero after a period of inactivity
      so the "tab is playing audio" icon can go away

    - Find a better way to fade out
      (that doesn't end abruptly especially when amplified)

    - Allow configuring the effects chain
      (at least toggle distortion on/off)

* Tablature view that isn't just a text area
  (show current song position, allow block-level editing)

* Stretch guitar up to the point of a realistic scale
  and then center it
  (currently it's squished)


[tuna]: https://github.com/Dinahmoe/tuna
[tablature-parser]: https://github.com/1j01/tablature-parser
