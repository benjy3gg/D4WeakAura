# D4 "WeakAura"
let's you create custom overlays by capturing specific regions on your screen.
doesn't access/alter game memory in any way!

## Prerequisited
- Get Autohotkey V1 -> https://www.autohotkey.com/ -> Download v1.1
## How to start
- Double click on D4WeakAura.ahk
- Loads settings from settings-{ScreenWidth}x{ScreenHeight}.ini
- This starts the overlay
- Configured with basic Overlay
    - Healthbar
    - Resourcebar
    - Trigger-Pixel (resposible for showing/hiding the UI)
        - UI is hidden when Map is visible
- Press F4 to toggle UI
- Press F5 to show help and debug view
    - in debug mode you can see the rectangles that are captured and where they are displayed, indicated by a line of the same color

![](./images/Setup_Debug_Help.gif)

----------------------------------------

## How to configure
### Rectangle Clone Mode
![](./images/Setup_new_Overlay.gif)
    
    - Used for Cooldowns or healthbar/resourcebar
    - Press F1 to starting point for new rectangle
    - Rectangle is drawn from starting point to current mouse position
    - Press F1 again to stop drawing the rectangle
    - Configuration window pops up
        - set a unique identifier (e.g. "skill1")
        - set transparency for the overlay
        - set rotation for the overlay
    - Press Okay
    - The new overlay is immediatly added

### Edit Rectangle Clone
![](./images/F3_Edit_Mode.gif)

    - Mouse over overlay
    - Press F3
    - Overlay moves to mouseposition
    - scrollwheel changes transparency
    - ctrl+scrollwheel changes scale
    - Press F3 again to save

### Delete Rectangle Clone

    - Mouse over overlay
    - Press ctrl+F3

### Pixel Clone Mode
    - Useful for cooldowns in peripheral vision
    - Press F2 to select a pixel on the screen
    - The position and color of this pixel is saved
    - Configuration window pops up
        - set a unique identifier (e.g. "skill1")
        - "Where to display"
            - the Pixel Clone Mode takes the color value of the selected pixel 
            - displays it at the borders of the screen (Top/Left/Right/Full)
        - set transparency for the overlay (doesn't work for now)

### Vibrate Mode
    - Useful for cooldowns
    - Setup the same as Pixel Clone Mode
    - Select Vibrate for "Where to display"
    - Configure the vibration strength in the Modifier input
    - Start the "Rumber.ahk" script to enable the rumble
    - This sends the rumble to the first connected XInput Gamepad
