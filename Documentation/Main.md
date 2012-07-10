Canvas-AHK
==========
Canvas-AHK is a portable, high level drawing library written for AutoHotkey, designed for use in moderately graphics intensive applications outputting to screens or image files.

Types
-----

### Units
;wip: write about unit system and cartesian coordinate system

### Color
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

Surfaces
--------
Surfaces represent and allow the manipulation of graphics properties and data. This may include drawing, painting, and more.

### Canvas.Surface.__New(Width,Height)
Creates a surface object representing a set of graphics properties and data, having a width of _Width_ (units) and height _Height_ (units).

### Canvas.Surface.Clear(Color = 0x00000000)
Clears the entire surface to a color defined by _Color_ (color).

### Canvas.Surface.DrawLine(Pen,X,Y,W,H)
Draws a single line with the pen _Pen_ (Pen), at the X-axis coordinate _X_ (units), Y-axis coordinate _Y_ (units), X-axis extent _W_ (positive or zero units), and Y-axis extent _H_ (positive or zero units).

### Canvas.Surface.DrawLines(Pen,Points)
;wip

Viewports
---------
Viewports represent output displays. This may include windows, controls, or the entire screen.

Surfaces attached to viewports will have their contents displayed in the viewport.

### Canvas.Viewport.__New(hWindow)
Creates a viewport object representing a window referenced by the window handle _hWindow_ (hwnd).

### Canvas.Viewport.Attach(Surface)
Attaches surface _Surface_ (Canvas.Surface) to the viewport so that it is displayed by the viewport.

### Canvas.Viewport.Refresh(X = 0,Y = 0,W = 0,H = 0)
Refreshes the viewport to reflect changes in a region of its attached surface defined by X-axis coordinate _X_ (positive or zero units), Y-axis coordinate _Y_ (positive or zero units), width _W_ (positive or zero units), and height _H_ (positive or zero units).

Pens
----
Pens represent drawing properties such as color or width, and are used to draw the outlines of shapes in graphics operations.

### Canvas.Pen.__New(Color = 0xFFFFFFFF,Width = 1)
Creates a pen object representing a set of drawing properties, with color defined by _Color_ (color) and width defined by _Width_ (units).

### Canvas.Pen.Color
Represents the current color of the pen (color). Can be set to change the current color.

### Canvas.Pen.Width
Represents the current width of the pen (units). Can be set to change the current width.

### Canvas.Pen.Join
Represents the current join style of the pen (join style). Can be set to change the current join style. Join styles define how the points where lines join are displayed when drawing multiple connected lines. Defaults to "Miter" when the pen is created.

Line join styles are one of the following values:

| Style | Effect                                                                                      |
|:------|:--------------------------------------------------------------------------------------------|
| Miter | Extend the outer edges of the lines being joined so that they meet, forming a sharp corner. |
| Bevel | Clips the intersection of the outer edges such that it forms a cut corner.                  |
| Round | Fills the intersection of the outer edges with part of an ellipse.                          |

### Canvas.Pen.Type
Represents the current type of the pen (type style). Can be set to change the current type style. Type styles define the appearance of the pen, such as stippling/dashing. Defaults to "Solid" when the pen is created.

| Style   | Effect                                                                      |
|:--------|:----------------------------------------------------------------------------|
| Solid   | Continuous, unbroken lines.                                                 |
| Dash    | Longer line segments divided by shorter breaks at regular intervals.        |
| Dot     | Dots spaced at regular short intervals along the line.                      |
| DashDot | Alternation between longer line segments and dots at equal short intervals. |

### Canvas.Pen.StartCap
Represents the start cap style of the pen (cap style). Can be set to change the current start cap style. Start cap styles define how the starting points of lines are displayed. Defaults to "Flat" when the pen is created.

Cap styles are one of the following values:

| Style    | Effect                                                  |
|:---------|:--------------------------------------------------------|
| Flat     | Flat end at the point.                                  |
| Square   | Flat end past the point by half the width of the pen.   |
| Round    | Round end with center of rounding at the point.         |
| Triangle | Tapered protrusion at the point, aligned with the line. |

### Canvas.Pen.EndCap
Represents the end cap style of the pen (cap style). Can be set to change the current end cap style. End cap styles define how the ending points of lines are displayed. Defaults to "Flat" when the pen is created.

Brushes
-------
Brushes represent fill properties such as color or texture, and are used to fill the interior of shapes in graphics operations.

