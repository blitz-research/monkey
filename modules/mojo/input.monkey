
' Module mojo.input
'
' Copyright 2011 Mark Sibly, all rights reserved.
' No warranty implied; use at your own risk.

#If MOJO_VERSION_X
Import mojox.input
#Else

Import keycodes

Private

Import inputdevice

Global device:InputDevice

Public

Function SetInputDevice( dev:InputDevice )
	device=dev
End

Function ResetInput()
	device.Reset()
End

'***** Keyboard *****

Function EnableKeyboard()
	Return device.SetKeyboardEnabled( True )
End

Function DisableKeyboard()
	Return device.SetKeyboardEnabled( False )
End

Function KeyDown( key )
	Return device.KeyDown( key )
End

Function KeyHit( key )
	Return device.KeyHit( key )
End

Function GetChar()
	Return device.GetChar()
End

Function PeekChar( index )
	Return device.PeekChar( index )
End

'***** Mouse *****

Function MouseX#()
	Return device.MouseX()
End

Function MouseY#()
	Return device.MouseY()
End

Function MouseDown( button=MOUSE_LEFT )
	Return device.KeyDown( KEY_LMB+button )
End

Function MouseHit( button=MOUSE_LEFT )
	Return device.KeyHit( KEY_LMB+button )
End

'***** Touch *****

Function TouchX#( index=0 )
	Return device.TouchX( index )
End

Function TouchY#( index=0 )
	Return device.TouchY( index )
End

Function TouchForce#( index=0 )
	Return device.TouchForce( index )
End

Function TouchMaximumPossibleForce#( index= 0)
	Return device.TouchMaximumPossibleForce( index )
End

Function TouchDown( index=0 )
	Return device.KeyDown( KEY_TOUCH0+index )
End

Function TouchHit( index=0 )
	Return device.KeyHit( KEY_TOUCH0+index )
End

'***** Joystick *****

Function JoyX#( index=0,unit=0 )
	Return device.JoyX( index,unit )
End

Function JoyY#( index=0,unit=0 )
	Return device.JoyY( index,unit )
End

Function JoyZ#( index=0,unit=0 )
	Return device.JoyZ( index,unit )
End

Function JoyDown( button,unit=0 )
	Return device.KeyDown( KEY_JOY0 | unit Shl 5 | button )
End

Function JoyHit( button,unit=0 )
	Return device.KeyHit( KEY_JOY0 | unit Shl 5 | button )
End

Function AccelX#()
	Return device.AccelX()
End

Function AccelY#()
	Return device.AccelY()
End

Function AccelZ#()
	Return device.AccelZ()
End

#Endif
