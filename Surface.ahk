#NoEnv

/*
Copyright 2012 Anthony Zhang <azhang9@gmail.com>

This file is part of Canvas-AHK. Source code is available at <https://github.com/Uberi/Canvas-AHK>.

Canvas-AHK is free software: you can redistribute it and/or modify
it under the terms of the GNU Affero General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU Affero General Public License for more details.

You should have received a copy of the GNU Affero General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/

class Surface
{
    __New(Width,Height)
    {
        If Width Is Not Integer
            throw Exception("INVALID_INPUT",-1,"Invalid width: " . Width)
        If Height Is Not Integer
            throw Exception("INVALID_INPUT",-1,"Invalid height: " . Height)

        this.Width := Width
        this.Height := Height

        ;create a memory device context for double buffering use
        this.hMemoryDC := DllCall("CreateCompatibleDC","UPtr",0,"UPtr")
        If !this.hMemoryDC
            throw Exception("INTERNAL_ERROR",A_ThisFunc,"Could not create memory device context.")

        ;set up BITMAPINFO structure
        VarSetCapacity(BitmapInfo,40)
        NumPut(40,BitmapInfo,0,"UInt") ;structure size
        NumPut(Width,BitmapInfo,4,"UInt") ;bitmap width
        NumPut(Height,BitmapInfo,8,"UInt") ;bitmap height
        NumPut(1,BitmapInfo,12,"UShort") ;target device plane count
        NumPut(32,BitmapInfo,14,"UInt") ;bits per pixel
        NumPut(0,BitmapInfo,16,"UInt") ;BI_RGB: compression type
        NumPut(0,BitmapInfo,20,"UInt") ;image size
        NumPut(0,BitmapInfo,24,"UInt") ;horizontal resolution of target device
        NumPut(0,BitmapInfo,28,"UInt") ;vertical resolution of target device
        NumPut(0,BitmapInfo,32,"UInt") ;color index used count
        NumPut(0,BitmapInfo,36,"UInt") ;color index required count

        ;create the device independent bitmap
        pBits := 0
        this.hBitmap := DllCall("CreateDIBSection","UPtr",0,"UPtr",&BitmapInfo,"UInt",0,"UPtr*",pBits,"UPtr",0,"UInt",0) ;DIB_RGB_COLORS
        If !this.hBitmap
            throw Exception("INTERNAL_ERROR",A_ThisFunc,"Could not create bitmap.")

        ;select the bitmap into the memory device context
        this.hOriginalBitmap := DllCall("SelectObject","UPtr",this.hMemoryDC,"UPtr",this.hBitmap,"UPtr")
        If !this.hOriginalBitmap
            throw Exception("INTERNAL_ERROR",A_ThisFunc,"Could not select bitmap into memory device context.")

        ;create a graphics object
        pGraphics := 0, Result := DllCall("gdiplus\GdipCreateFromHDC","UPtr",this.hMemoryDC,"UPtr*",pGraphics)
        If Result != 0 ;Status.Ok
            throw Exception("INTERNAL_ERROR",A_ThisFunc,"Could not create graphics object from memory device context (GDI+ error " . Result . ").")
        this.pGraphics := pGraphics

        ;wip: set smoothing mode
    }

    __Delete()
    {
        ;delete the graphics object
        Result := DllCall("gdiplus\GdipDeleteGraphics","UPtr",this.pGraphics)
        If (Result != 0 && !e) ;Status.Ok
            e := Exception("INTERNAL_ERROR",A_ThisFunc,"Could not delete graphics object (GDI+ error " . Result . ").")

        ;deselect the bitmap if present
        If !DllCall("SelectObject","UPtr",this.hMemoryDC,"UPtr",this.hOriginalBitmap,"UPtr")
            throw Exception("INTERNAL_ERROR",A_ThisFunc,"Could not deselect bitmap from memory device context.")

        ;delete the bitmap
        If !DllCall("DeleteObject","UPtr",this.hBitmap)
            throw Exception("INTERNAL_ERROR",A_ThisFunc,"Could not delete bitmap.")

        ;delete the memory device context
        If !DllCall("DeleteDC","UPtr",this.hMemoryDC)
            throw Exception("INTERNAL_ERROR",A_ThisFunc,"Could not delete memory device context.")
    }

    Clear(Color = 0x00000000)
    {
        If Color Is Not Integer
            throw Exception("INVALID_INPUT",-1,"Invalid color: " . Color . ".")
        Result := DllCall("gdiplus\GdipGraphicsClear","UPtr",this.pGraphics,"UInt",Color)
        If Result != 0 ;Status.Ok
            throw Exception("INTERNAL_ERROR",A_ThisFunc,"Could not clear graphics (GDI+ error " . Result . ").")
        Return, this
    }

    DrawLine(Pen,X,Y,W,H)
    {
        this.CheckRectangle(X,Y,W,H)

        Result := DllCall("gdiplus\GdipDrawLine","UPtr",this.pGraphics,"UPtr",Pen.pPen,"Float",X,"FLoat",Y,"Float",X + W,"Float",Y + H)
        If Result != 0 ;Status.Ok
            throw Exception("INTERNAL_ERROR",A_ThisFunc,"Could not draw line (GDI+ error " . Result . ").")
        Return, this
    }

    DrawLines(Pen,Points)
    {
        Length := this.CheckPoints(Points,PointArray)

        Result := DllCall("gdiplus\GdipDrawLines","UPtr",this.pGraphics,"UPtr",Pen.pPen,"UPtr",&PointArray,"Int",Length)
        If Result != 0 ;Status.Ok
            throw Exception("INTERNAL_ERROR",A_ThisFunc,"Could not draw lines (GDI+ error " . Result . ").")
        Return, this
    }

    DrawArc(Pen,X,Y,W,H,Start,Sweep)
    {
        this.CheckSector(X,Y,W,H,Start,Sweep)

        Result := DllCall("gdiplus\GdipDrawArc","UPtr",this.pGraphics,"UPtr",Pen.pPen,"Float",X,"Float",Y,"Float",W,"Float",H,"Float",Start - 90,"Float",Sweep)
        If Result != 0 ;Status.Ok
            throw Exception("INTERNAL_ERROR",A_ThisFunc,"Could not draw arc (GDI+ error " . Result . ").")
        Return, this
    }

    DrawCurve(Pen,Points,Closed = False)
    {
        Length := this.CheckPoints(Points,PointArray)

        If Closed
            Result := DllCall("gdiplus\GdipDrawClosedCurve","UPtr",this.pGraphics,"UPtr",Pen.pPen,"UPtr",&PointArray,"Int",Length)
        Else
            Result := DllCall("gdiplus\GdipDrawCurve","UPtr",this.pGraphics,"UPtr",Pen.pPen,"UPtr",&PointArray,"Int",Length)
        If Result != 0 ;Status.Ok
            throw Exception("INTERNAL_ERROR",A_ThisFunc,"Could not draw curve (GDI+ error " . Result . ").")
        Return, this
    }

    DrawEllipse(Pen,X,Y,W,H)
    {
        this.CheckRectangle(X,Y,W,H)

        Result := DllCall("gdiplus\GdipDrawEllipse","UPtr",this.pGraphics,"UPtr",Pen.pPen,"Float",X,"Float",Y,"Float",W,"Float",H)
        If Result != 0 ;Status.Ok
            throw Exception("INTERNAL_ERROR",A_ThisFunc,"Could not draw ellipse (GDI+ error " . Result . ").")
        Return, this
    }

    DrawPie(Pen,X,Y,W,H,Start,Sweep)
    {
        this.CheckSector(X,Y,W,H,Start,Sweep)

        Result := DllCall("gdiplus\GdipDrawPie","UPtr",this.pGraphics,"UPtr",Pen.pPen,"Float",X,"Float",Y,"Float",W,"Float",H,"Float",Start - 90,"Float",Sweep)
        If Result != 0 ;Status.Ok
            throw Exception("INTERNAL_ERROR",A_ThisFunc,"Could not draw pie (GDI+ error " . Result . ").")
        Return, this
    }

    DrawPolygon(Pen,Points)
    {
        Length := this.CheckPoints(Points,PointArray)

        Result := DllCall("gdiplus\GdipDrawPolygon","UPtr",this.pGraphics,"UPtr",Pen.pPen,"UPtr",&PointArray,"Int",Length)
        If Result != 0 ;Status.Ok
            throw Exception("INTERNAL_ERROR",A_ThisFunc,"Could not draw polygon (GDI+ error " . Result . ").")
        Return, this
    }

    DrawRectangle(Pen,X,Y,W,H)
    {
        this.CheckRectangle(X,Y,W,H)

        Result := DllCall("gdiplus\GdipDrawRectangle","UPtr",this.pGraphics,"UPtr",Pen.pPen,"Float",X,"Float",Y,"Float",W,"Float",H)
        If Result != 0 ;Status.Ok
            throw Exception("INTERNAL_ERROR",A_ThisFunc,"Could not draw rectangle (GDI+ error " . Result . ").")
        Return, this
    }

    FillCurve(Brush,Points)
    {
        Length := this.CheckPoints(Points,PointArray)

        Result := DllCall("gdiplus\GdipFillClosedCurve","UPtr",this.pGraphics,"UPtr",Brush.pBrush,"UPtr",&PointArray,"Int",Length)
        If Result != 0 ;Status.Ok
            throw Exception("INTERNAL_ERROR",A_ThisFunc,"Could not fill curve (GDI+ error " . Result . ").")
        Return, this
    }

    FillEllipse(Brush,X,Y,W,H)
    {
        this.CheckRectangle(X,Y,W,H)

        Result := DllCall("gdiplus\GdipFillEllipse","UPtr",this.pGraphics,"UPtr",Brush.pBrush,"Float",X,"Float",Y,"Float",W,"Float",H)
        If Result != 0 ;Status.Ok
            throw Exception("INTERNAL_ERROR",A_ThisFunc,"Could not fill ellipse (GDI+ error " . Result . ").")
        Return, this
    }

    FillPie(Brush,X,Y,W,H,Start,Sweep)
    {
        this.CheckSector(X,Y,W,H,Start,Sweep)

        Result := DllCall("gdiplus\GdipFillPie","UPtr",this.pGraphics,"UPtr",Pen.pPen,"Float",X,"Float",Y,"Float",W,"Float",H,"Float",Start - 90,"Float",Sweep)
        If Result != 0 ;Status.Ok
            throw Exception("INTERNAL_ERROR",A_ThisFunc,"Could not fill pie (GDI+ error " . Result . ").")
        Return, this
    }

    FillPolygon(Brush,Points)
    {
        Length := this.CheckPoints(Points,PointArray)

        Result := DllCall("gdiplus\GdipFillPolygon","UPtr",this.pGraphics,"UPtr",Brush.pBrush,"UPtr",&PointArray,"Int",Length)
        If Result != 0 ;Status.Ok
            throw Exception("INTERNAL_ERROR",A_ThisFunc,"Could not fill polygon (GDI+ error " . Result . ").")
        Return, this
    }

    FillRectangle(Brush,X,Y,W,H)
    {
        this.CheckRectangle(X,Y,W,H)

        Result := DllCall("gdiplus\GdipFillRectangle","UPtr",this.pGraphics,"UPtr",Brush.pBrush,"Float",X,"Float",Y,"Float",W,"Float",H)
        If Result != 0 ;Status.Ok
            throw Exception("INTERNAL_ERROR",A_ThisFunc,"Could not fill rectangle (GDI+ error " . Result . ").")
        Return, this
    }

    CheckSector(X,Y,W,H,Start,Sweep)
    {
        If X Is Not Number
            throw Exception("INVALID_INPUT",-2,"Invalid X-axis coordinate: " . X)
        If Y Is Not Number
            throw Exception("INVALID_INPUT",-2,"Invalid Y-axis coordinate: " . Y)
        If W < 0
            throw Exception("INVALID_INPUT",-2,"Invalid width: " . W)
        If H < 0
            throw Exception("INVALID_INPUT",-2,"Invalid height: " . H)
        If Start Is Not Number
            throw Exception("INVALID_INPUT",-2,"Invalid start angle: " . Start)
        If Sweep Is Not Number
            throw Exception("INVALID_INPUT",-2,"Invalid sweep angle: " . Sweep)
    }

    CheckRectangle(X,Y,W,H)
    {
        If X Is Not Number
            throw Exception("INVALID_INPUT",-2,"Invalid X-axis coordinate: " . X)
        If Y Is Not Number
            throw Exception("INVALID_INPUT",-2,"Invalid Y-axis coordinate: " . Y)
        If W < 0
            throw Exception("INVALID_INPUT",-2,"Invalid width: " . W)
        If H < 0
            throw Exception("INVALID_INPUT",-2,"Invalid height: " . H)
    }

    CheckPoints(Points,ByRef PointArray)
    {
        Length := Points.MaxIndex()
        If !Length
            throw Exception("INVALID_INPUT",-2,"Invalid point set: " . Points)
        VarSetCapacity(PointArray,Length << 3)
        Offset := 0
        Loop, %Length%
        {
            Point := Points[A_Index]
            If !IsObject(Point)
                throw Exception("INVALID_INPUT",-2,"Invalid point: " . Point)
            PointX := Point[1]
            PointY := Point[2]
            If PointX Is Not Number
                throw Exception("INVALID_INPUT",-2,"Invalid X-axis coordinate: " . PointX)
            If PointY Is Not Number
                throw Exception("INVALID_INPUT",-2,"Invalid X-axis coordinate: " . PointX)

            NumPut(PointX,PointArray,Offset,"Float"), Offset += 4
            NumPut(PointY,PointArray,Offset,"Float"), Offset += 4
        }
        Return, Length
    }
}