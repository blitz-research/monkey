
Private

Global device:InputDevice

Const MAX_JOYSTATES=4

Class JoyState
	Field joyx:Float[2]
	Field joyy:Float[2]
	Field joyz:Float[2]
	Field buttons:Bool[32]
End

Public

Class InputDevice

	Method New()
		For Local i=0 Until MAX_JOYSTATES
			_joyStates[i]=New JoyState
		Next
	End

	Method Reset:Void()
		For Local i=0 Until 512
			_keyDown[i]=False
			_keyHit[i]=0
		Next
		_charGet=0
		_charPut=0
	End

	Method SetKeyboardEnabled:Int( enabled:Bool )
		BBGame.Game().SetKeyboardEnabled enabled
		Return 1
	End

	Method KeyDown:Bool( key:Int )
		If key>0 And key<512 Return _keyDown[key]
		Return False
	End
	
	Method KeyHit:Int( key:Int )
		If key>0 And key<512 Return _keyHit[key]
		Return 0
	End
	
	Method GetChar:Int()
		If _charGet=_charPut Return 0
		Local chr:=_charQueue[_charGet]
		_charGet+=1
		Return chr
	End
	
	Method MouseX:Float()
		Return _mouseX
	End
	
	Method MouseY:Float()
		Return _mouseY
	End

	Method TouchX#( index )
		If index>=0 And index<32 Return _touchX[index]
		Return 0
	End
	
	Method TouchY#( index )
		If index>=0 And index<32 Return _touchY[index]
		Return 0
	End
	
	Method AccelX#()
		Return _accelX
	End
	
	Method AccelY#()
		Return _accelY
	End
	
	Method AccelZ#()
		Return _accelZ
	End
	
	Method JoyX#( index,unit )
		Return _joyStates[unit].joyx[index]
	End
	
	Method JoyY#( index,unit )
		Return _joyStates[unit].joyy[index]
	End
	
	Method JoyZ#( index,unit )
		Return _joyStates[unit].joyz[index]
	End
	
	Method KeyEvent:Void( event:Int,data:Int )
		Select event
		Case BBGameEvent.KeyDown
			If _keyDown[data] Return
			_keyDown[data]=True
			AddKeyHit(data)
			If data=KEY_LMB
				_keyDown[KEY_TOUCH0]=True
				AddKeyHit(KEY_TOUCH0)
			Else If data=KEY_TOUCH0
				_keyDown[KEY_LMB]=True
				AddKeyHit(KEY_LMB)
			Endif
		Case BBGameEvent.KeyUp
			If Not _keyDown[data] Return
			_keyDown[data]=False
			If data=KEY_LMB
				_keyDown[KEY_TOUCH0]=False
			Else If data=KEY_TOUCH0
				_keyDown[KEY_LMB]=False
			Endif
		Case BBGameEvent.KeyChar
			If _charPut<_charQueue.Length
				_charQueue[_charPut]=data
				_charPut+=1
			Endif
		End
	End
	
	Method MouseEvent:Void( event:Int,data:Int,x:Float,y:Float )
		Select event
		Case BBGameEvent.MouseDown
			KeyEvent BBGameEvent.KeyDown,KEY_LMB+data
		Case BBGameEvent.MouseUp
			KeyEvent BBGameEvent.KeyUp,KEY_LMB+data
			Return
		Case BBGameEvent.MouseMove
		Default
			return
		End
		_mouseX=x
		_mouseY=y
		_touchX[0]=x
		_touchY[0]=y
	End
	
	Method TouchEvent:Void( event:Int,data:Int,x:Float,y:Float )
		Select event
		Case BBGameEvent.TouchDown
			KeyEvent BBGameEvent.KeyDown,KEY_TOUCH0+data
		Case BBGameEvent.TouchUp
			KeyEvent BBGameEvent.KeyUp,KEY_TOUCH0+data
			Return
		Case BBGameEvent.TouchMove
		Default
			Return
		End
		_touchX[data]=x
		_touchY[data]=y
		If data=0
			_mouseX=x
			_mouseY=y
		Endif
	End
	
	Method MotionEvent:Void( event:Int,data:Int,x:Float,y:Float,z:Float )
		Select event
		Case BBGameEvent.MotionMove
		Default
			Return			
		End
		_accelX=x
		_accelY=y
		_accelZ=z
	End
	
	Method BeginUpdate:Void()
		For Local i:=0 Until MAX_JOYSTATES
			Local state:=_joyStates[i]
			If Not BBGame.Game().PollJoystick( i,state.joyx,state.joyy,state.joyz,state.buttons ) Exit
			For Local j:=0 Until 32
				Local key:=$100+i*32+j
				If state.buttons[j]
					If Not _keyDown[key]
						_keyDown[key]=True
						AddKeyHit(key)
					Endif
				Else
					_keyDown[key]=False
				Endif
			Next
		Next
	End
	
	Method EndUpdate:Void()
		For Local i=0 Until _keysHitCount
			_keyHit[_keysToClear[i]]=0
		Next
		_keysHitCount=0
		_charGet=0
		_charPut=0
	End

	Const KEY_LMB=1
	Const KEY_TOUCH0=$180

Private

	Method AddKeyHit:Void( key:Int )
		If _keyHit[key] = 0 And _keysHitCount < 32
			_keysToClear[_keysHitCount] = key
			_keysHitCount += 1
		End
		_keyHit[key] += 1
	End

	Field _keysHitCount:Int = 0
	Field _keysToClear:Int[32] '32 inputs per update seems generous
	Field _keyDown:Bool[512]
	Field _keyHit:Int[512]
	Field _charQueue:Int[32]
	Field _charPut:Int
	Field _charGet:Int
	Field _mouseX:Float
	Field _mouseY:Float
	Field _touchX:Float[32]
	Field _touchY:Float[32]
	Field _accelX:Float
	Field _accelY:Float
	Field _accelZ:Float
	Field _joyStates:JoyState[MAX_JOYSTATES]

End
