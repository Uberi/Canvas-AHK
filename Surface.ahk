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
    __New(Width,Height,Path = "") ;wip: move image loading code to Viewport-like Image class with attach() and load() and save()
    {
        ObjInsert(this,"",Object())

        ;create a memory device context for double buffering use
        this.hMemoryDC := DllCall("CreateCompatibleDC","UPtr",0,"UPtr")
        If !this.hMemoryDC
            throw Exception("INTERNAL_ERROR",A_ThisFunc,"Could not create memory device context (error in CreateCompatibleDC)")

        If (Path = "")
            this.CreateBitmap(Width,Height)
        Else
            this.LoadBitmap(Path)

        ;select the bitmap into the memory device context
        this.hOriginalBitmap := DllCall("SelectObject","UPtr",this.hMemoryDC,"UPtr",this.hBitmap,"UPtr")
        If !this.hOriginalBitmap
            throw Exception("INTERNAL_ERROR",A_ThisFunc,"Could not select bitmap into memory device context (error in SelectObject)")

        ;create a graphics object
        pGraphics := 0
        this.CheckStatus(DllCall("gdiplus\GdipCreateFromHDC","UPtr",this.hMemoryDC,"UPtr*",pGraphics)
            ,"GdipCreateFromHDC","Could not create graphics object")
        this.pGraphics := pGraphics

        this.Transforms := []

        this.Interpolation := "None"
        this.Smooth := "None"
    }

    CreateBitmap(Width,Height)
    {
        If Width < 0
            throw Exception("INVALID_INPUT",-2,"Invalid width: " . Width)
        If Height < 0
            throw Exception("INVALID_INPUT",-2,"Invalid height: " . Height)

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
            throw Exception("INTERNAL_ERROR",A_ThisFunc,"Could not create bitmap (error in CreateDIBSection)")

        this.Width := Width
        this.Height := Height
    }

    LoadBitmap(Path)
    {
        Attributes := FileExist(Path)
        If !Attributes ;path does not exist
            throw Exception("INVALID_INPUT",-1,"Invalid path")
        If InStr(Attributes,"D") ;path is not a file
            throw Exception("INVALID_INPUT",-1,"Invalid file")
        pBitmap := 0
        this.CheckStatus(DllCall("gdiplus\GdipCreateBitmapFromFile", "WStr",Path,"UPtr*",pBitmap)
            ,"GdipCreateBitmapFromFile","Could not create bitmap from file")
        Width := 0
        this.CheckStatus(DllCall("gdiplus\GdipGetImageWidth","UPtr",pBitmap,"UInt*",Width)
            ,"GdipGetImageWidth","Could not obtain image width")
        Height := 0
        this.CheckStatus(DllCall("gdiplus\GdipGetImageHeight","UPtr",pBitmap,"UInt*",Height)
            ,"GdipGetImageHeight","Could not obtain image height")
        hBitmap := 0
        this.CheckStatus(DllCall("gdiplus\GdipCreateHBITMAPFromBitmap","UPtr",pBitmap,"UPtr*",hBitmap,"UPtr",0)
            ,"GdipCreateHBITMAPFromBitmap","Could not obtain bitmap handle from bitmap pointer")

        this.hBitmap := hBitmap
        this.Width := Width
        this.Height := Height
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
                throw Exception("INVALID_INPUT",-1,"Invalid interpolation mode: " . Value)
            this.CheckStatus(DllCall("gdiplus\GdipSetInterpolationMode","UPtr",this.pGraphics,"UInt",InterpolationStyles[Value])
                ,"GdipSetInterpolationMode","Could not set interpolation mode")
        }
        Else If (Key = "Smooth")
        {
            If !SmoothStyles.HasKey(Value)
                throw Exception("INVALID_INPUT",-1,"Invalid smooth mode: " . Value)
            this.CheckStatus(DllCall("gdiplus\GdipSetSmoothingMode","UPtr",this.pGraphics,"UInt",SmoothStyles[Value])
                ,"GdipSetSmoothingMode","Could not set smooth mode")
        }
        this[""][Key] := Value
        Return, Value
    }

    __Delete()
    {
        ;delete the graphics object
        Result := DllCall("gdiplus\GdipDeleteGraphics","UPtr",this.pGraphics)
        If Result != 0 ;Status.Ok
        {
            DllCall("SelectObject","UPtr",this.hMemoryDC,"UPtr",this.hOriginalBitmap,"UPtr") ;deselect the bitmap if present
            DllCall("DeleteObject","UPtr",this.hBitmap) ;delete the bitmap
            DllCall("DeleteDC","UPtr",this.hMemoryDC) ;delete the memory device context
            this.CheckStatus(Result,"GdipDeleteGraphics","Could not delete graphics object")
        }

        ;deselect the bitmap if present
        If !DllCall("SelectObject","UPtr",this.hMemoryDC,"UPtr",this.hOriginalBitmap,"UPtr")
        {
            DllCall("DeleteObject","UPtr",this.hBitmap) ;delete the bitmap
            DllCall("DeleteDC","UPtr",this.hMemoryDC) ;delete the memory device context
            throw Exception("INTERNAL_ERROR",A_ThisFunc,"Could not deselect bitmap from memory device context (error in SelectObject)")
        }

        ;delete the bitmap
        If !DllCall("DeleteObject","UPtr",this.hBitmap)
        {
            DllCall("DeleteDC","UPtr",this.hMemoryDC) ;delete the memory device context
            throw Exception("INTERNAL_ERROR",A_ThisFunc,"Could not delete bitmap (error in DeleteObject)")
        }

        ;delete the memory device context
        If !DllCall("DeleteDC","UPtr",this.hMemoryDC)
            throw Exception("INTERNAL_ERROR",A_ThisFunc,"Could not delete memory device context (error in DeleteDC)")
    }

    Clear(Color = 0x00000000)
    {
        If Color Is Not Integer
            throw Exception("INVALID_INPUT",-1,"Invalid color: " . Color)
        Return, this.CheckStatus(DllCall("gdiplus\GdipGraphicsClear","UPtr",this.pGraphics,"UInt",Color)
            ,"GdipGraphicsClear","Could not clear graphics")
    }

    MeasureText(Format,Value,ByRef Width,ByRef Height) ;wip: streamline and sort
    {
        this.CheckFormat(Format)

        VarSetCapacity(Rectangle,16,0)
        VarSetCapacity(Bounds,16)
        this.CheckStatus(DllCall("gdiplus\GdipMeasureString"
            ,"UPtr",this.pGraphics
            ,"WStr",Value ;string value
            ,"Int",-1 ;null terminated
            ,"UPtr",Format.hFont ;font handle
            ,"UPtr",&Rectangle ;input bounds
            ,"UPtr",Format.hFormat ;string format
            ,"UPtr",&Bounds ;output bounds
            ,"UPtr",0 ;output number of characters that can fit in input bounds
            ,"UPtr",0) ;output number of lines that can fit in input bounds
            ,"GdipMeasureString","Could not measure text bounds")
        Width := NumGet(Bounds,8,"Float")
        Height := NumGet(Bounds,12,"Float")
        Return, this
    }

    Text(Brush,Format,Value,X,Y,W = "",H = "") ;wip: streamline and sort
    {
        this.CheckBrush(Brush)
        this.CheckFormat(Format)

        ;determine dimensions automatically if not specified
        If (W = "")
            W := 0
        If (H = "")
            H := 0

        ;create bounding rectangle
        this.CheckRectangle(X,Y,W,H)
        VarSetCapacity(Rectangle,16)
        NumPut(X,Rectangle,0,"Float")
        NumPut(Y,Rectangle,4,"Float")
        NumPut(W,Rectangle,8,"Float")
        NumPut(H,Rectangle,12,"Float")

        Return, this.CheckStatus(DllCall("gdiplus\GdipDrawString"
            ,"UPtr",this.pGraphics ;graphics handle
            ,"WStr",Value ;string value
            ,"Int",-1 ;null terminated
            ,"UPtr",Format.hFont ;font handle
            ,"UPtr",&Rectangle ;bounding rectangle
            ,"UPtr",Format.hFormat ;string format
            ,"UPtr",Brush.pBrush) ;fill brush
            ,"GdipDrawString","Could not draw text")
    }

    Draw(Surface,X = 0,Y = 0,W = "",H = "",SourceX = 0,SourceY = 0,SourceW = "",SourceH = "") ;wip: streamline
    {
        If !Surface.hBitmap
            throw Exception("INVALID_INPUT",-1,"Invalid surface: " . Surface)

        If (W = "")
            W := this.Width
        If (H = "")
            H := this.Height
        If (SourceW = "")
            SourceW := Surface.Width
        If (SourceH = "")
            SourceH := Surface.Height

        this.CheckRectangle(X,Y,W,H)
        this.CheckRectangle(SourceX,SourceY,SourceW,SourceH)

        pBitmap := 0
        this.CheckStatus(DllCall("gdiplus\GdipCreateBitmapFromHBITMAP","UPtr",Surface.hBitmap,"UPtr",0,"UPtr*",pBitmap)
            ,"GdipCreateBitmapFromHBITMAP","Could not obtain bitmap pointer from bitmap handle")
        this.CheckStatus(DllCall("gdiplus\GdipDrawImageRectRect","UPtr",this.pGraphics,"UPtr",pBitmap
            ,"Float",X,"Float",Y,"Float",W,"Float",H
            ,"Float",SourceX,"Float",SourceY,"Float",SourceW,"Float",SourceH
            ,"Int",2,"UPtr",0,"UPtr",0,"UPtr",0) ;Unit.UnitPixel
            ,"GdipDrawImageRectRect","Could not transfer image data to surface")
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
        pMatrix := 0
        this.CheckStatus(Result := DllCall("gdiplus\GdipCreateMatrix","UPtr*",pMatrix)
            ,"GdipCreateMatrix","Could not create matrix")

        ;obtain current transformation matrix
        Result := DllCall("gdiplus\GdipGetWorldTransform","UPtr",this.pGraphics,"UPtr",pMatrix)
        If Result != 0 ;Status.Ok
        {
            DllCall("gdiplus\GdipDeleteMatrix","UPtr",pMatrix) ;delete temporary matrix
            this.CheckStatus(Result,"GdipGetWorldTransform","Could not obtain transformation matrix")
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
            this.CheckStatus(Result,"GdipGetMatrixElements","Could not obtain matrix elements")
        }

        ;delete temporary matrix
        this.CheckStatus(DllCall("gdiplus\GdipDeleteMatrix","UPtr",pMatrix)
            ,"GdipDeleteMatrix","Could not delete matrix")

        Return, this
    }

    Pop()
    {
        Index := this.Transforms.MaxIndex()
        If !Index
            throw Exception("INVALID_INPUT",-1,"Invalid transformation stack entries")

        ;create temporary matrix to hold elements
        pElements := this.Transforms.GetAddress(Index)
        pMatrix := 0
        this.CheckStatus(DllCall("gdiplus\GdipCreateMatrix2"
            ,"Float",NumGet(pElements + 0,0,"Float")
            ,"Float",NumGet(pElements + 0,4,"Float")
            ,"Float",NumGet(pElements + 0,8,"Float")
            ,"Float",NumGet(pElements + 0,12,"Float")
            ,"Float",NumGet(pElements + 0,16,"Float")
            ,"Float",NumGet(pElements + 0,20,"Float")
            ,"UPtr*",pMatrix)
            ,"GdipCreateMatrix2","Could not create matrix")

        ;set the current transformation matrix
        Result := DllCall("gdiplus\GdipSetWorldTransform","UPtr",this.pGraphics,"UPtr",pMatrix)
        If Result != 0 ;Status.Ok
        {
            DllCall("gdiplus\GdipDeleteMatrix","UPtr",pMatrix) ;delete temporary matrix
            this.CheckStatus(Result,"GdipSetWorldTransform","Could not set transformation matrix")
        }

        ;delete temporary matrix
        this.CheckStatus(DllCall("gdiplus\GdipDeleteMatrix","UPtr",pMatrix)
            ,"GdipDeleteMatrix","Could not delete matrix")

        this.Transforms.Remove(Index)
        Return, this
    }

    Translate(X,Y)
    {
        this.CheckPoint(X,Y)
        Return, this.CheckStatus(DllCall("gdiplus\GdipTranslateWorldTransform","UPtr",this.pGraphics,"Float",X,"Float",Y,"UInt",0) ;MatrixOrder.MatrixOrderPrepend
            ,"GdipTranslateWorldTransform","Could not apply translation matrix")
    }

    Rotate(Angle)
    {
        If Angle Is Not Number
            throw Exception("INVALID_INPUT",-1,"Invalid angle: " . Angle)
        Return, this.CheckStatus(DllCall("gdiplus\GdipRotateWorldTransform","UPtr",this.pGraphics,"Float",Angle,"UInt",0) ;MatrixOrder.MatrixOrderPrepend
            ,"GdipRotateWorldTransform","Could not apply rotation matrix")
    }

    Scale(X,Y)
    {
        this.CheckPoint(X,Y)
        Return, this.CheckStatus(DllCall("gdiplus\GdipScaleWorldTransform","UPtr",this.pGraphics,"Float",X,"Float",Y,"UInt",0) ;MatrixOrder.MatrixOrderPrepend
            ,"GdipScaleWorldTransform","Could not apply scale matrix")
    }

    StubCheckStatus(Result,Name,Message)
    {
        Return, this
    }

    StubCheckPen(Pen)
    {
    }

    StubCheckBrush(Brush)
    {
    }

    StubCheckFormat(Brush)
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

    StubCheckPoint(X,Y)
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
            throw Exception("INVALID_INPUT",-2,"Invalid pen: " . Pen)
    }

    CheckBrush(Brush)
    {
        If !Brush.pBrush
            throw Exception("INVALID_INPUT",-2,"Invalid brush: " . Brush)
    }

    CheckFormat(Format)
    {
        If !(Format.hFontFamily && Format.hFont && Format.hFormat)
            throw Exception("INVALID_INPUT",-2,"Invalid brush: " . Brush)
    }

    CheckLine(X1,Y1,X2,Y2)
    {
        If X1 Is Not Number
            throw Exception("INVALID_INPUT",-2,"Invalid X-axis coordinate: " . X1)
        If Y1 Is Not Number
            throw Exception("INVALID_INPUT",-2,"Invalid Y-axis coordinate: " . Y1)
        If X2 Is Not Number
            throw Exception("INVALID_INPUT",-2,"Invalid width: " . X2)
        If Y2 Is Not Number
            throw Exception("INVALID_INPUT",-2,"Invalid height: " . Y2)
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

    CheckPoint(X,Y)
    {
        If X Is Not Number
            throw Exception("INVALID_INPUT",-2,"Invalid X-axis coordinate: " . X)
        If Y Is Not Number
            throw Exception("INVALID_INPUT",-2,"Invalid Y-axis coordinate: " . Y)
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