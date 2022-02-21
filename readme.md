# Mandlebrot Fractal Engine - FPGA
![Image](/doc/FractalFront.gif)

*Migrated to Git on February 20th, 2022. Original release November 13th, 2020.*

A fractal is a recursive geometric pattern: think of a triangle inside of a triangle inside of a
triangle. If you're familiar with fractals, you've probably already seen the Mandlebrot fractal.
It's a fractal that is described purely by a simple math equation. Images like the one shown below
can be easily generated by just adding, multiplying, and comparing complex numbers.

| *Sierpinksi Triangle Fractal* | *Mandlebrot Set Fractal*      |
| ----------------------------- | ----------------------------- |
| ![Image](/doc/TriFractal.png) | ![Image](/doc/mandlebrot.jpg) |




Implementing the Mandlebrot fractal can be a good project for experimenting with any technical
platform. I decided that writing a Mandlebrot fractal generator purely on an FPGA sounded fun: it
could give the opportunity to fully utilize the hardware and optimize for the highest frequency
possible. But what started as a goal to learn pipelining, timing analysis techniques, and HDMI
interfaces turned into a stubborn nightmare of fighting with a cheap FPGA. This project took place
mainly between July and August of 2020.  

## Demonstration
CTRL+click the video thumbnails to open in a new tab

| Youtube Videos |
| :--: |
| *Mandlebrot Fractal on FPGA* |
| [![Image](/doc/vid01_tb.png)](https://youtu.be/olNmJYW6uFA) |

## Implementation

### The Mandlebrot Fractal

The Mandlebrot set is described by a single math equation:
<p align="center" class="font-weight-bold">Z<sub>n+1</sub> = Z<sub>n</sub><sup>2</sup> + C, while Z &lt; R&nbsp;</p>

In the equation above, Z and C are complex numbers, and R is a real number. For the Mandlebrot set:
Z is intialized to zero, and C is always the coordinate in the complex plane (AKA: the pixel on the
screen). The equation is evaluated iteratively until Z is greater than an escape radius R, which can
be any number.  The square and the sum are calculated over and over again until Z is greater than or
equal to R. At that point we note how many times we iterated through the equation, we say that the
coordinate is not part of the Mandlebrot set, and we move onto the next coordinate. On the screen,
this pixel would receive color based on the number of iterations.

The problem with this process is that there is an infinite amount of detail in the Mandlebrot set.
Some coordinates will require an infinite amount of iterations, so we have to limit it somehow for a
real-time implementation. To do this, we pick a maximum bailout number: if the value of n above
exceeds this number, we break out of the calculation loop, and we say that the coordinate belongs to
the Mandlebrot set. On the screen, this pixel would be colored black. 

Although this is a simple equation, there is infinite room for improvement by increasing this
maximum bailout number. It can be fun to try and rewrite your code to increase this number further
and further. The higher the maximum bailout number, the better the detail in the output of your
fractal engine.

Notice the detail in the images below for the same portion of the Mandlebrot set but with different
maximum iterations. The center coordinate for the images was -1.42 + 0j, the vertical width was
0.28, and the horizontal width was 1.00

| Bailout = 20 | Bailout = 40     | Bailout = 200 |
| ----------------------------- | ----------------------------- |
| ![Image](/doc/20_iter.png) | ![Image](/doc/40_iter.png) | ![Image](/doc/200_iter.png) |

### Learning Goals

### Project Specifications

### Fractal Math

### Fractal Engine Design

### Hardware Design

#### VIO

#### Fractal Screen Generator

#### Fractal Coordinate Generator

#### Fractal Core

#### Fractal Smooth Counter

#### Video Blanking Extender

#### Color LUT

#### Gaussian Blur (2D Convolution)

#### Video Sync Generator

#### TMDS Encoder and OSERDES

### Hardware Troubles

### Project Finish

## References
