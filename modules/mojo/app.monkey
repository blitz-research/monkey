
' Module mojo.app
'
' Copyright 2011 Mark Sibly, all rights reserved.
' No warranty implied; use at your own risk.

#If MOJO_VERSION_X
Import mojox.app
#Else

Private

Import graphicsdevice
Import audiodevice
Import inputdevice

Import graphics
Import audio
Import input

Import data

Global _app:App
Global _game:=BBGame.Game()
Global _delegate:GameDelegate
Global _devWidth:Int
Global _devHeight:Int
Global _updateRate:Int
Global _displayModes:DisplayMode[]
Global _desktopMode:DisplayMode

Function EnumDisplayModes:Void()
	Local modes:=_game.GetDisplayModes()
	Local mmap:=New IntMap<DisplayMode>
	Local mstack:=New Stack<DisplayMode>
	For Local i:=0 Until modes.Length
		Local w:=modes[i].width
		Local h:=modes[i].height
		Local size:=w Shl 16 | h
		If mmap.Contains( size )
		Else
			Local mode:=New DisplayMode( modes[i].width,modes[i].height )
			mmap.Insert size,mode
			mstack.Push mode
		Endif
	Next
	_displayModes=mstack.ToArray()
	Local mode:=_game.GetDesktopMode()
	If mode 
		_desktopMode=New DisplayMode( mode.width,mode.height )
	Else
		_desktopMode=New DisplayMode( DeviceWidth,DeviceHeight )
	Endif
End

Function ValidateDeviceWindow:Void( notifyApp:Bool )
	Local w:=_game.GetDeviceWidth()
	Local h:=_game.GetDeviceHeight()
	If w=_devWidth And h=_devHeight Return
	_devWidth=w
	_devHeight=h
	If notifyApp _app.OnResize
End
	
Class GameDelegate Extends BBGameDelegate

	Field _graphics:GraphicsDevice
	Field _audio:AudioDevice
	Field _input:InputDevice
	
	'***** BBGameDelegate *****
	
	Method StartGame:Void()

		_graphics=New GraphicsDevice
		graphics.SetGraphicsDevice _graphics
		graphics.SetFont Null

		_audio=New AudioDevice
		audio.SetAudioDevice _audio

		_input=New InputDevice
		input.SetInputDevice _input
		
		ValidateDeviceWindow False

		EnumDisplayModes
		
		_app.OnCreate()
	End

	Method SuspendGame:Void()
		_app.OnSuspend()
		_audio.Suspend
	End

	Method ResumeGame:Void()
		_audio.Resume
		_app.OnResume()
	End

	Method UpdateGame:Void()
		ValidateDeviceWindow True
		_input.BeginUpdate
		_app.OnUpdate()
		_input.EndUpdate
	End

	Method RenderGame:Void()
		ValidateDeviceWindow True
		Local mode:=_graphics.BeginRender()
		If mode graphics.BeginRender
		If mode=2 _app.OnLoading Else _app.OnRender
		If mode graphics.EndRender
		_graphics.EndRender
	End

	Method KeyEvent:Void( event:Int,data:Int )
		_input.KeyEvent event,data
		If event<>BBGameEvent.KeyDown Return
		Select data
		Case KEY_CLOSE
			_app.OnClose
		Case KEY_BACK
			_app.OnBack
		End
	End

	Method MouseEvent:Void( event:Int,data:Int,x:Float,y:Float )
		_input.MouseEvent event,data,x,y
	End
	
	Method TouchEvent:Void( event:Int,data:Int,x:Float,y:Float )
		_input.TouchEvent event,data,x,y
	End
	
	Method MotionEvent:Void( event:Int,data:Int,x:Float,y:Float,z:Float )
		_input.MotionEvent event,data,x,y,z
	End
	
	Method DiscardGraphics:Void()
		_graphics.DiscardGraphics
	End

End

Public

Class App

	Method New()
		If _app Error "App has already been created"
		_app=Self
		_delegate=New GameDelegate
		_game.SetDelegate _delegate
	End

	Method OnCreate:Int()
	End
	
	Method OnUpdate:Int()
	End
	
	Method OnRender:Int()
	End
	
	Method OnLoading:Int()
	End
	
	Method OnSuspend:Int()
	End
	
	Method OnResume:Int()
	End
	
	Method OnClose:Int()
		EndApp
	End

	Method OnBack:Int()
		OnClose
	End
	
	Method OnResize:Int()
	End
	
End

Class DisplayMode

	Method New( width:Int,height:Int )
		_width=width
		_height=height
	End

	Method Width:Int() Property
		Return _width
	End
	
	Method Height:Int() Property
		Return _height
	End
	
	Private
	
	Field _width:Int
	Field _height:Int
	
End

Function LoadState:String()
	Return _game.LoadState()
End

Function SaveState:Void( state:String )
	_game.SaveState( state )
End

Function LoadString:String( path:String )
	Return _game.LoadString( FixDataPath(path) )
End

Function SetUpdateRate:Void( hertz )
	_updateRate=hertz
	_game.SetUpdateRate hertz
End

Function UpdateRate:Int()
	Return _updateRate
End

Function Millisecs:Int()
	Return _game.Millisecs()
End

Function GetDate:Int[]()
	Local date:Int[7]
	GetDate date
	Return date
End

Function GetDate:Void( date:Int[] )
	_game.GetDate date
End

Function OpenUrl:Void( url:String )
	_game.OpenUrl url
End

Function HideMouse:Void()
	_game.SetMouseVisible False
End

Function ShowMouse:Void()
	_game.SetMouseVisible True
End

Function EndApp:Void()
	Error ""
End

Function DeviceWidth:Int()
	Return _devWidth
End

Function DeviceHeight:Int()
	Return _devHeight
End

Function SetDeviceWindow:Void( width:Int,height:Int,flags:Int )
	_game.SetDeviceWindow( width,height,flags )
	ValidateDeviceWindow False
End

Function SetDisplayMode:Void( width:Int,height:Int,depth:Int,hertz:Int,flags:Int )
	_game.SetDisplayMode width,height,depth,hertz,flags
	ValidateDeviceWindow False
End

Function DisplayModes:DisplayMode[]()
	Return _displayModes
End

Function DesktopMode:DisplayMode()
	Return _desktopMode
End

Function SetSwapInterval:Void( interval:Int )
	_game.SetSwapInterval interval
End

#Endif
