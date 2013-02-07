Canvas-AHK
==========
Canvas-AHK is a portable, high level drawing library written for AutoHotkey, designed for use in moderately graphics intensive applications outputting to screens or image files.

Overview
--------
* Surfaces are where things are drawn.
* Viewports display surfaces on the screen.
* Pens and brushes define what the drawn things look like.
* Formats define what drawn text looks like.

Types
-----

### Units
Units represent distances and dimensions (real number).

Each unit corresponds to one pixel on the screen.

Units are represented using a cartesian coordinate system, where an increase in the X-axis value corresponds to rightwards and an increase in the Y-axis value corresponds to downwards. The origin can be found at the top left corner.

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

Point sets are arrays of points, which are themselves 1-indexed arrays with two elements each, the first representing the X-axis coordinate (units), the second the Y-axis coordinate (units):

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

Transforms
----------
Transforms are changes applied to all drawing operations on a surface done while it is in effect. They work only on the surface they are applied to.

Transforms do not affect previous drawing operations or those done when the transform is removed.

Transforms work on top of each other. Applying one transform, and then another, results in both transforms being applied, rather than the second overwriting the first. Each transform modifies the current transformation state.

Each surface has its own independent transform stack. This is a stack that can store transformation states. Using the `Canvas.Surface.Push()` and `Canvas.Surface.Pop()` functions, one can save and restore the current transformation state.

Canvas
------
The Canvas class is not to be instaniated and serves mainly to provide general initialization and cleanup functions, as well as to contain its submodules.

### Canvas.Lenient()
Disables most error checking routines in submodules. This may improve performance somewhat, though invalid input or internal errors may not be detected.

This setting applies globally to all Canvas-related objects in the program, and is recommended for use only if performance concerns outweigh reliability concerns.

Surfaces
--------
Surfaces represent and allow the manipulation of graphics properties and data. This may include drawing, painting, and more.

### Canvas.Surface.__New(Width,Height,Path = "")
Creates a surface object representing a set of graphics properties and data, having a width of `Width` (units) and height `Height` (units).

If `Path` is not a blank string, it is interpreted as a path to a supported image file, which will be loaded as the contents of the surface. In this case, the `Width` and `Height` parameters are ignored, and instead the dimensions of the surface are determined by the dimensions of the image. ;wip: document supported image formats

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

### Canvas.Surface.Width
The width of the surface (units). Should not be modified.

### Canvas.Surface.Height
The height of the surface (units). Should not be modified.

### Canvas.Surface.Clear(Color = 0x00000000)
Clears the entire surface to a color defined by `Color` (color).

Returns the surface object.

### Canvas.Surface.Draw(Surface,X = 0,Y = 0,W = "",H = "",SourceX = 0,SourceY = 0,SourceW = "",SourceH = "") ;wip: streamline
Draws the contents of `Surface` (surface) starting from X-axis coordinate `SourceX` (units) and Y-axis coordinate `SourceY` (units), with width `SourceW` (units) and height `SourceH` (units), at X-axis coordinate `X` (units) and Y-axis coordinate `Y` (units), with width `W` (units) and height `H` (units).

Returns the surface object.

### Canvas.Surface.DrawArc(Pen,X,Y,W,H,Start,Sweep)
Draws an arc of an ellipse at X-axis coordinate `X` (units) and Y-axis coordinate `Y` (units), with width `W` (units) and height `H` (units), starting at `Start` (angle) and sweeping for `Sweep` (angle). The coordinates and dimensions define the bounding rectangle of the ellipse if it were to be drawn in full.

Returns the surface object.

### Canvas.DrawCurve(Pen,Points,Closed = False)
;wip: talk about the Tension parameter that is added with GdipDrawCurve2
Draws a cardinal spline as a curved line with `Pen` (pen), passing through each point in `Points` (point set). If `Closed` (boolean) is set, the curve will be drawn as the outline of a closed shape. Otherwise, the curve is open.

Returns the surface object.

### Canvas.Surface.DrawEllipse(Pen,X,Y,W,H)
Draws the outline of an ellipse at X-axis coordinate `X` (units) and Y-axis coordinate `Y` (units), with width `W` (units) and height `H` (units). The coordinates and dimensions define the bounding box of the ellipse.

Returns the surface object.

### Canvas.Surface.DrawPie(Pen,X,Y,W,H,Start,Sweep)
Draws the outline of a pie (an arc with lines leading from the end to the center) of an ellipse with `Pen` (pen) at X-axis coordinate `X` (units) and Y-axis coordinate `Y` (units), with width `W` (units) and height `H` (units), starting at `Start` (angle) and sweeping for `Sweep` (angle). The coordinates and dimensions define the bounding rectangle of the ellipse if it were to be drawn in full.

Returns the surface object.

### Canvas.Surface.DrawPolygon(Pen,Points)
Draws the outline of a closed polygon with `Pen` (pen), with the vertices defined by `Points` (point set).

Returns the surface object.

### Canvas.Surface.DrawRectangle(Pen,X,Y,W,H)
Draws the outline of a rectangle with `Pen` (pen) at X-axis coordinate `X` (units) and Y-axis coordinate `Y` (units), with width `W` (units) and height `H` (units).

Returns the surface object.

### Canvas.Surface.FillCurve(Brush,Points)
Fills the area of a closed cardinal spline with `Brush` (brush), passing through each point in `Points` (point set).

Returns the surface object.

### Canvas.Surface.FillEllipse(Brush,X,Y,W,H)
Fills the area of an ellipse with `Brush` (brush) at X-axis coordinate `X` (units) and Y-axis coordinate `Y` (units), with width `W` (units) and height `H` (units). The coordinates and dimensions define the bounding rectangle of the ellipse.

Returns the surface object.

### Canvas.Surface.FillPie(Brush,X,Y,W,H,Start,Sweep)
Fills the area of a pie (an arc with lines leading from the end to the center) of an ellipse with `Brush` (brush) at X-axis coordinate `X` (units) and Y-axis coordinate `Y` (units), with width `W` (units) and height `H` (units), starting at `Start` (angle) and sweeping for `Sweep` (angle). The coordinates and dimensions define the bounding rectangle of the ellipse if it were to be drawn in full.

Returns the surface object.

### Canvas.Surface.FillPolygon(Brush,Points)
Fills the area of a closed polygon with `Brush` (brush), with the vertices defined by `Points` (point set).

Returns the surface object.

### Canvas.Surface.FillRectangle(Brush,X,Y,W,H)
Fills the area of a rectangle with `Brush` (brush) at X-axis coordinate `X` (units) and Y-axis coordinate `Y` (units), with width `W` (units) and height `H` (units).

Returns the surface object.

### Canvas.Surface.Line(Pen,X1,Y1,X2,Y2)
Draws a single line with `Pen` (pen), starting at X-axis coordinate `X1` (units) and Y-axis coordinate `Y1` (units), ending at X-axis coordinate `X2` (units) and Y-axis coordinate `Y2` (units).

Returns the surface object.

### Canvas.Surface.Lines(Pen,Points)
Draws a series of connected lines with `Pen` (pen), at coordinates defined by `Points` (point set).

Returns the surface object.

### Canvas.Surface.TextDimensions(Format,Value,ByRef Width,ByRef Height)
Determines the width and height of the bounding box of `Value` (text) if it were to be drawn with `Format` (format). The resulting numbers can be found in the variables passed as `Width` and `Height`.

Returns the surface object.

### Canvas.Surface.Text(Brush,Format,Value,X,Y,W = "",H = "")
Draws `Text` (text) with `Brush` (brush) and `Format` (format), at X-axis coordinate `X` (units) and Y-axis coordinate `Y` (units). If width `W` (units) is specified, the text is drawn with that width. If height `H` (units) is specified, the text is drawn with that height. Otherwise, both dimensions are assumed to be those of the text's bounding box.

### Canvas.Surface.Push()
Pushes the current transformation state onto the transform stack. The transformation state includes the current translation, rotation, and scaling.

Returns the surface object.

### Canvas.Surface.Pop()
Pops the top entry of the transform stack off and sets the current transformation state to the entry's state.

Returns the surface object.

### Canvas.Surface.Translate(X,Y)
Translates the current transformation state by `X` (units) along the X-axis and `Y` (units) along the Y-axis.

Returns the surface object.

### Canvas.Surface.Rotate(Angle)
Rotates the current transformation state by `Angle` (angle).

Returns the surface object.

### Canvas.Surface.Scale(X,Y)
Scales the current transformation state by a factor of `X` (units) along the X-axis and `Y` (units) along the Y-axis.

Viewports
---------
Viewports represent output displays. This may include windows, controls, or the entire screen.

Surfaces attached to viewports will have their contents displayed in the viewport.

### Canvas.Viewport.__New(hWindow)
Creates a viewport object representing a window referenced by the window handle `hWindow` (hwnd).

Returns the viewport object.

### Canvas.Viewport.Attach(Surface)
Attaches surface `Surface` (Canvas.Surface) to the viewport so that it is displayed by the viewport.

Returns the viewport object.

### Canvas.Viewport.Refresh(X = 0,Y = 0,W = 0,H = 0)
Refreshes the viewport to reflect changes in a region of its attached surface defined by X-axis coordinate `X` (positive or zero units), Y-axis coordinate `Y` (positive or zero units), width `W` (positive or zero units), and height `H` (positive or zero units).

If `W` is zero, it will be interpreted as the width of the currently attached surface (Canvas.Surface.Width). If `H` is zero, it will be interpreted as the height of the currently attached surface (Canvas.Surface.Height).

Returns the viewport object.

Pens
----
Pens represent drawing properties such as color or width, and are used to draw the outlines of shapes in graphics operations.

### Canvas.Pen.__New(Color = 0xFFFFFFFF,Width = 1)
Creates a pen object representing a set of drawing properties, with color defined by `Color` (color) and width defined by `Width` (units).

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