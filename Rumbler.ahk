#SingleInstance
#Include XInput.ahk

XInput_Init()
global vibrationEnabled := True

OnMessage(0x004A, "Receive_WM_COPYDATA")  ; 0x004A is WM_COPYDATA
return

Receive_WM_COPYDATA(wParam, lParam)
{
    StringAddress := NumGet(lParam + 2*A_PtrSize)  ; Retrieves the CopyDataStruct's lpData member.
    CopyOfData := StrGet(StringAddress)  ; Copy the string out of the structure.
    ; Show it with ToolTip vs. MsgBox so we can return in a timely fashion:
	params := StrSplit(CopyOfData, "|")
	Rumble(params[1], params[2], params[3])
    return true  ; Returning 1 (true) is the traditional way to acknowledge this message.
}

Rumble(rumbleStrength, rumbleLength, rumbleRepeats) {
	if(vibrationEnabled) {

        Loop, % rumbleRepeats
        {
            argh := XInput_SetState(0, 0*257, rumbleStrength*257)
            Sleep, rumbleLength
            argh := XInput_SetState(0, 0*257, 0*257)
        }
    }
    argh := XInput_SetState(0, 0*257, 0*257)
    return
}
