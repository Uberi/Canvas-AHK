Canvas-AHK
==========
Canvas-AHK is a portable, high level drawing library written for AutoHotkey, designed for use in moderately graphics intensive applications outputting to screens or image files.

Types
-----

### Units
;wip: write about unit system and cartesian coordinate system

### Color
;wip: write about ARGB and hex

Surfaces
--------
Surfaces represent and allow the manipulation of graphics data. This may include drawing, painting, and more.

### Canvas.Surface.__New(Width,Height)
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
Refreshes the viewport to reflect changes in a region of its attached surface defined by X-axis coordinate _X_ (units), Y-axis coordinate _Y_ (units), width _W_ (units), and height _H_ (units).

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

