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

class Pen
{
    __New(Color = 0xFFFFFFFF,Width = 1)
    {
        If Color Is Not Integer
            throw Exception("Invalid color: " . Color . ".",-1)
        If Width Is Not Number
            throw Exception("Invalid width: " . Width . ".",-1)

        ObjInsert(this,"",Object())

        ;create the pen
        pPen := 0, Result := DllCall("gdiplus\GdipCreatePen1","UInt",Color,"Float",Width,"UInt",2,"UPtr*",pPen) ;Unit.UnitPixel
        If Result != 0 ;Status.Ok
            throw Exception("Could not create pen (GDI+ error " . Result . ").")
        this.pPen := pPen

        ;set properties
        this.Color := Color
        this.Width := Width
        this.Join := "Miter"
        this.Type := "Solid"
        this.StartCap := "Flat"
        this.EndCap := this.StartCap
    }

    __Delete()
    {
        ;delete the pen
        Result := DllCall("gdiplus\GdipDeletePen","UPtr",this.pPen)
        If Result != 0 ;Status.Ok
            throw Exception("Could not delete pen (GDI+ error " . Result . ").")
    }

    __Get(Key)
    {
        If (Key != "")
            Return, this[""][Key]
    }

    __Set(Key,Value)
    {
        static JoinStyles := Object("Miter",0 ;LineJoin.LineJoinMiter
                                   ,"Bevel",1 ;LineJoin.LineJoinBevel
                                   ,"Round",2) ;LineJoin.LineJoinRound
        static TypeStyles := Object("Solid",0 ;DashStyleSolid
                                   ,"Dash",1 ;DashStyleDash
                                   ,"Dot",2 ;DashStyleDot
                                   ,"DashDot",3) ;DashStyleDashDot
        static CapStyles := Object("Flat",0 ;LineCap.LineCapFlat
                                  ,"Square",1 ;LineCap.LineCapSquare
                                  ,"Round",2 ;LineCap.LineCapRound
                                  ,"Triangle",3) ;LineCap.LineCapTriangle
        If (Key = "Color") ;set pen color
        {
            If Value Is Not Integer
                throw Exception("Invalid color: " . Value . ".",-1)
            Result := DllCall("gdiplus\GdipSetPenColor","UPtr",this.pPen,"UInt",Value)
            If Result != 0 ;Status.Ok
                throw Exception("Could not set pen color (GDI+ error " . Result . ").")
        }
        Else If (Key = "Width") ;set pen width
        {
            If Value Is Not Number
                throw Exception("Invalid width: " . Value . ".",-1)
            Result := DllCall("gdiplus\GdipSetPenWidth","UPtr",this.pPen,"Float",Value)
            If Result != 0 ;Status.Ok
                throw Exception("Could not set pen width (GDI+ error " . Result . ").")
        }
        Else If (Key = "Join") ;set pen line join style
        {
            If !JoinStyles.HasKey(Value)
                throw Exception("Invalid pen join: " . Value . ".")
            Result := DllCall("gdiplus\GdipSetPenLineJoin","UPtr",this.pPen,"UInt",JoinStyles[Value])
            If Result != 0 ;Status.Ok
                throw Exception("Could not set pen join (GDI+ error " . Result . ").")
        }
        Else If (Key = "Type") ;set pen type
        {
            If !TypeStyles.HasKey(Value)
                throw Exception("Invalid pen type: " . Value . ".")
            Result := DllCall("gdiplus\GdipSetPenDashStyle","UPtr",this.pPen,"UInt",TypeStyles[Value])
            If Result != 0 ;Status.Ok
                throw Exception("Could not set type (GDI+ error " . Result . ").")
        }
        Else If (Key = "StartCap") ;set pen start cap
        {
            If !CapStyles.HasKey(Value)
                throw Exception("Invalid pen start cap: " . Value . ".")
            Result := DllCall("gdiplus\GdipSetPenStartCap","UPtr",this.pPen,"UInt",CapStyles[Value])
            If Result != 0 ;Status.Ok
                throw Exception("Could not set pen start cap (GDI+ error " . Result . ").")
        }
        Else If (Key = "EndCap") ;set pen end cap
        {
            If !CapStyles.HasKey(Value)
                throw Exception("Invalid pen end cap: " . Value . ".")
            Result := DllCall("gdiplus\GdipSetPenStartCap","UPtr",this.pPen,"UInt",CapStyles[Value])
            If Result != 0 ;Status.Ok
                throw Exception("Could not set pen end cap (GDI+ error " . Result . ").")
        }
        this[""][Key] := Value
        Return, Value
    }
}