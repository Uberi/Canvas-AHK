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

class Viewport
{
    __New(hWindow)
    {
        this.hWindow := hWindow

        ;obtain a handle to the window device context
        this.hDC := DllCall("GetDC","UPtr",hWindow,"UPtr")
        If !this.hDC
            throw Exception("INTERNAL_ERROR",A_ThisFunc,"Could not obtain window device context.")

        ;subclass window to override WM_PAINT
        this.PaintData := Object()
        ObjAddRef(&this.PaintData) ;add reference to prevent freeing if the canvas object is freed but the paint callback is still called
        this.PaintData.hMemoryDC := 0
        this.PaintData.hPreviousCallback := 0
        this.pCallback := RegisterCallback(this.PaintCallback,"Fast",4,&this.PaintData)
        this.PaintData.hPreviousCallback := DllCall("SetWindowLong" . ((A_PtrSize != 4) ? "Ptr" : ""),"UPtr",hWindow,"Int",-4,"UPtr",this.pCallback,"UPtr") ;GWL_WNDPROC
        If !this.PaintData.hPreviousCallback
            throw Exception("INTERNAL_ERROR",A_ThisFunc,"Could not subclass window.")
    }

    __Delete()
    {
        ;remove subclass of window
        If !DllCall("SetWindowLong" . ((A_PtrSize != 4) ? "Ptr" : ""),"UPtr",this.hWindow,"Int",-4,"UPtr",this.PaintData.hPreviousCallback,"UPtr") ;GWL_WNDPROC
        {
            ObjRelease(&this.PaintData)
            throw Exception("INTERNAL_ERROR",A_ThisFunc,"Could not remove subclass from window.")
        }

        ;remove reference to allow paint data to be freed
        ObjRelease(&this.PaintData)

        ;release the window device context
        If !DllCall("ReleaseDC","UPtr",this.hWindow,"UPtr",this.hDC)
            throw Exception("INTERNAL_ERROR",A_ThisFunc,"Could not release window device context.")
    }

    Attach(Surface)
    {
        this.PaintData.hMemoryDC := Surface.hMemoryDC
        this.Width := Surface.Width
        this.Height := Surface.Height
        Return, this
    }

    Refresh(X = 0,Y = 0,W = 0,H = 0)
    {
        If (X < 0 || X > this.Width)
            throw Exception("INVALID_INPUT",A_ThisFunc,"Invalid X-axis coordinate: " . X)
        If (Y < 0 || Y > this.Height)
            throw Exception("INVALID_INPUT",A_ThisFunc,"Invalid Y-axis coordinate: " . Y)
        If (W < 0 || W > this.Width)
            throw Exception("INVALID_INPUT",A_ThisFunc,"Invalid width: " . W)
        If (H < 0 || H > this.Height)
            throw Exception("INVALID_INPUT",A_ThisFunc,"Invalid height: " . W)

        If W = 0
            W := this.Width
        If H = 0
            H := this.Height

        ;flush the GDI+ drawing batch
        Result := DllCall("gdiplus\GdipFlush","UInt",1) ;FlushIntention.FlushIntentionSync
        If Result != 0 ;Status.Ok
            throw Exception("INTERNAL_ERROR",A_ThisFunc,"Could not flush GDI+ pending rendering operations (GDI+ error " . Result . ").")

        ;set up rectangle structure representing area to redraw
        VarSetCapacity(Rect,16)
        NumPut(X,Rect,0,"UInt")
        NumPut(Y,Rect,4,"UInt")
        NumPut(X + W,Rect,8,"UInt")
        NumPut(Y + H,Rect,12,"UInt")

        ;trigger redrawing of the window
        If !DllCall("InvalidateRect","UPtr",this.hWindow,"UPtr",&Rect,"UInt",0)
            throw Exception("INTERNAL_ERROR",A_ThisFunc,"Could not add rectangle to update region.")
        If !DllCall("UpdateWindow","UPtr",this.hWindow)
            throw Exception("INTERNAL_ERROR",A_ThisFunc,"Could not update window.")

        Return, this
    }

    PaintCallback(Message,wParam,lParam)
    {
        Critical
        PaintData := Object(A_EventInfo)
        hWindow := this

        If Message = 0xF ;WM_PAINT
        {
            ;prepare window for painting
            VarSetCapacity(PaintStruct,A_PtrSize + 60)
            hDC := DllCall("BeginPaint","UPtr",hWindow,"UPtr",&PaintStruct,"UPtr")
            If !hDC
                throw Exception("INTERNAL_ERROR",A_ThisFunc,"Could not prepare window for painting.")

            ;obtain dimensions of update region
            X := NumGet(PaintStruct,A_PtrSize + 4,"UInt")
            Y := NumGet(PaintStruct,A_PtrSize + 8,"UInt")
            W := NumGet(PaintStruct,A_PtrSize + 12,"UInt") - X
            H := NumGet(PaintStruct,A_PtrSize + 16,"UInt") - Y

            ;transfer bitmap from memory device context to window device context
            If PaintData.hMemoryDC && !DllCall("BitBlt","UPtr",hDC,"Int",X,"Int",Y,"Int",W,"Int",H,"UPtr",PaintData.hMemoryDC,"Int",X,"Int",Y,"UInt",0xCC0020) ;SRCCOPY
                throw Exception("INTERNAL_ERROR",A_ThisFunc,"Could not transfer bitmap data from memory device context to window device context.")

            ;finish painting window
            DllCall("EndPaint","UPtr",hWindow,"UPtr",&PaintStruct)
            Return, 0
        }

        ;call the original message handler
        Return, DllCall("CallWindowProc","UPtr",PaintData.hPreviousCallback,"UPtr",hWindow,"UInt",Message,"UInt",wParam,"UInt",lParam,"UPtr")
    }
}