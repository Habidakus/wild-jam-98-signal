Wild Frogs - Kelano Studio

8 frogs, 12 animations each.

sprites/        32x32 static sprites, feet on the bottom row
animations/     one horizontal strip per animation, 48x48 frames, feet on the bottom row of every frame
sheets/         one sheet per frog, one animation per row (order below)
preview_gifs/   4x previews
frame_data.json frame counts and timing in milliseconds

Animations (frames, total length):
  idle      9 frames  1110 ms
  sleep     8 frames  1760 ms
  croak    10 frames  890 ms
  tongue    8 frames  550 ms
  hop       5 frames  310 ms
  spawn     7 frames  640 ms
  despawn   9 frames  900 ms
  bubble   12 frames  1250 ms
  sing      9 frames  850 ms
  startle   8 frames  830 ms
  happy     8 frames  650 ms
  jump      8 frames  660 ms

Loops: idle, sleep, hop, sing. One-shots: croak, tongue, spawn, despawn, bubble, startle, happy, jump.
The 32x32 sprite sits at x=11, y=16 inside each 48x48 frame.
