#NoEnv
#SingleInstance force
#Persistent
#MaxHotkeysPerInterval 99000000
#HotkeyInterval 99000000
#KeyHistory 0
ListLines Off
Process, Priority, , H
SetBatchLines, -1
SetKeyDelay, -1, -1
SetMouseDelay, -1
SetDefaultMouseSpeed, 0
SetWinDelay, -1
SetControlDelay, -1
SendMode Input
#Include Gdip_All.ahk

; Start GDI+
If !pToken := Gdip_Startup()
{
    MsgBox, 48, gdiplus error!, Gdiplus failed to start. Please ensure you have gdiplus on your system
    ExitApp
}
OnExit, Exit

Font := "Diablo"
If !hFamily := Gdip_FontFamilyCreate(Font)
{
    MsgBox, 48, Font error!, The font you have specified does not exist on the system
    ExitApp
}
Gdip_DeleteFontFamily(hFamily)


GetRunningWindowText(window_title) {
    MouseGetPos,,,WindowUnderMouse
    WinGetTitle, title, ahk_id %WindowUnderMouse%
    Return title == window_title
}

Width := A_ScreenWidth, Height := A_ScreenHeight
Options = x10p y30p w80p Centre cbbffffff r4 s20 Underline Italic
Font = Arial
showUI := True
global drawDebug := False

global f1Pressed := -1
global f3Pressed := -1
global tempX := -1
global tempY := -1
global tempW := -1
global tempH := -1

; Create a layered window (+E0x80000 : must be used for UpdateLayeredWindow to work!) that is always on top (+AlwaysOnTop), has no taskbar entry or caption
Gui, Overlay: -Caption +E0x80000 +E0x20 +LastFound +AlwaysOnTop +ToolWindow +OwnDialogs
; Show the window
Gui, Overlay: Show, NA
; Get a handle to this window we have created in order to update it later
hwnd1 := WinExist()
; Create a GDI bitmap with width and height of the drawing area
hbm := CreateDIBSection(Width, Height)
; Get a device context compatible with the screen
hdc := CreateCompatibleDC()
; Select the bitmap into the device context
obm := SelectObject(hdc, hbm)
; Get a pointer to the graphics of the bitmap for drawing
G := Gdip_GraphicsFromHDC(hdc)
; Set the smoothing mode to antialias = 4 to make shapes appear smoother
Gdip_SetSmoothingMode(G, 4)

Screenshot(x,y,w,h)
{
    screen=%x%|%y%|%w%|%h%
    screenshot := Gdip_BitmapFromScreen(screen)
    return screenshot
}

RotateImage(image, angle)
{
    IWidth := Gdip_GetImageWidth(image)
    IHeight := Gdip_GetImageHeight(image)
    Gdip_GetRotatedDimensions(IWidth, IHeight, angle, RWidth, RHeight)

    ; xTranslation and yTranslation now contain the distance to shift the image by
    Gdip_GetRotatedTranslation(IWidth, IHeight, Angle, xTranslation, yTranslation)

    rotatedBitmap := Gdip_CreateBitmap(RWidth, RHeight)                       ; Create a new bitmap
    GRotated := Gdip_GraphicsFromImage(rotatedBitmap)                                ; Get a pointer to the graphics of the bitmap
    Gdip_SetSmoothingMode(GRotated, 1)
    Gdip_TranslateWorldTransform(GRotated, xTranslation, yTranslation)
    Gdip_RotateWorldTransform(GRotated, angle)
    Gdip_DrawImage(GRotated, image, 0, 0, IWidth, IHeight, 0, 0, IWidth, IHeight)
    ;Gdip_SaveBitmapToFile(rotatedBitmap, "rotated.png")          ; Save the new bitmap to file ## A_ScriptDir . "/Image2.png"
    ;Gdip_ResetWorldTransform(GRotated)
    Gdip_DeleteGraphics(GRotated)                                              ; The graphics may now be deleted
    Gdip_DisposeImage(image)                                          ; Delete the new bitmap
    return rotatedBitmap
}

multiply_colors(color1, color2)
{
    r1 := (color1 >> 16) & 0xFF
    g1 := (color1 >> 8) & 0xFF
    b1 := color1 & 0xFF

    r2 := (color2 >> 16) & 0xFF
    g2 := (color2 >> 8) & 0xFF
    b2 := color2 & 0xFF

    color3 := (0xFF << 24) | ((r1 * r2) >>> 8 << 16) | ((g1 * g2) >>> 8 << 8) | (b1 * b2 >>> 8)
}

generate_random_argb()
{
    Random, Rand, 0, 16777215
    random_color := Format("0xFF{}", Format("{:06X}", Rand))

    return random_color
}

create_pen(section, pScreenshot, solid)
{
     if section.cloneOverrideColor
    {
        ARGB := Gdip_GetPixelColor(pScreenshot, 0, 0, 1)
    }
    Else
    {
        ARGB := Gdip_GetPixelColor(pScreenshot, 0, 0, 1)
    }

    if solid
    {
        return Gdip_BrushCreateSolid(ARGB)
    }
    Else
    {
        return Gdip_CreatePen(ARGB, 10)
    }
}

render_section(section, G, pScreenshot)
{
    if section.cloneOutputType == "Full"
    {
        gPen := create_pen(section, pScreenshot, false)
        Gdip_DrawRectangle(G, gPen, 0, 0, A_ScreenWidth, A_ScreenHeight)
        Gdip_DeletePen(gPen)
    }
    Else if section.cloneOutputType == "Left"
    {
        gPen := create_pen(section, pScreenshot, true)
        Gdip_FillRectangle(G, gPen, -1, -1, 25, A_ScreenHeight+1)
        Gdip_DeleteBrush(gPen)
        if drawDebug {
            debugPen := Gdip_CreatePen(section.cloneColor, 2)
            Gdip_DrawRectangle(G, debugPen, section.x, section.y, section.w, section.h)
            Gdip_DrawLine(G, debugPen, section.x, section.y, 20, A_ScreenHeight/2)
            Gdip_DeletePen(debugPen)
        }
    }
    Else if section.cloneOutputType == "Right"
    {
        gPen := create_pen(section, pScreenshot, true)
        Gdip_FillRectangle(G, gPen, A_ScreenWidth-40, -1, A_ScreenWidth, A_ScreenHeight+1)
        Gdip_DeleteBrush(gPen)
        ;Gdip_DrawRectangle(G, greenPen, A_ScreenWidth-30, 0, A_ScreenWidth, A_ScreenHeight)
        if drawDebug {
            debugPen := Gdip_CreatePen(section.cloneColor, 2)
            Gdip_DrawRectangle(G, debugPen, section.x, section.y, section.w, section.h)
            Gdip_DrawLine(G, debugPen, section.x, section.y, A_ScreenWidth-20, A_ScreenHeight/2)
            Gdip_DeletePen(debugPen)
        }
    }
    Else if section.cloneOutputType == "Top"
    {
        gPen := create_pen(section, pScreenshot, true)
        Gdip_FillRectangle(G, gPen, -1, -1, A_ScreenWidth+1, 20)
        Gdip_DeleteBrush(gPen)
        ;Gdip_DrawRectangle(G, greenPen, A_ScreenWidth-30, 0, A_ScreenWidth, A_ScreenHeight)
        if drawDebug {
            debugPen := Gdip_CreatePen(section.cloneColor, 2)
            Gdip_DrawRectangle(G, debugPen, section.x, section.y, section.w, section.h)
            Gdip_DrawLine(G, debugPen, section.x, section.y, A_ScreenWidth/2, 10)
            Gdip_DeletePen(debugPen)
        }
    }
    Else{
        if section.cloneRotation
        {
            pScreenshot := RotateImage(pScreenshot, section.cloneRotation)
        }
        www := section.w
        hhh := section.h

        if section.cloneOnMouse
        {
            MouseGetPos, xPos, yPos
            xPos := xPos - www/2
            xPos := xPos - hhh
        }
        Else
        {
            xPos := section.dx
            yPos := section.dy
        }
        scale := section.cloneScale ? section.cloneScale : 1
        Gdip_DrawImage(G, pScreenshot, xPos, yPos, www*section.cloneScale, hhh*section.cloneScale, Null, Null, Null, Null, section.cloneTransparency)
        Gdip_DisposeBitmap(pScreenshot)
        if drawDebug {
            debugPen := Gdip_CreatePen(section.cloneColor, 2)
            Gdip_DrawRectangle(G, debugPen, section.x, section.y, section.w, section.h)
            Gdip_DrawRectangle(G, debugPen, section.dx, section.dy, section.w*section.cloneScale, section.h*section.cloneScale)
            Gdip_DrawLine(G, debugPen, section.x, section.y, section.dx, section.dy)

            xx := section.x
            yy := section.y
            Options = x%xx% y%yy% Centre cbbffffff r4 s10
            Gdip_TextToGraphics(G, Format("x:{} y:{}", xx, yy)  , Options, Font, Width, Height)

            xx := section.dx
            yy := section.dy
            Options = x%xx% y%yy% Centre cbbffffff r4 s10
            Gdip_TextToGraphics(G, Format("dx:{} dy:{}", xx, yy)  , Options, Font, Width, Height)
            Gdip_DeletePen(debugPen)
        }
    }
    Gdip_DisposeBitmap(pBitmap)
}

Width := A_ScreenWidth, Height := A_ScreenHeight
iniFilename := Format("settings-{}x{}.ini", Width, Height)
ini := iniObj(iniFilename)

argb := generate_random_argb()
cloneToMove := ""
cloneToMoveTransparency := -1
cloneToMoveScale := 1

if !FileExist(iniFilename)
{
  FileAppend, , %iniFilename%
  MsgBox, File created.
}
Else
{
    ;MsgBox, Using config from %iniFilename%
}

should_render(ini, G)
{
    general := ini["General"]

    pScreenshot := Screenshot(general.enableX,general.enableY,2,2)
    ARGB := Gdip_GetPixelColor(pScreenshot, 0, 0, 1)

    Gdip_DisposeBitmap(pScreenshot)
    return ARGB == general.enableColor
}


;SetTimer, RenderLoop, -1

;~ RenderLoop:
    ;~ active := GetRunningWindowText("Diablo IV")
    ;~ Gdip_GraphicsClear(G)
    ;~ if (showUI and active)
    ;~ {
        ;~ ini := iniObj(iniFilename)

        ;~ render := should_render(ini, G)

        ;~ if(render)
        ;~ {
            ;~ for section_name, section_data in ini {
                ;~ if(section_name != "General")
                ;~ {
                    ;~ pScreenshot := Screenshot(section_data.x,section_data.y,section_data.w,section_data.h)
                    ;~ render_section(section_data, G, pScreenshot)
                ;~ }
                ;~ else
                ;~ {
                    ;~ if(drawDebug) {
                        ;~ debugPen := Gdip_CreatePen(0xffff0000, 1)
                        ;~ Gdip_DrawRectangle(G, debugPen, section_data.enableX-1, section_data.enableY-1, 2, 2)
                        ;~ debugPen := Gdip_CreatePen(0xbbff0000, 1)
                        ;~ Gdip_DrawLine(G, debugPen, Width/2, 0, Width/2, Height)
                        ;~ Gdip_DrawLine(G, debugPen, 0, Height/2, Width, Height/2)
                    ;~ }
                ;~ }
            ;~ }
        ;~ }


    ;~ }
    ;~ UpdateLayeredWindow(hwnd1, hdc, 0, 0, Width, Height)
    ;~ Gdip_DisposeBitmap(pScreenshot)
    ;~ Return

Loop
{
    sT:=A_TickCount
    active := GetRunningWindowText("Diablo IV")
    Gdip_GraphicsClear(G)
    if (showUI and active)
    {
        ini := iniObj(iniFilename)

        render := should_render(ini, G)

        if(render)
        {
            for section_name, section_data in ini {
                if(section_name != "General")
                {
                    pScreenshot := Screenshot(section_data.x,section_data.y,section_data.w,section_data.h)
                    if(section_name != cloneToMove)
                    {
                        render_section(section_data, G, pScreenshot)
                    }
                    else
                    {
                        MouseGetPos , xxxx, yyyy
                        section_data.dx := xxxx - section_data.w
                        section_data.dy := yyyy - section_data.h
                        section_data.cloneTransparency := cloneToMoveTransparency
                        section_data.cloneScale := cloneToMoveScale
                        render_section(section_data, G, pScreenshot)
                    }
                }
                else
                {
                    if(drawDebug) {
                        debugPen := Gdip_CreatePen(0xffff0000, 1)
                        Gdip_DrawRectangle(G, debugPen, section_data.enableX-1, section_data.enableY-1, 2, 2)
                        debugPen := Gdip_CreatePen(0xbbff0000, 1)
                        Gdip_DrawLine(G, debugPen, Width/2, 0, Width/2, Height)
                        Gdip_DrawLine(G, debugPen, 0, Height/2, Width, Height/2)
                        Gdip_DeletePen(debugPen)
                    }
                }
            }
        }

        if(f1Pressed == 0)
        {
            MouseGetPos , tempX, tempY
            tempW := tempX-clonex
            tempH := tempY-cloney
            debugPen := Gdip_CreatePen(0xffff0000, 1)
            Gdip_DrawRectangle(G, debugPen, clonex, cloney, tempW, tempH)
            Gdip_DeletePen(debugPen)
        }

        if(f1Pressed == 1)
        {
            MouseGetPos , tempX2, tempY2
            pScreenshot := Screenshot(clonex,cloney,clonew,cloneh)
            Gdip_DrawImage(G, pScreenshot, tempX2, tempY2, clonew, cloneh)
            Gdip_DisposeBitmap(pScreenshot)
        }


    }
    UpdateLayeredWindow(hwnd1, hdc, 0, 0, Width, Height)
    Gdip_DisposeBitmap(pScreenshot)
    eT:=A_TickCount
    ticks := eT-sT
    if(ticks<16)
    {
        sleepfor := 16-ticks
        DllCall("Sleep","UInt", sleepfor)
    }
}


Exit:
; Release resources
Gdip_DeletePen(greenPen)
Gdip_DeletePen(orangePen)
Gdip_DeletePen(redPen)
Gdip_DeletePen(whitePen)
Gdip_DeleteGraphics(G)
SelectObject(hdc, obm)
DeleteObject(hbm)
DeleteDC(hdc)
Gdip_DeleteFontFamily(hFamily)
Gdip_Shutdown(pToken)
ExitApp

iniObj(iniFilename) {
    ini := []
    IniRead, sections,% iniFilename
    for number, section in StrSplit(sections,"`n") {
        IniRead, keys  ,% iniFilename,% section
        ini[section] := []
        for number, key in StrSplit(keys,"`n") {
            ini[section][StrSplit(key,"=").1] := StrSplit(key,"=").2
            }
        }
    Return ini
}


#IfWinActive Diablo IV
F1::
{
    if(f1Pressed < 0)
    {
        ; first f1 press -> set x,y
        MouseGetPos , clonex, cloney
        f1Pressed := 0
    }
    else if(f1Pressed == 0)
    {
        ; second f1 press -> set w,h
        MouseGetPos , tempxx, tempyy
        clonew := Abs(clonex - tempxx)
        cloneh := Abs(cloney - tempyy)
        f1Pressed := 1
    }
    else if(f1Pressed == 1)
    {
        MouseGetPos , clonedx, clonedy
        Gui, 2:Destroy
        Gui, 2:Add, Text,, Enter the name:
        Gui, 2:Add, Edit, vMyInput,
        Gui, 2:Add, Text,, Transparency:
        Gui, 2:Add, Edit, vMyTransparency,
        Gui, 2:Add, Text,, Rotation:
        Gui, 2:Add, Edit, vMyRotation,
        Gui, 2:Add,Button,gSaveClone wp,Ok
        Gui, 2:Show,,Setup Clone
        ;Goto, SaveClone
    }
    return
}

^F1::
{
    MouseGetPos , enableX, enableY
    pScreenshot := Screenshot(enableX, enableY, 1, 1)
    ARGB := Gdip_GetPixelColor(pScreenshot, 0, 0, 1)
    IniWrite, %ARGB%, %iniFilename%, General, enableColor
    IniWrite, %enableX%, %iniFilename%, General, enableX
    IniWrite, %enableY%, %iniFilename%, General, enableY
    return
}

F2::
{
    MouseGetPos , clonedx, clonedy
    cloneOutputType := "border"

    clonex := clonedx
    cloney := clonedy
    clonew := 8
    cloneh := 8
    clonedx := clonedx
    clonedy := clonedy

    Gui, 2:Destroy
    Gui, 2:Add, Text,, Enter a name:
    Gui, 2:Add, Edit, vMyInput,
    Gui, 2:Add, Text,, Where to put?
    Gui, 2:Add, DropdownList,vMyDropdown,Left|Right|Top|Bottom|Full
    Gui, 2:Add, Text,, Transparency
    Gui, 2:Add, Edit, vMyTransparency,
    Gui, 2:Add,Button,gOkBorder wp,Ok
    Gui, 2:Show,,This is the title
    return
}

SaveClone:
{
    if (clonex > 0 and cloney > 0 and clonew > 0 and cloneh > 0)
    {
        Gui, 2:Hide
        GuiControlGet, MyDropdown,, MyDropdown
        GuiControlGet, MyInput,, MyInput
        GuiControlGet, MyTransparency,, MyTransparency
        GuiControlGet, MyRotation,, MyRotation
        MsgBox, You selected %MyDropdown% and entered %MyInput% with transparency %MyTransparency%.
        vclonename := MyInput
        vwhere := MyDropdown
        vtransparency := MyTransparency
        vrotation := MyRotation

        cloneOutputType := "clone"

        IniWrite, %clonex%, %iniFilename%, clone_%vclonename%, x
        IniWrite, %cloney%, %iniFilename%, clone_%vclonename%, y

        IniWrite, %clonew%, %iniFilename%, clone_%vclonename%, w
        IniWrite, %cloneh%, %iniFilename%, clone_%vclonename%, h

        IniWrite, %clonedx%, %iniFilename%, clone_%vclonename%, dx
        IniWrite, %clonedy%, %iniFilename%, clone_%vclonename%, dy

        IniWrite, %vclonename%, %iniFilename%, clone_%vclonename%, clonename
        IniWrite, %vtransparency%, %iniFilename%, clone_%vclonename%, cloneTransparency
        IniWrite, %cloneOutputType%, %iniFilename%, clone_%vclonename%, cloneOutputType
        IniWrite, %vrotation%, %iniFilename%, clone_%vclonename%, cloneRotation

        IniWrite, %A_ScreenHeight%, %iniFilename%, clone_%vclonename%, height
        IniWrite, %A_ScreenWidth%, %iniFilename%, clone_%vclonename%, width

        random_color := generate_random_argb()
        IniWrite, %random_color%, %iniFilename%, clone_%vclonename%, cloneColor

        clonex := -1
        cloney := -1
        clonew := -1
        cloneh := -1
        clonedx := -1
        clonedy := -1
        f1Pressed := -1
    }
    return
}

; x,y,w,h - defines the region, xxx,yyy is the point we clicked on, r is the angle
did_we_click_on_clone(x,y,w,h, xxx, yyy, s, r)
{
    leftt := x
    rightt := x + (w * s)
    top := y
    bottom := y + (h * s)

    ; Check if mouse is inside
    inside := xxx >= leftt && xxx <= rightt
            && yyy >= top && yyy <= bottom

    return inside
}

F3::
{
    MouseGetPos , xxx, yyy

    if(f3Pressed < 0)
    {
        for section_name, section_data in ini {
            test := did_we_click_on_clone(section_data.dx, section_data.dy, section_data.w, section_data.h, xxx, yyy, section_data.cloneScale ? section_data.cloneScale : 1, section_data.cloneRotation ? section_data.cloneRotation : 0)
            if (test) {
                cloneToMove := section_name
                cloneToMoveTransparency := section_data.cloneTransparency
                cloneToMoveScale := section_data.cloneScale
                f3Pressed := 0
                break
            }
        }
    }
    else if(f3Pressed == 0) {
        ddx := xxx-ini[cloneToMove].w
        ddy := yyy-ini[cloneToMove].h
        IniWrite, %ddx%, %iniFilename%, %cloneToMove%, dx
        IniWrite, %ddy%, %iniFilename%, %cloneToMove%, dy

        IniWrite, %cloneToMoveTransparency%, %iniFilename%, %cloneToMove%, cloneTransparency
        IniWrite, %cloneToMoveScale%, %iniFilename%, %cloneToMove%, cloneScale

        cloneToMove := ""
        cloneToMoveTransparency := -1
        f3Pressed := -1
    }
    return
}

^F3::
{
    MouseGetPos , xxx, yyy
    if(f3Pressed < 0)
    {
        for section_name, section_data in ini {
            if(section_data.cloneOutputType == "clone") {
                test := did_we_click_on_clone(section_data.dx, section_data.dy, section_data.w, section_data.h, xxx, yyy, section_data.cloneScale ? section_data.cloneScale : 1, section_data.cloneRotation ? section_data.cloneRotation : 0)
                if (test) {
                    IniDelete, %iniFilename%, %section_name%
                    f3Pressed := -1
                }
            }
            else
            {
                test := did_we_click_on_clone(section_data.x, section_data.y, section_data.w, section_data.h, xxx, yyy, 1, 0)
                if (test) {
                    IniDelete, %iniFilename%, %section_name%
                    f3Pressed := -1
                }
            }
        }
    }
}

#If (f1Pressed >= 0)
Esc::
{
    clonex := -1
    cloney := -1
    clonew := -1
    cloneh := -1
    clonedx := -1
    clonedy := -1
    f1Pressed := -1
}
#If

#If (f3Pressed == 0)
Esc::
{
    f3Pressed := -1
    cloneToMoveTransparency := 1.0
    cloneToMoveScale := 1.0
}
WheelUp::
{
    cloneToMoveTransparency := cloneToMoveTransparency ? cloneToMoveTransparency : 1.0
    cloneToMoveTransparency := Min(cloneToMoveTransparency + 0.1, 1.0)
    return
}

WheelDown::
{
    cloneToMoveTransparency := cloneToMoveTransparency ? cloneToMoveTransparency : 1.0
    cloneToMoveTransparency := Max(cloneToMoveTransparency - 0.1, 0.0)
    return
}

^WheelUp::
{
    cloneToMoveScale := cloneToMoveScale ? cloneToMoveScale : 1.0
    if(cloneToMoveScale <= 2.0)
    {
        cloneToMoveScale := cloneToMoveScale + 0.1
    }
    return
}

^WheelDown::
{
    cloneToMoveScale := cloneToMoveScale ? cloneToMoveScale : 1.0
    if(cloneToMoveScale >= 0.1)
    {
        cloneToMoveScale := cloneToMoveScale - 0.1
    }
    return
}


#If

OkClone:
    Gui, 2:Hide
    GuiControlGet, MyDropdown,, MyDropdown
    GuiControlGet, MyInput,, MyInput
    GuiControlGet, MyTransparency,, MyTransparency
    MsgBox, You selected %MyDropdown% and entered %MyInput% with transparency %MyTransparency%.
    vclonename := MyInput
    vwhere := MyDropdown
    vtransparency := MyTransparency

    IniWrite, %clonex%, %iniFilename%, clone_%vclonename%, x
    IniWrite, %cloney%, %iniFilename%, clone_%vclonename%, y

    IniWrite, %clonew%, %iniFilename%, clone_%vclonename%, w
    IniWrite, %cloneh%, %iniFilename%, clone_%vclonename%, h

    IniWrite, %clonedx%, %iniFilename%, clone_%vclonename%, dx
    IniWrite, %clonedy%, %iniFilename%, clone_%vclonename%, dy

    IniWrite, %A_ScreenHeight%, %iniFilename%, clone_%vclonename%, height
    IniWrite, %A_ScreenWidth%, %iniFilename%, clone_%vclonename%, width

    IniWrite, %vclonename%, %iniFilename%, clone_%vclonename%, clonename
    IniWrite, 1.0, %iniFilename%, clone_%vclonename%, cloneTransparency
    IniWrite, %vwhere%, %iniFilename%, clone_%vclonename%, cloneOutputType

    random_color := generate_random_argb()
    IniWrite, %random_color%, %iniFilename%, clone_%vclonename%, cloneColor

    clonex := -1
    cloney := -1
    clonew := -1
    cloneh := -1
    clonedx := -1
    clonedy := -1
    IniRead, sections, Filename
    ini := iniObj(iniFilename)

    return

OkBorder:
    Gui, 2:Hide
    GuiControlGet, MyDropdown,, MyDropdown
    GuiControlGet, MyInput,, MyInput
    GuiControlGet, MyTransparency,, MyTransparency
    MsgBox, You selected %MyDropdown% and entered %MyInput% with transparency %MyTransparency%.
    vclonename := MyInput
    vwhere := MyDropdown
    vtransparency := MyTransparency

    IniWrite, %clonex%, %iniFilename%, clone_%vclonename%, x
    IniWrite, %cloney%, %iniFilename%, clone_%vclonename%, y

    IniWrite, %clonew%, %iniFilename%, clone_%vclonename%, w
    IniWrite, %cloneh%, %iniFilename%, clone_%vclonename%, h

    IniWrite, %clonedx%, %iniFilename%, clone_%vclonename%, dx
    IniWrite, %clonedy%, %iniFilename%, clone_%vclonename%, dy

    IniWrite, %A_ScreenHeight%, %iniFilename%, clone_%vclonename%, height
    IniWrite, %A_ScreenWidth%, %iniFilename%, clone_%vclonename%, width

    IniWrite, %vclonename%, %iniFilename%, clone_%vclonename%, clonename
    IniWrite, 1.0, %iniFilename%, clone_%vclonename%, cloneTransparency
    IniWrite, %vwhere%, %iniFilename%, clone_%vclonename%, cloneOutputType

    random_color := generate_random_argb()
    IniWrite, %random_color%, %iniFilename%, clone_%vclonename%, cloneColor

    clonex := -1
    cloney := -1
    clonew := -1
    cloneh := -1
    clonedx := -1
    clonedy := -1
    IniRead, sections, Filename
    ini := iniObj(iniFilename)

    return

F4::
{
    showUI := !showUI
    return
}

F5::
{
    drawDebug := !drawDebug
    return
}
#IfWinActive