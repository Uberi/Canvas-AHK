Canvas-AHK
==========
Canvas-AHK is a portable, high level drawing library written for AutoHotkey, designed for use in moderately graphics intensive applications outputting to screens or image files.

Types
-----

### Units
Units represent distances and dimensions (positive or negative real number).

;wip: write about unit system and cartesian coordinate system

### Angles
Angles are measured in degrees from the reference line, clockwise. The reference line is vertical and is directed towards the negative Y-axis:

    A
    |  B
    | /
    |/
    C

The reference line is AC, with the origin at C and directed towards A. Therefore, the angle is represented by ACB.

### Colors
Color references represent a specific color and transparency. They are written in hexadecimal ARGB format.

Each byte of the four byte color reference forms a single component, and each component is between the range of 0x00 to 0xFF (0 to 255 in decimal):

    0x40FF0000
      AARRGGBB

| Component | Description |
|:----------|:------------|
| A         | Alpha       |
| R         | Red         |
| G         | Green       |
| B         | Blue        |

### Point Set
Point sets represent one or more 2-dimensional coordinate pairs.

Point sets are arrays of points, which are themselves arrays with two elements each, the first representing the X-axis coordinate (units), the second the Y-axis coordinate (units):

    [[X1,Y1],[X2,Y2]]

Exceptions
----------
There are two types of exceptions that may be thrown by this library: invalid input and internal errors.

Exceptions may be thrown when functions are called with invalid input, when properties are set to invalid values, or when the library encounters an error internally and cannot continue. Any function call or setting of a property is capable of throwing an exception.

By the time an exception is thrown, any temporary resources have already been cleaned up. It is not necessary to clean up anything manually.

### Invalid Input
Exceptions of this type take the following form:

    throw Exception("INVALID_INPUT",-1,Extra)

Invalid input exceptions represent errors in the input given to a function, such as passing a string when a number was expected, or a decimal number when an integer was expected.

This type of exception is defined by its message being the string "INVALID_INPUT" (Exception.Message). The caller of the function throwing the error will be the exception's routine (Exception.What). Detailed information about the error is available in the exception's extended information (Exception.Extra), but should be used only for debugging purposes.

### Internal Error
Exceptions of this type take the following form:

    throw Exception("INTERNAL_ERROR",A_ThisFunc,Extra)

Internal error exceptions represent errors in the operation of a function, such as a failed drawing command or an out-of-memory error.

This type of exception is defined by its message being the string "INTERNAL_ERROR" (Exception.Message). The function throwing the error will be the exception's routine (Exception.What). Detailed information about the error is available in the exception's extended information (Exception.Extra), but should be used only for debugging purposes.

Canvas
------
The Canvas class is not to be instaniated and serves mainly to provide general initialization and cleanup functions, as well as to contain its submodules.

### Canvas.Lenient()
Disables most error checking routines in all submodules. This may improve performance somewhat, though invalid input or internal errors may not be detected.

This setting applies globally to all Canvas-related objects in the program, and is recommended for use only if performance concerns outweigh reliability concerns.

Surfaces
--------
Surfaces represent and allow the manipulation of graphics properties and data. This may include drawing, painting, and more.

### Canvas.Surface.__New(Width,Height,Path = "")
Creates a surface object representing a set of graphics properties and data, having a width of _Width_ (units) and height _Height_ (units).

If _Path_ is not a blank string, it is interpreted as a path to a supported image file, which will be loaded as the contents of the surface. In this case, the _Width_ and _Height_ parameters are ignored, and instead the dimensions of the surface are determined by the dimensions of the image. ;wip: document supported image formats

Returns the surface object.

### Canvas.Surface.Interpolation := "None"
Represents the current interpolation mode of the surface (interpolation style). Interpolation modes define the appearance of surfaces when scaled.

Interpolation styles are one of the following values:

| Style  | Effect                                                                                                         |
|:-------|:---------------------------------------------------------------------------------------------------------------|
| None   | Pixels are sampled according to the nearest neighbor. Suitable for fast, low quality, or pixelated effects.    |
| Linear | Pixels are linearly sampled across the source values. Suitable for medium quality and reasonably fast effects. |
| Cubic  | Pixels are sampled according to a cubic spline. Suitable for high quality, slower effects.                     |

### Canvas.Surface.Smooth := "None"
Represents the current smooth mode of the surface (smooth style). Smooth modes define the appearance and antialiasing of objects drawn onto the surface.

Smooth styles are one of the following values:

| Style | Effect                                                                                          |
|:------|:------------------------------------------------------------------------------------------------|
| None  | Objects are not smoothed or antialiased. Suitable for fast, low quality, or pixelated effects.  |
| Good  | Objects are smoothed and antialiased at medium quality. Suitable for reasonably fast effects.   |
| Best  | Objects are smoothed and antialiased at high quality. Suitable for slower but smoother effects. |

### Canvas.Surface.Clear(Color = 0x00000000)
Clears the entire surface to a color defined by _Color_ (color).

Returns the surface object.

### Canvas.Surface.Line(Pen,X1,Y1,X2,Y2)
Draws a single line with the pen _Pen_ (Pen), starting at the X-axis coordinate _X1_ (units) and Y-axis coordinate _Y1_ (units), ending at X-axis coordinate _X2_ (units) and Y-axis coordinate _Y2_ (units).

Returns the surface object.

### Canvas.Surface.Lines(Pen,Points)
;wip

### Canvas.Surface.Width
The width of the surface (units). Should not be modified.

### Canvas.Surface.Height
The height of the surface (units). Should not be modified.

Viewports
---------
Viewports represent output displays. This may include windows, controls, or the entire screen.

Surfaces attached to viewports will have their contents displayed in the viewport.

### Canvas.Viewport.__New(hWindow)
Creates a viewport object representing a window referenced by the window handle _hWindow_ (hwnd).

Returns the viewport object.

### Canvas.Viewport.Attach(Surface)
Attaches surface _Surface_ (Canvas.Surface) to the viewport so that it is displayed by the viewport.

Returns the viewport object.

### Canvas.Viewport.Refresh(X = 0,Y = 0,W = 0,H = 0)
Refreshes the viewport to reflect changes in a region of its attached surface defined by X-axis coordinate _X_ (positive or zero units), Y-axis coordinate _Y_ (positive or zero units), width _W_ (positive or zero units), and height _H_ (positive or zero units).

If _W_ is zero, it will be interpreted as the width of the currently attached surface (Canvas.Surface.Width). If _H_ is zero, it will be interpreted as the height of the currently attached surface (Canvas.Surface.Height).

Returns the viewport object.

Pens
----
Pens represent drawing properties such as color or width, and are used to draw the outlines of shapes in graphics operations.

### Canvas.Pen.__New(Color = 0xFFFFFFFF,Width = 1)
Creates a pen object representing a set of drawing properties, with color defined by _Color_ (color) and width defined by _Width_ (units).

### Canvas.Pen.Color
Represents the current color of the pen (color). Can be set to change the current color.

### Canvas.Pen.Width
Represents the current width of the pen (units). Can be set to change the current width.

### Canvas.Pen.Join := "Miter"
Represents the current join style of the pen (join style). Can be set to change the current join style. Join styles define how the points where lines join are displayed when drawing multiple connected lines.

Line join styles are one of the following values:

| Style | Effect                                                                                      |
|:------|:--------------------------------------------------------------------------------------------|
| Miter | Extend the outer edges of the lines being joined so that they meet, forming a sharp corner. |
| Bevel | Clips the intersection of the outer edges such that it forms a cut corner.                  |
| Round | Fills the intersection of the outer edges with part of an ellipse.                          |

### Canvas.Pen.Type := "Solid"
Represents the current type of the pen (type style). Can be set to change the current type style. Type styles define the appearance of the pen, such as stippling/dashing.

| Style   | Effect                                                                      |
|:--------|:----------------------------------------------------------------------------|
| Solid   | Continuous, unbroken lines.                                                 |
| Dash    | Longer line segments divided by shorter breaks at regular intervals.        |
| Dot     | Dots spaced at regular short intervals along the line.                      |
| DashDot | Alternation between longer line segments and dots at equal short intervals. |

### Canvas.Pen.StartCap := "Flat"
Represents the start cap style of the pen (cap style). Can be set to change the current start cap style. Start cap styles define how the starting points of lines are displayed.

Cap styles are one of the following values:

| Style    | Effect                                                  |
|:---------|:--------------------------------------------------------|
| Flat     | Flat end at the point.                                  |
| Square   | Flat end past the point by half the width of the pen.   |
| Round    | Round end with center of rounding at the point.         |
| Triangle | Tapered protrusion at the point, aligned with the line. |

### Canvas.Pen.EndCap := "Flat"
Represents the end cap style of the pen (cap style). Can be set to change the current end cap style. End cap styles define how the ending points of lines are displayed.

Brushes
-------
Brushes represent fill properties such as color or texture, and are used to fill the interior of shapes in graphics operations.

;wip