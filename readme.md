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

| Bailout = 20               | Bailout = 40               | Bailout = 200               |
| -------------------------- | -------------------------- | --------------------------- |
| ![Image](/doc/20_iter.png) | ![Image](/doc/40_iter.png) | ![Image](/doc/200_iter.png) |

### Learning Goals

Here is what I wanted to learn about over the course of the project: 
1. Static Timing Analysis
    - In order to get the most performance out of the FPGA possible, the design would need to be well pipelined for the highest F<sub>max</sub>.
2. Video Processing
    - Avoid any video processing hard-IP and write everything myself: buffering, post processing
      like anti-aliasing, convolutional kernels for image effects. 
3. HDMI
    - The only video interfaces I have worked with so far are parallel/serial TFTs and standard VGA.
      HDMI is more modern so it only felt right to learn it.

### Project Specifications

For any project there should be a list of specifications, here is what I wanted out of my fractal
generator:

- Use an Artix-7 from Xilinx
- The most number of iterations for the fractal calculation possible (around 200-300)
- Real-time, constant framerate output at 1080p (1920x1080), 60 FPS over HDMI
- Automatic and manual fractal zooming / panning 
- A switch between Mandlebrot and Julia fractals
- Minimal IP, all VHDL written by myself
- Music input to affect fractal image output

### Fractal Math

The entirety of the fractal math consists of squaring Z, adding C to it, and comparing it to the
bailout radius R. Because Z and C are complex numbers, the complex square needs to be broken down to
be represented in hardware.

<p align="center" class="font-weight-bold">Z<sub>n+1</sub> = Z<sub>n</sub><sup>2</sup> + C, while Z &lt; R&nbsp;</p>
<p align="center">Z = a + j*b, C = x + j*y</p>
<p align="center">Z<sup>2</sup> = (a + j*b)*(a + j*b)<br>Z<sup>2</sup> = a<sup>2</sup> + 2*j*a*b -b<sup>2</sup><br></p>
<p align="center">Z<sub>n+1</sub> = a<sup>2</sup> - b<sup>2</sup> + x + j(2*a*b + y)</p>

With this reduction, we can see that the main calculation requies 3 multiplies, 3 additions (one
subtraction), and a comparison. We also want to compute the magnitude of Z, so we can compare it
against R, which is not a complex number. The magnitude of Z is just the sum of the squarer outputs. 

### Fractal Engine Design

Below are conceptual designs for the most important hardware chunks of the fractal engine: the
fractal slice, and the fractal core. 

The "fractal slice" is what I call the architectural code that has the multipliers, adders, and
comparators needed for the calculation. It's the building block of the fractal engine: the more
fractal slices the FPGA can hold, the better the fractal image output. 

The structure of the fractal slice is simple, it just maps the equation given above into hardware.
The challenging part was optimizing it for minimal LUT usage, minimal DSP usage, and a high
operating frequency. 

![Image](/doc/slice_concept.png)

The "fractal core" is what I labeled as the wrapper of all of the VHDL components used in the
Mandlebrot calculation. For the diagram below:


- Complex plane coordinates are inputted into the core at every pixel clock cycle.
- They are passed across clock domains into the F max region by the left-sided flow control.
    - F<sub>max</sub> is an integer ratio of the pixel clock
- The data is processed by the fully-pipelined fractal slices, where each slice represents an iteration.
- The fractal math data is then either converted back to the slower pixel clock domain and passed
out of the core via the right-sided flow control, or it is looped back to the start of the slice
pipeline
    - This loopback feature works when F max is an integer multiple of the pixel clock. For a ratio of 3, we can send the same coordinate through the pipeline three times: tripling the amount of iterations the core can achieve without increasing the amount of hardware required.

![Image](/doc/core_concept.png)

### Hardware Design

Here's the block diagram for the final top-level. All of the blocks were self-written besides the VIO, OSERDES, and
TMDS Encoder:

![Image](/doc/TopLevel.png)

Explanations and examples of each block:

#### VIO

The VIO is a Xilinx IP core (Virtual Input Output). I used it to interface the mouse and keyboard to my project via JTAG. It was responsible for controlling the zooming and panning functionality shown in the video.

The picture below shows the buttons and entries used for controlling the fractal image. For example, clicking the "pan_d" button would pan the image downward in the complex plane. Clicking the "zoom_i" button would zoom in the complex plane.

![Image](/doc/VIO_picture.jpg)

#### Fractal Screen Generator

The screen generator is responsible for setting up the dimensions of the complex plane to pass
through the fractal engine. It basically sets what part of the fractal we want to look at. Every
1/60 of a second (for 60 frames a second video), the top-left corner, width, and height of the
complex plane are sent downstream.

Zooming and panning functionality is included here. Panning means translating the complex plane
in a cardinal direction, while zooming means shrinking or expanding the width/height of the plane.
The zooming feature is seen in all classic Mandlebrot fractal videos. Special care was taken when
zooming to maintain the aspect ratio of the screen, set by generics.

#### Fractal Coordinate Generator

The coordinate generator receives the complex plane dimensions (position, width, height), does
simple math, and generates a new coordinate every pixel clock cycle. This is fed directly into the
fractal core. It also notifies downstream which pixel is the start of a new video frame via
metadata.

#### Fractal Core

The main job of the core is to receive a complex plane coordinate, then transmit that coordinate
along with the number of iterations requried to escape the Mandlebrot set (or bailout).

I designed it to operate with zero throttling or backpressure, and it is fully pipelined to
produce a result every clock cycle.

The core operates at integer multiple of the pixel clock for the video system. One challenging
part of designing the core was crossing the complex plane data between clock domains. I ended up
using a simple ping-pong BRAM buffering scheme to convert an array of data from the pixel clock
domain to the faster calculation clock domain, and then eventually back to the pixel clock domain.

The core instantiates as many fractal slices as possible that can fit in the FPGA. I was able to
place 20 optimized fractal slices in the core, quadruple-pumped at 300 MHz (about a 65 MHz pixel
clock). So the maximum amount of iterations I was able to achieve for the fractal calculation was
80. This was using less than half the FPGA as well: see later sections for my hardware issues.

The fractal slice was where 80% of the VHDL work was focused. The first revision of the slice used about 1K LUTs, 2K FFs, and 12 DSP units. This accounts for (1.67%, 1.67%, and 5%) of the entire 7-series FPGA. I was able to balance the resource utilization better by writing optimized squaring circuits to use LUTs instead of DSPs, using: 1.5K LUTS, 3K FFs, and 4 DSP units (2.5%, 2.5%, and 1.67%) of the FPGA. 
 
A lot of my timing analysis went here as well. I needed the fractal slice to operate at a high speed, and the main way this was accomplished was just adding more registers to shorten logic paths or net delays.

#### Fractal Smooth Counter

The output of the fractal core are discrete iteration numbers: 1, 2, ... 79, 80, etc. This can
result in unappealing color bands later on when applying a color LUT:

*No Smoothing: 80 max iterations, escape radius = 4*
![Image](/doc/nosmoothing_80iter_4escape.png)

By applying a logarithmic smoothing equation, increasing the escape radius, and scaling the amount
of colors, we can get rid of the color bands. In the image below, there are 10 times the amount of
colors used compared to the previous image. I did not come up with the equation, so check the
references if you're interested in it.

*With Smoothing: 80 max iterations, escape radius = 40, color scale = 10*
![Image](/doc/smoothing_80iter_40escape.png)

#### Video Blanking Extender

The blanking extender is the first of the video components. Screen data sent through the fractal
core does not include any of the video blanking intervals, so this just adds the blank pixel periods
needed later. It simply buffers up the data and throttles it using a FIFO to add in the horizontal
and vertical blanking periods. 

This was actually my first time using a FIFO. I've always just preferred addressable BRAM,
but I can see the usefulness now!

I was pretty happy with this design, as I was able to completely avoid having to use a
framebuffer for the video components.

#### Color LUT

The color LUT is what gives the pixel's on the screen color. The iteration count for the fractal
coordinate is inputted into a ROM loaded with color data from MATLAB.

#### Gaussian Blur (2D Convolution)

The image data from the fractal calculation has an infinite amount of detail, just because of the
nature of the fractal. When presented on the screen, the high frequency components from this don't
look good. I implemented a 3x3 Gaussian Blur Kernel using 2D convolution on each of the color
channels to act as a simple form of anti aliasing. I was happy with the result, and learning image
convolution was fun. 

| *No Post Processing*                                   |  *3x3 Gaussian Blur*                                           |
| ------------------------------------------------------ | -------------------------------------------------------------- |
| ![Image](/doc/highdetail_smoothed_80iter_40escape.png) | ![Image](/doc/highdetail_smoothed_blurred_80iter_40escape.png) |

#### Video Sync Generator

The sync generator uses metadata generated upstream (at the fractal coordinate generator) to run
counters and create the VSYNC and HSYNC signals based off where we are in the screen.

#### TMDS Encoder and OSERDES

The TMDS Encoder is used in the DVI and HDMI video interfaces. It performs an 8b10b encoding
algorithm to convert 8 bits of color and the video sync markers into a 10 bit word. The 10 bit word
is designed with special properties like minimal transitions and DC balancing for when it is sent
out over a serial line. It also carries audio data for HDMI (and maybe DVI, I didn't look into it).
I used some code from Digikey for this block; I'm not sure why I didn't feel like writing it. I
guess I was impatient to see an image on the screen.

The 5:1 DDR OSERDES was a Xilinx IP block that I generated using the SelectIO wizard. I prefer
using the wizard to wrap up the SERDES blocks, as opposed to directly instantiating the primitives.
From experience, I've gotten better results from this. The OSERDES is used to drive the TMDS serial
signals that go over the HDMI cord to the monitor.

### Hardware Troubles

I kind of alluded to this earlier, but I experienced seriously stupid hardware issues on my journey
to make a great fractal project. At the start of April I ordered a $100 FPGA from Chinese company
via Aliexpress, and after three months of shipping I was able to finally use it. On paper it was a
great board: a lot of GPIO, HDMI, ethernet, and a relatively big FPGA (Artix-7, 60K LUTs) with a
decent speed grade. 

*Bad FPGA Board*
![Image](/doc/UneducatedDesigner.png)

However, problems showed up when I started filling the FPGA past 50% utilization. When I increased
the amount of fractal slices in the design (via a generic), the FPGA would brown-out the power
supply voltage shortly after being programmed. I ran a bunch of tests to try and determine if it was
an issue with my design, but eventually gave up. I decided to end the nightmare and attribute it to
the fact that the designer for this board did not add any decoupling capacitors to the FPGA. There
are zero capacitors on the bottom of this BGA chip, so goodluck trying to easily fix this. 

Because of this I wasn't able to push my design as far as I wanted to. It also marked the end of the
project, as I had no desire to add more features. The fizzling-end of this project did prove to be a
good exercise in the stubbornness-flexibility tradeoff, as I couldn't just work through the problems
and fix everything. In the future, I plan to never order something like this from Aliexpress again.
Terrible customer service and review policies, too. Hopefully the market for American-made
evaluation boards (or just well made products) contiues to expand.

### Project Finish

In conclusion, here are the parts of the project I liked:

- Setting up an HDMI interface to work directly with a monitor (no codec) was interesting. I should have wrote my own TMDS_encoder and not been lazy, though.
- I was proud of my optimized squaring circuit used in the fractal slice. I was able to perform a 32-bit square using 500 LUTs, 1000 FFs, and no DSP units. The circuit used a funky set of reduced partial products and ternary adders to perform in a similar way to a Wallace tree. 
- I had never written anything for 2D image convolution before, so writing the block for
performing the Gaussian Blur was cool and seeing the output was cool.
- The video blanking extender had an interesting design process. For no good reason, I struggled with the buffering concept initially. Adding a synchronous FIFO to the design offered a simple solution that really appealed to me and changed the way I perceived the block.
- Learning timing analysis was kind of an underwhelming experience. In most situations, I could fix timing violations by just adding more registers to the logic. Maybe in a future project I'll have to force some multicycle or false paths.

Here are some shortcomings of the project:

- I wasn't able to push my design to the fullest. This was mentioned earlier, but it really killed any desire I had to polish this project or add a lot of features.
- I did not implement an auto-zoom or auto-panning feature. The idea was that you could turn the
  fractal generator on and it would automatically zoom and pan into interesting parts of the complex
plane. It would also reset itself when the fixed-point numbers were about to underflow, or if the
output image was primarily empty.
- I wasn't able to run the video system at 1080P. To support native HDMI without a CODEC, the FPGA OSERDES block would need to be clocked around 750MHz at 5:1 DDR serialization factor. When I would run the design at 1080P, sometimes my monitors wouldn't pick up the video signal. From the FPGA's manual the max speed is below 750 MHz, so I had to lower the clock rate and run at 1080i (interlaced) to get consistent performance.
- Because I wasn't interested in this project at the end, I didn't implement the Julia set. The Julia fractal is very similar to the Mandlebrot; if you've written a good Mandlebrot generator then it can easily handle the Julia set. 
- I didn't add a music portion to the design for the same reason as above.

## References
1. [Wikipedia, Mandlebrot set](https://en.wikipedia.org/wiki/Mandelbrot_set)
2. [Wikipedia, Plotting algorithms for the Mandlebrot set](https://en.wikipedia.org/wiki/Plotting_algorithms_for_the_Mandelbrot_set)
3. [Wikipedia, Julia set](https://en.wikipedia.org/wiki/Julia_set)
4. [Iniqo Quilez, Smooth Iteration Count for Generalized Mandlebrot
   Sets](https://www.iquilezles.org/www/articles/mset_smooth/mset_smooth.htm)
5. [Linas Vepstas, Renormalizing the Mandlebrot Escape](https://linas.org/art-gallery/escape/escape.html)
6. [fpga4fun, HDMI](https://www.fpga4fun.com/HDMI.html)
7. [Digikey, TMDS Encoder in VHDL](https://forum.digikey.com/t/tmds-encoder-vhdl/12653)
