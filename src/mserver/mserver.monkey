
'VERY simple mserver!
'
'Mainly just so we can get 64bit linux versions up and running...
'
#MSERVER_VERSION="2.0"

#If HOST<>"linux" And HOST<>"macos"
#Error "Host<>linux/macos"
#Endif

#If TARGET<>"glfw"
#Error "Target<>glfw"
#Endif

Import mojo

Import brl.socket
Import brl.process
Import brl.filepath
Import brl.filesystem

#MOJO_AUTO_SUSPEND_ENABLED=False

#If CONFIG="debug"
#GLFW_WINDOW_WIDTH=1024
#GLFW_WINDOW_HEIGHT=768
#Else
#GLFW_WINDOW_WIDTH=320
#GLFW_WINDOW_HEIGHT=240
#Endif
#GLFW_WINDOW_RESIZABLE=True
#GLFW_WINDOW_TITLE="Monkey MiniServer V"+MSERVER_VERSION
#GLFW_WINDOW_RENDER_WHILE_RESIZING=True

Const MSERVER_PORT:=50609

Class FClient Implements IOnSendComplete,IOnReceiveComplete

	Field _socket:Socket
	Field _fserver:FServer
	Field _data:=New DataBuffer( 4096 )
	Field _content:DataBuffer
	
	Method New( socket:Socket,fserver:FServer )
		_socket=socket
		_fserver=fserver
		_socket.ReceiveAsync _data,0,_data.Length,Self
	End
	
	Method OnSendComplete:Void( data:DataBuffer,offset:Int,count:Int,socket:Socket )

		If Not _content
'			MServer.Debug "Closing FClient"
			socket.Close
			Return
		Endif
		
		_socket.SendAsync _content,0,_content.Length,Self
		_content=Null

	End
	
	Method OnReceiveComplete:Void( data:DataBuffer,offset:Int,count:Int,socket:Socket )

		offset+=count
		If offset<4 Or data.PeekString( offset-4,4 )<>"~r~n~r~n"
			socket.ReceiveAsync data,offset,data.Length-offset,Self
			Return
		Endif
		
		Local header:String[]=data.PeekString( 0,offset ).Split( "~r~n" ),req:String[]
		If header.Length>0 req=header[0].Split( " " )
		
		Local response:=New StringStack
		
		If req.Length>1 And req[0].ToLower().Trim()="get"
		
			Local path:=_fserver.RootDir+req[1].Trim()
						
			If FileType( path )=FILETYPE_FILE
			
				MServer.Debug "@"+_fserver.Port()+" GET "+StripDir( path )

				_content=DataBuffer.Load( path )
				response.Push "HTTP/1.1 200 OK"
				response.Push "Content-Type: "+MimeType( ExtractExt( path ) )
				response.Push "Content-Length: "+_content.Length
				response.Push "Connection: close"
			Else
				response.Push "HTTP/1.1 404 Not Found"
				response.Push "Connection: close"
			Endif
		Else
			response.Push "HTTP/1.1 501 Not Implemented"
			response.Push "Connection: close"
		Endif
		
		Local str:=response.Join( "~r~n" )+"~r~n~r~n"
		
'		MServer.Debug str

		socket.SendAsync _data,0,_data.PokeString( 0,str ),Self
		
	End
	
End

Class FServer Implements IOnAcceptComplete

	Field _rootDir:String
	Field _socket:Socket
	
	Method New( rootDir:String,socket:Socket )
		_rootDir=rootDir
		_socket=socket
		_socket.AcceptAsync Self
	End
	
	Method RootDir:String() Property
		Return _rootDir
	End
	
	Method Port:Int() Property
		Return _socket.LocalAddress.Port
	End
	
	Method OnAcceptComplete:Void( socket:Socket,source:Socket )
		New FClient( socket,Self )
		_socket.AcceptAsync Self
	End

End

Class MServer Extends App Implements IOnAcceptComplete

	Field _socket:Socket
	Field _data:=New DataBuffer( 4096 )
	Field _fservers:=New StringMap<FServer>
	global _debug:=New StringStack
	
	Method New( socket:Socket )
		_socket=socket
	End
	
	Method OnCreate:Int()
		_socket.AcceptAsync Self
		SetUpdateRate 10
		Debug "MServer started."
	End
	
	Method OnUpdate:Int()
		UpdateAsyncEvents
	End
	
	Method OnRender:Int()
		Cls
		SetColor 0,255,0
		Local y:=DeviceHeight()-_debug.Length*12
		For Local line:=Eachin _debug
			DrawText line,0,y
			y+=12
		Next
	End
	
	Method OnAcceptComplete:Void( socket:Socket,source:Socket )
		Local msg:=_data.PeekString( 0,socket.Receive( _data,0,_data.Length ) ) 'bit naughty - msg might not fit in a buffer.
		Local reply:="ERROR"
		If msg.StartsWith( "NEW " )
			Local dir:=msg[4..]
			Local fserver:=_fservers.Get( dir )
			If fserver
				Debug "@"+fserver.Port+" OPEN"
			Else
				Local socket:=New Socket( "server" )
				If socket.Bind( "",0 )
					fserver=New FServer( dir,socket )
					_fservers.Set dir,fserver
					Debug "@"+fserver.Port+" NEW "+dir
				Else
					reply="ERROR: couldn't bind server socket"
					Debug reply
				Endif
			Endif
			If fserver reply="OK "+fserver.Port
		Else
			reply="ERROR: Error in message"
			Debug reply
		Endif
		socket.Send _data,0,_data.PokeString( 0,reply )
		socket.Close
		_socket.AcceptAsync Self
	End

	Function Debug:Void( text:String )
		For Local line:=Eachin text.Split( "~r~n" )
			_debug.Push line
		Next
	End
	
End

Function Main()

	Local AppPath:=Process.AppPath()
	Local AppArgs:=Process.AppArgs()
	
#If CONFIG="debug"	
	If AppArgs.Length=1
		AppArgs=[ AppArgs[0],"/Users/marksibly/Desktop/bouncyaliens/bouncyaliens.buildv81b/html5/MonkeyGame.html" ]
'		AppArgs=[ AppArgs[0],"/home/marksibly/desktop/audiotest/audiotest.buildv81b/html5/MonkeyGame.html" ]
	Endif
#Endif

	If AppArgs.Length=1 Or (AppArgs.Length=2 And AppArgs[1]="GO")
	
		Local socket:=New Socket( "server" )
		If Not socket.Bind( "localhost",MSERVER_PORT ) Error "Failed to start MServer"
		
		New MServer( socket )
		
	Else If AppArgs.Length=2
	
		Local socket:=New Socket( "stream" )
		
		If Not socket.Connect( "localhost",MSERVER_PORT )
		
			Execute "~q"+AppPath+"~q GO  >/dev/null 2>/dev/null &"

'			Local proc:=New Process
'			If Not proc.Start( AppPath+" GO" ) Error "Error starting MServer process"
			
			Local err:=True
			For Local i:=0 Until 50
				Process.Sleep 100
				socket.Close
				socket=New Socket( "stream" )
				If Not socket.Connect( "localhost",MSERVER_PORT ) Continue
				err=False
				Exit
			Next
			
			If err Error "Error connecting to MServer (1)"

		Endif
		
		Local path:=AppArgs[1]
		Local data:=New DataBuffer( 1024 )
		
		socket.Send data,0,data.PokeString( 0,"NEW "+ExtractDir( path ) )
		Local reply:=data.PeekString( 0,socket.ReceiveAll( data,0,data.Length ) )
		
		If reply.StartsWith( "OK " )
			Local port:=Int( reply[3..] )
			OpenUrl "http://localhost:"+port+"/"+StripDir( path )
		Else
			Error "Error connecting to MServer (2), reply="+reply
		Endif
		
	Else
	
		Error "MServer command line error"
	
	Endif
		
End

Function MimeType:String( ext:String )

	Select ext.ToLower()
	Case "wav","wave"	Return "audio/wav"
	Case "webm" 		Return "audio/webm"
	Case "ra" 			Return "audio/vnd.rn-realaudio"
	Case "ogg" 			Return "audio/ogg"
	Case "mp3","m4a"	Return "audio/mpeg"
	Case "gif"			Return "image/gif"
	Case "jpeg","jpg","jfif","pjpeg"
						Return "image/jpeg"
	Case "png"			Return "image/png"
	Case "svg"			Return "image/svg+xml"
	Case "tiff","tff"	Return "image/tiff"
	Case "ico","icon","icn"
						Return "image/vnd.microsoft.icon"
	Case "js"			Return "application/javascript"
	Case "xml"			Return "text/xml"
	Case "pdf"			Return "application/pdf"
	Case "zip"			Return "application/zip"
	Case "gzip"			Return "application/gzip"
	Case "cmd"			Return "text/cmd"
	Case "csv"			Return "text/csv"
	Case "css"			Return "text/css"
	Case "txt"			Return "text/plain"
	Case "html","htm"	Return "text/html"
	End Select
	
	Return "text/plain"
	
End Function
