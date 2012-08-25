class Format
{
    __New(Typeface,Size)
    {
        If Size Is Not Number
            throw Exception("INVALID_INPUT",-1,"Invalid size: " . Size)

        ObjInsert(this,"",Object())

        ;create string format
        hFormat := 0
        this.CheckStatus(DllCall("gdiplus\GdipCreateStringFormat","Int",0x800,"Int",0,"Ptr*",hFormat) ;StringFormat.StringFormatFlagsMeasureTrailingSpaces, LANG_NEUTRAL
            ,"GdipCreateStringFormat","Could not create string format")

        this.hFormat := hFormat

        this[""].Typeface := Typeface
        this[""].Size := Size

        this[""].Bold := False
        this[""].Italic := False
        this[""].Underline := False
        this[""].Strikeout := False

        this.CreateFont()
    }

    CreateFont()
    {
        ;create font family
        hFontFamily := 0
        this.CheckStatus(DllCall("gdiplus\GdipCreateFontFamilyFromName","WStr",this.Typeface,"UPtr",0,"UPtr*",hFontFamily)
            ,"GdipCreateFontFamilyFromName","Could not create font family")

        ;determine font style
        Style := 0 ;FontStyle.FontStyleRegular
        If this.Bold
            Style |= 1 ;FontStyle.FontStyleBold
        If this.Italic
            Style |= 2 ;FontStyle.FontStyleItalic
        If this.Underline
            Style |= 4 ;FontStyle.FontStyleUnderline
        If this.Strikeout
            Style |= 8 ;FontStyle.FontStyleStrikeout

        ;create font
        hFont := 0, Result := DllCall("gdiplus\GdipCreateFont","UPtr",hFontFamily,"Float",this.Size,"Int",Style,"UInt",2,"UPtr*",hFont) ;Unit.UnitPixel
        If Result != 0 ;Status.Ok
        {
            DllCall("gdiplus\GdipDeleteFontFamily","UPtr",hFontFamily) ;delete font family
            this.CheckStatus(Result,"GdipCreateFont","Could not create font")
        }

        this.hFontFamily := hFontFamily
        this.hFont := hFont
    }

    __Delete()
    {
        ;delete font
        Result := DllCall("gdiplus\GdipDeleteFont","UPtr",this.hFont)
        If Result != 0
        {
            DllCall("gdiplus\GdipDeleteFontFamily","UPtr",this.hFontFamily) ;delete font family
            DllCall("gdiplus\GdipDeleteStringFormat","UPtr",this.hFormat) ;delete string format
            this.CheckStatus(Result,"GdipDeleteFont","Could not delete font")
        }

        ;delete font family
        Result := DllCall("gdiplus\GdipDeleteFontFamily","UPtr",this.hFontFamily)
        If Result != 0 ;Status.Ok
        {
            DllCall("gdiplus\GdipDeleteStringFormat","UPtr",this.hFormat) ;delete string format
            this.CheckStatus(Result,"GdipDeleteFontFamily","Could not delete font family")
        }

        ;delete string format
        this.CheckStatus(DllCall("gdiplus\GdipDeleteStringFormat","UPtr",this.hFormat)
            ,"GdipDeleteStringFormat","Could not delete string format")
    }

    __Get(Key)
    {
        If (Key != "")
            Return, this[""][Key]
    }

    __Set(Key,Value)
    {
        static AlignStyles := Object("Left",0 ;StringAlignment.StringAlignmentNear
                                   ,"Center",1 ;StringAlignment.StringAlignmentCenter
                                   ,"Right",2) ;StringAlignment.StringAlignmentFar
        If (Key = "Size")
        {
            If Value Is Not Number
                throw Exception("INVALID_INPUT",-1,"Invalid size: " . Value)
            this[""].Size := Value
            this.CreateFont() ;wip: delete old first
        }
        Else If (Key = "Typeface" || Key = "Bold" || Key = "Italic" || Key = "Underline" || Key = "Strikeout")
        {
            this[""][Key] := Value
            this.CreateFont() ;wip: delete old first
        }
        Else If (Key = "Align")
        {
            If !AlignStyles.HasKey(Value)
                throw Exception("INVALID_INPUT",-1,"Invalid alignment: " . Value)
            this.CheckStatus(DllCall("gdiplus\GdipSetStringFormatAlign","UPtr",this.hFormat,"UInt",AlignStyles[Value])
                ,"GdipSetStringFormatAlign","Could not set string format alignment")
            this[""].Align := Value
        }
        Else
            this[""][Key] := Value
        Return, Value
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