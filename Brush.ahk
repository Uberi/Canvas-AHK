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

class Brush
{
    ; This is supposed to be an abstract class
    __Delete()
    {
        ;delete the brush
        this.CheckStatus(DllCall("gdiplus\GdipDeleteBrush","UPtr",this.pBrush)
            ,"GdipDeleteBrush","Could not delete brush")
    }

    __Get(Key)
    {
        If (Key != "" && Key != "base")
            Return, this[""][Key]
    }

    __Set(Key,Value)
    {
        this[""][Key] := Value
        Return, Value
    }

    StubCheckStatus(Result,Name,Message)
    {
        Return, this
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
}

class SolidBrush extends Canvas.Brush
{
    __New(Color = 0xFFFFFFFF)
    {
        If Color Is Not Integer
            throw Exception("INVALID_INPUT",-1,"Invalid color: " . Color)

        ObjInsert(this,"",Object())

        ;create the brush
        pBrush := 0
        this.CheckStatus(DllCall("gdiplus\GdipCreateSolidFill","UInt",Color,"UPtr*",pBrush)
            ,"GdipCreateSolidFill","Could not create brush")
        this.pBrush := pBrush

        this.Color := Color
    }

    __Set(Key,Value)
    {
        If (Key = "Color") ;set brush color
        {
            If Value Is Not Integer
                throw Exception("INVALID_INPUT",-1,"Invalid color: " . Value)
            this.CheckStatus(DllCall("gdiplus\GdipSetSolidFillColor","UPtr",this.pBrush,"UInt",Value)
                ,"GdipSetSolidFillColor","Could not set brush color")
        }
        this[""][Key] := Value
        Return, Value
    }
}

class LinearGradientBrush extends Canvas.Brush
{
    __New(Point1, Point2, Color1 = 0xFFFFFFFF, Color2 = 0xFFFFFFFF, WrapMode = 0)
    {
        this.CheckPoint(Point1)
        this.CheckPoint(Point2)
        If Color1 Is Not Integer
            throw Exception("INVALID_INPUT",-1,"Invalid color: " . Color1)
        If Color2 Is Not Integer
            throw Exception("INVALID_INPUT",-1,"Invalid color: " . Color2)
        If (WrapMode Is Not Integer or WrapMode < 0 or WrapMode > 4)
            throw Exception("INVALID_INPUT",-1,"Invalid wrap mode: " . WrapMode)

        ObjInsert(this,"",Object())

        ;create the brush
        pBrush := 0
        VarSetCapacity(Point1_, 8)
        NumPut(Point1[1],Point1_,0,"Float")
        NumPut(Point1[2],Point1_,4,"Float")
        VarSetCapacity(Point2_, 8)
        NumPut(Point2[1],Point2_,0,"Float")
        NumPut(Point2[2],Point2_,4,"Float")
        this.CheckStatus(DllCall("gdiplus\GdipCreateLineBrush","UPtr",&Point1_,"UPtr",&Point2_,"UInt",Color1,"UInt",Color2,"Int",WrapMode,"UPtr*",pBrush)
            ,"GdipCreateLineBrush","Could not create brush")
        this.pBrush := pBrush

        this.Point1 := Point1
        this.Point2 := Point2
        this.Color1 := Color1
        this.Color2 := Color2
        this.WrapMode := WrapMode
    }
    
    CheckPoint(Point)
    {
        X := Point[1]
        Y := Point[2]
        If X Is Not Number
            throw Exception("INVALID_INPUT",-2,"Invalid X-axis coordinate: " . X)
        If Y Is Not Number
            throw Exception("INVALID_INPUT",-2,"Invalid Y-axis coordinate: " . Y)
    }
}

class TextureBrush extends Canvas.Brush
{
    __New(Surface, WrapMode = 0, X = 0, Y = 0, W = "", H = "")
    {
        If !Surface.pBitmap
            throw Exception("INVALID_INPUT",-1,"Invalid surface: " . Surface)
        If (WrapMode Is Not Integer or WrapMode < 0 or WrapMode > 4)
            throw Exception("INVALID_INPUT",-1,"Invalid wrap mode: " . WrapMode)

        If (W = "")
            W := Surface.Width
        If (H = "")
            H := Surface.Height
        this.CheckRectangle(X,Y,W,H)

        ObjInsert(this,"",Object())

        ;create the brush
        pBrush := 0
        this.CheckStatus(DllCall("gdiplus\GdipCreateTexture2","UPtr",Surface.pBitmap,"Int",WrapMode,"Float",X,"Float",Y,"Float",W,"Float",H,"UPtr*",pBrush)
            ,"GdipCreateTexture2","Could not create brush")
        this.pBrush := pBrush

        this.Surface := Surface
        this.WrapMode := WrapMode
        this.X := X
        this.Y := Y
        this.W := W
        this.H := H
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

    ; TODO: transforms
}