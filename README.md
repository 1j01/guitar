
Guitar
======

It's a virtual guitar record-a-synthsize-amatronic web application.

You can copy and paste entire webpages containing guitar tabs and it'll try to load all it can.

Uses [tuna][] audio effects library.

The tablature parser is available as separately as a module [here][tablature-parser].


## TODO

* Better mobile support
  (You can't even play back recorded notes!)

* Make web application self-explanatory

* Make bending (MMB) less ridiculous

* Maybe add scale highlighting like I did with [Tri-Chromatic Keyboard][]

* Record chords
  (with multitouch or a modifier key, maybe also have some sort of toggle)

* Record, parse, and play back articulations
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
[Tri-Chromatic Keyboard]: https://github.com/1j01/tri-chromatic-keyboard
