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

        ObjInsert(this,"",Object())

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

        this.Transforms := []

        this.Interpolation := "None"
        this.Smooth := "None"
    }

    __Get(Key)
    {
        If (Key != "")
            Return, this[""][Key]
    }

    __Set(Key,Value)
    {
        static InterpolationStyles := Object("None",5 ;InterpolationMode.InterpolationModeNearestNeighbor
                                            ,"Linear",6 ;InterpolationMode.InterpolationModeHighQualityBilinear
                                            ,"Cubic",7) ;InterpolationMode.InterpolationModeHighQualityBicubic
        static SmoothStyles := Object("None",3 ;SmoothingMode.SmoothingModeNone
                                     ,"Good",4 ;SmoothingMode.SmoothingModeAntiAlias8x4
                                     ,"Best",5) ;SmoothingMode.SmoothingModeAntiAlias8x8
        If (Key = "Interpolation")
        {
            If !InterpolationStyles.HasKey(Value)
                throw Exception("INVALID_INPUT",-1,"Invalid interpolation mode: " . Value . ".")
            Result := DllCall("gdiplus\GdipSetInterpolationMode","UPtr",this.pGraphics,"UInt",InterpolationStyles[Value])
            If Result != 0 ;Status.Ok
                throw Exception("INTERNAL_ERROR",A_ThisFunc,"Could not set interpolation mode (GDI+ error " . Result . ").")
        }
        Else If (Key = "Smooth")
        {
            If !SmoothStyles.HasKey(Value)
                throw Exception("INVALID_INPUT",-1,"Invalid smooth mode: " . Value . ".")
            Result := DllCall("gdiplus\GdipSetSmoothingMode","UPtr",this.pGraphics,"UInt",SmoothStyles[Value])
            If Result != 0 ;Status.Ok
                throw Exception("INTERNAL_ERROR",A_ThisFunc,"Could not set smooth mode (GDI+ error " . Result . ").")
        } ;wip: use setters and getters for transforms
        this[""][Key] := Value
        Return, Value
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
        Return, this.CheckStatus(DllCall("gdiplus\GdipGraphicsClear","UPtr",this.pGraphics,"UInt",Color)
            ,"GdipGraphicsClear","Could not clear graphics")
    }

    DrawArc(Pen,X,Y,W,H,Start,Sweep)
    {
        this.CheckPen(Pen)
        this.CheckSector(X,Y,W,H,Start,Sweep)

        Return, this.CheckStatus(DllCall("gdiplus\GdipDrawArc","UPtr",this.pGraphics,"UPtr",Pen.pPen,"Float",X,"Float",Y,"Float",W,"Float",H,"Float",Start - 90,"Float",Sweep)
            ,"GdipDrawArc","Could not draw arc")
    }

    DrawCurve(Pen,Points,Closed = False)
    {
        this.CheckPen(Pen)
        Length := this.CheckPoints(Points,PointArray)
        If Closed
            Return, this.CheckStatus(DllCall("gdiplus\GdipDrawClosedCurve","UPtr",this.pGraphics,"UPtr",Pen.pPen,"UPtr",&PointArray,"Int",Length)
                ,"GdipDrawClosedCurve","Could not draw curve")
        Return, this.CheckStatus(DllCall("gdiplus\GdipDrawCurve","UPtr",this.pGraphics,"UPtr",Pen.pPen,"UPtr",&PointArray,"Int",Length)
            ,"GdipDrawCurve","Could not draw curve")
    }

    DrawEllipse(Pen,X,Y,W,H)
    {
        this.CheckPen(Pen)
        this.CheckRectangle(X,Y,W,H)
        Return, this.CheckStatus(DllCall("gdiplus\GdipDrawEllipse","UPtr",this.pGraphics,"UPtr",Pen.pPen,"Float",X,"Float",Y,"Float",W,"Float",H)
            ,"GdipDrawEllipse","Could not draw ellipse")
    }

    DrawPie(Pen,X,Y,W,H,Start,Sweep)
    {
        this.CheckPen(Pen)
        this.CheckSector(X,Y,W,H,Start,Sweep)
        Return, this.CheckStatus(DllCall("gdiplus\GdipDrawPie","UPtr",this.pGraphics,"UPtr",Pen.pPen,"Float",X,"Float",Y,"Float",W,"Float",H,"Float",Start - 90,"Float",Sweep)
            ,"GdipDrawPie","Could not draw pie")
    }

    DrawPolygon(Pen,Points)
    {
        this.CheckPen(Pen)
        Length := this.CheckPoints(Points,PointArray)
        Return, this.CheckStatus(DllCall("gdiplus\GdipDrawPolygon","UPtr",this.pGraphics,"UPtr",Pen.pPen,"UPtr",&PointArray,"Int",Length)
            ,"GdipDrawPolygon","Could not draw polygon")
    }

    DrawRectangle(Pen,X,Y,W,H)
    {
        this.CheckPen(Pen)
        this.CheckRectangle(X,Y,W,H)
        Return, this.CheckStatus(DllCall("gdiplus\GdipDrawRectangle","UPtr",this.pGraphics,"UPtr",Pen.pPen,"Float",X,"Float",Y,"Float",W,"Float",H)
            ,"GdipDrawRectangle","Could not draw rectangle")
    }

    FillCurve(Brush,Points)
    {
        this.CheckBrush(Brush)
        Length := this.CheckPoints(Points,PointArray)
        Return, this.CheckStatus(DllCall("gdiplus\GdipFillClosedCurve","UPtr",this.pGraphics,"UPtr",Brush.pBrush,"UPtr",&PointArray,"Int",Length)
            ,"GdipFillClosedCurve","Could not fill curve")
    }

    FillEllipse(Brush,X,Y,W,H)
    {
        this.CheckBrush(Brush)
        this.CheckRectangle(X,Y,W,H)
        Return, this.CheckStatus(DllCall("gdiplus\GdipFillEllipse","UPtr",this.pGraphics,"UPtr",Brush.pBrush,"Float",X,"Float",Y,"Float",W,"Float",H)
            ,"GdipFillEllipse","Could not fill ellipse")
    }

    FillPie(Brush,X,Y,W,H,Start,Sweep)
    {
        this.CheckBrush(Brush)
        this.CheckSector(X,Y,W,H,Start,Sweep)
        Return, this.CheckStatus(DllCall("gdiplus\GdipFillPie","UPtr",this.pGraphics,"UPtr",Brush.pBrush,"Float",X,"Float",Y,"Float",W,"Float",H,"Float",Start - 90,"Float",Sweep)
            ,"GdipFillPie","Could not fill pie")
    }

    FillPolygon(Brush,Points)
    {
        this.CheckBrush(Brush)
        Length := this.CheckPoints(Points,PointArray)
        Return, this.CheckStatus(DllCall("gdiplus\GdipFillPolygon","UPtr",this.pGraphics,"UPtr",Brush.pBrush,"UPtr",&PointArray,"Int",Length)
            ,"GdipFillPolygon","Could not fill polygon")
    }

    FillRectangle(Brush,X,Y,W,H)
    {
        this.CheckBrush(Brush)
        this.CheckRectangle(X,Y,W,H)
        Return, this.CheckStatus(DllCall("gdiplus\GdipFillRectangle","UPtr",this.pGraphics,"UPtr",Brush.pBrush,"Float",X,"Float",Y,"Float",W,"Float",H)
            ,"GdipFillRectangle","Could not fill rectangle")
    }

    Line(Pen,X1,Y1,X2,Y2)
    {
        this.CheckPen(Pen)
        this.CheckLine(X1,Y1,X2,Y2)
        Return, this.CheckStatus(DllCall("gdiplus\GdipDrawLine","UPtr",this.pGraphics,"UPtr",Pen.pPen,"Float",X1,"FLoat",Y1,"Float",X2,"Float",Y2)
            ,"GdipDrawLine","Could not draw line")
    }

    Lines(Pen,Points)
    {
        this.CheckPen(Pen)
        Length := this.CheckPoints(Points,PointArray)
        Return, this.CheckStatus(DllCall("gdiplus\GdipDrawLines","UPtr",this.pGraphics,"UPtr",Pen.pPen,"UPtr",&PointArray,"Int",Length)
            ,"GdipDrawLines","Could not draw lines")
    }

    Push()
    {
        ;create temporary matrix to hold elements
        pMatrix := 0, Result := DllCall("gdiplus\GdipCreateMatrix","UPtr*",pMatrix)
        If Result != 0 ;Status.Ok
            throw Exception("INTERNAL_ERROR",A_ThisFunc,"Could not create matrix (GDI+ error " . Result . " in GdipCreateMatrix).")

        ;obtain current transformation matrix
        Result := DllCall("gdiplus\GdipGetWorldTransform","UPtr",this.pGraphics,"UPtr",pMatrix)
        If Result != 0 ;Status.Ok
        {
            DllCall("gdiplus\GdipDeleteMatrix","UPtr",pMatrix) ;delete temporary matrix
            throw Exception("INTERNAL_ERROR",A_ThisFunc,"Could not obtain transformation matrix (GDI+ error " . Result . " in GdipGetWorldTransform).")
        }

        ;push transformation matrix elements onto stack
        Index := this.Transforms.MaxIndex()
        If Index
            Index ++
        Else
            Index := 1
        this.Transforms.SetCapacity(Index,24)
        Result := DllCall("gdiplus\GdipGetMatrixElements","UPtr",pMatrix,"UPtr",this.Transforms.GetAddress(Index)) ;obtain matrix elements
        If Result != 0 ;Status.Ok
        {
            DllCall("gdiplus\GdipDeleteMatrix","UPtr",pMatrix) ;delete temporary matrix
            throw Exception("INTERNAL_ERROR",A_ThisFunc,"Could not obtain matrix elements (GDI+ error " . Result . " in GdipGetMatrixElements).")
        }

        ;delete temporary matrix
        Result := DllCall("gdiplus\GdipDeleteMatrix","UPtr",pMatrix)
        If Result != 0 ;Status.Ok
            throw Exception("INTERNAL_ERROR",A_ThisFunc,"Could not delete matrix (GDI+ error " . Result . " in GdipDeleteMatrix).")

        Return, this
    }

    Pop()
    {
        Index := this.Transforms.MaxIndex()
        If !Index
            throw Exception("INVALID_INPUT",-1,"No transformation stack entries to pop.")

        ;create temporary matrix to hold elements
        pElements := this.Transforms.GetAddress(Index)
        pMatrix := 0, Result := DllCall("gdiplus\GdipCreateMatrix2"
            ,"Float",NumGet(pElements + 0,0,"Float")
            ,"Float",NumGet(pElements + 0,4,"Float")
            ,"Float",NumGet(pElements + 0,8,"Float")
            ,"Float",NumGet(pElements + 0,12,"Float")
            ,"Float",NumGet(pElements + 0,16,"Float")
            ,"Float",NumGet(pElements + 0,20,"Float")
            ,"UPtr*",pMatrix)
        If Result != 0 ;Status.Ok
            throw Exception("INTERNAL_ERROR",A_ThisFunc,"Could not create matrix (GDI+ error " . Result . " in GdipCreateMatrix3).")

        ;set the current transformation matrix
        Result := DllCall("gdiplus\GdipSetWorldTransform","UPtr",this.pGraphics,"UPtr",pMatrix)
        If Result != 0 ;Status.Ok
        {
            DllCall("gdiplus\GdipDeleteMatrix","UPtr",pMatrix) ;delete temporary matrix
            throw Exception("INTERNAL_ERROR",A_ThisFunc,"Could not set transformation matrix (GDI+ error " . Result . " in GdipSetWorldTransform).")
        }

        ;delete temporary matrix
        Result := DllCall("gdiplus\GdipDeleteMatrix","UPtr",pMatrix)
        If Result != 0 ;Status.Ok
            throw Exception("INTERNAL_ERROR",A_ThisFunc,"Could not delete matrix (GDI+ error " . Result . " in GdipDeleteMatrix).")

        this.Transforms.Remove(Index)
        Return, this
    }

    Translate(X,Y)
    {
        Return, this.CheckStatus(DllCall("gdiplus\GdipTranslateWorldTransform","UPtr",this.pGraphics,"Float",X,"Float",Y,"UInt",0) ;MatrixOrder.MatrixOrderPrepend
            ,"GdipTranslateWorldTransform","Could not apply translation matrix")
    }

    Rotate(Angle)
    {
        Return, this.CheckStatus(DllCall("gdiplus\GdipRotateWorldTransform","UPtr",this.pGraphics,"Float",Angle,"UInt",0) ;MatrixOrder.MatrixOrderPrepend
            ,"GdipRotateWorldTransform","Could not apply rotation matrix")
    }

    Scale(X,Y)
    {
        Return, this.CheckStatus(DllCall("gdiplus\GdipScaleWorldTransform","UPtr",this.pGraphics,"Float",X,"Float",Y,"UInt",0) ;MatrixOrder.MatrixOrderPrepend
            ,"GdipScaleWorldTransform","Could not apply scale matrix")
    }

    StubCheckStatus(a,b,c) ;wip
    {
        Return, this
    }

    StubCheckPen(Pen)
    {
    }

    StubCheckBrush(Brush)
    {
    }

    StubCheckLine(X1,Y1,X2,Y2)
    {
    }

    StubCheckRectangle(X,Y,W,H)
    {
    }

    StubCheckSector(X,Y,W,H,Start,Sweep)
    {
    }

    StubCheckPoints(Points,ByRef PointArray)
    {
        Length := Points.MaxIndex()
        VarSetCapacity(PointArray,Length << 3)
        Offset := 0
        Loop, %Length%
        {
            Point := Points[A_Index]
            NumPut(Point[1],PointArray,Offset,"Float"), Offset += 4
            NumPut(Point[2],PointArray,Offset,"Float"), Offset += 4
        }
        Return, Length
    }

    CheckStatus(Result,Name,Message)
    {
        static StatusValues := ["Status.GenericError"
                               ,"Status.InvalidParameter"
                               ,"Status.OutOfMemory"
                               ,"Status.ObjectBusy"
                               ,"Status.InsufficientBuffer"
                               ,"Status.NotImplemented"
                               ,"Status.Win32Error"
                               ,"Status.WrongState"
                               ,"Status.Aborted"
                               ,"Status.FileNotFound"
                               ,"Status.ValueOverflow"
                               ,"Status.AccessDenied"
                               ,"Status.UnknownImageFormat"
                               ,"Status.FontFamilyNotFound"
                               ,"Status.FontStyleNotFound"
                               ,"Status.NotTrueTypeFont"
                               ,"Status.UnsupportedGdiplusVersion"
                               ,"Status.GdiplusNotInitialized"
                               ,"Status.PropertyNotFound"
                               ,"Status.PropertyNotSupported"
                               ,"Status.ProfileNotFound"]
        If Result != 0 ;Status.Ok
            throw Exception("INTERNAL_ERROR",-1,Message . " (GDI+ error " . StatusValues[Result] . " in " . Name . ")")
        Return, this
    }

    CheckPen(Pen)
    {
        If !Pen.pPen
            throw Exception("INVALID_INPUT",-2,"Invalid pen: " . Pen . ".")
    }

    CheckBrush(Brush)
    {
        If !Brush.pBrush
            throw Exception("INVALID_INPUT",-2,"Invalid brush: " . Brush . ".")
    }

    CheckLine(X1,Y1,X2,Y2)
    {
        If X1 Is Not Number
            throw Exception("INVALID_INPUT",-2,"Invalid X-axis coordinate: " . X1 . ".")
        If Y1 Is Not Number
            throw Exception("INVALID_INPUT",-2,"Invalid Y-axis coordinate: " . Y1 . ".")
        If X2 Is Not Number
            throw Exception("INVALID_INPUT",-2,"Invalid width: " . X2 . ".")
        If Y2 Is Not Number
            throw Exception("INVALID_INPUT",-2,"Invalid height: " . Y2 . ".")
    }

    CheckRectangle(X,Y,W,H)
    {
        If X Is Not Number
            throw Exception("INVALID_INPUT",-2,"Invalid X-axis coordinate: " . X . ".")
        If Y Is Not Number
            throw Exception("INVALID_INPUT",-2,"Invalid Y-axis coordinate: " . Y . ".")
        If W < 0
            throw Exception("INVALID_INPUT",-2,"Invalid width: " . W . ".")
        If H < 0
            throw Exception("INVALID_INPUT",-2,"Invalid height: " . H . ".")
    }

    CheckSector(X,Y,W,H,Start,Sweep)
    {
        If X Is Not Number
            throw Exception("INVALID_INPUT",-2,"Invalid X-axis coordinate: " . X . ".")
        If Y Is Not Number
            throw Exception("INVALID_INPUT",-2,"Invalid Y-axis coordinate: " . Y . ".")
        If W < 0
            throw Exception("INVALID_INPUT",-2,"Invalid width: " . W . ".")
        If H < 0
            throw Exception("INVALID_INPUT",-2,"Invalid height: " . H . ".")
        If Start Is Not Number
            throw Exception("INVALID_INPUT",-2,"Invalid start angle: " . Start . ".")
        If Sweep Is Not Number
            throw Exception("INVALID_INPUT",-2,"Invalid sweep angle: " . Sweep . ".")
    }

    CheckPoints(Points,ByRef PointArray)
    {
        Length := Points.MaxIndex()
        If !Length
            throw Exception("INVALID_INPUT",-2,"Invalid point set: " . Points . ".")
        VarSetCapacity(PointArray,Length << 3)
        Offset := 0
        Loop, %Length%
        {
            Point := Points[A_Index]
            If !IsObject(Point)
                throw Exception("INVALID_INPUT",-2,"Invalid point: " . Point . ".")
            PointX := Point[1]
            PointY := Point[2]
            If PointX Is Not Number
                throw Exception("INVALID_INPUT",-2,"Invalid X-axis coordinate: " . PointX . ".")
            If PointY Is Not Number
                throw Exception("INVALID_INPUT",-2,"Invalid X-axis coordinate: " . PointX . ".")

            NumPut(PointX,PointArray,Offset,"Float"), Offset += 4
            NumPut(PointY,PointArray,Offset,"Float"), Offset += 4
        }
        Return, Length
    }
}