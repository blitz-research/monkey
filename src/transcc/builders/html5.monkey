
Import builder

Import brl.filestream

Private

Global Info_Width:Int
Global Info_Height:Int

Function GetInfo_PNG:Int( path:String )
	Local f:=FileStream.Open( path,"r" )
	If f
		Local data:=New DataBuffer( 32 )
		Local n:=f.Read( data,0,24 )
		f.Close
		If n=24 And data.PeekByte(1)="P"[0] And data.PeekByte(2)="N"[0] And data.PeekByte(3)="G"[0]
			Info_Width=(data.PeekByte(16)&255) Shl 24 | (data.PeekByte(17)&255) Shl 16 | (data.PeekByte(18)&255) Shl 8 | (data.PeekByte(19)&255)
			Info_Height=(data.PeekByte(20)&255) Shl 24 | (data.PeekByte(21)&255) Shl 16 | (data.PeekByte(22)&255) Shl 8 | (data.PeekByte(23)&255)
			Return 0
		Endif
	Endif
	Return -1
End

Function GetInfo_GIF:Int( path:String )
	Local f:=FileStream.Open( path,"r" )
	If f
		Local data:=New DataBuffer( 32 )
		Local n:=f.Read( data,0,10 )
		f.Close
		If n=10 And data.PeekByte(0)="G"[0] And data.PeekByte(1)="I"[0] And data.PeekByte(2)="F"[0]
			Info_Width=(data.PeekByte(7)&255) Shl 8 | (data.PeekByte(6)&255)
			Info_Height=(data.PeekByte(9)&255) Shl 8 | (data.PeekByte(8)&255)
			Return 0
		Endif
	Endif
	Return -1
End

Function GetInfo_JPG:Int( path:String )
	Local f:=FileStream.Open( path,"r" )
	If f
		Local buf:=New DataBuffer( 32 )
		
		If f.Read( buf,0,2 )=2 And (buf.PeekByte(0)&255)=$ff And (buf.PeekByte(1)&255)=$d8
			Repeat

				While f.Read( buf,0,1 )=1  And (buf.PeekByte(0)&255)<>$ff
				Wend
				If f.Eof() Exit
				
				While f.Read( buf,0,1 )=1  And (buf.PeekByte(0)&255)=$ff
				Wend
				If f.Eof() Exit

				Local marker:=buf.PeekByte(0)&255
				Select marker
				Case $d0,$d1,$d2,$d3,$d4,$d5,$d6,$d7,$d8,$d9,$00,$ff
					Continue
				End

				If f.Read( buf,0,2 )<>2 Exit
				Local datalen:=((buf.PeekByte(0)&255) Shl 8 | (buf.PeekByte(1)&255))-2
				
				Select marker
				Case $c0,$c1,$c2,$c3
					If datalen And f.Read( buf,0,5 )=5
						Local bpp:=buf.PeekByte(0)&255
						Info_Width=(buf.PeekByte(3)&255) Shl 8 | (buf.PeekByte(4)&255)
						Info_Height=(buf.PeekByte(1)&255) Shl 8 | (buf.PeekByte(2)&255)
						f.Close
						Return 0
					Endif
				End
				
				Local pos:=f.Position+datalen
				If f.Seek( pos )<>pos Exit
				
			Forever
		Endif
		f.Close
	Endif
	Return -1
End

Public

Class Html5Builder Extends Builder

	Method New( tcc:TransCC )
		Super.New( tcc )
	End
	
	Method Config:String()
		Local config:=New StringStack
		For Local kv:=Eachin GetConfigVars()
			config.Push "CFG_"+kv.Key+"="+Enquote( kv.Value,"js" )+";"
		Next
		Return config.Join( "~n" )
	End
	
	Method MetaData:String()
		Local meta:=New StringStack
		For Local kv:=Eachin dataFiles
			Local src:=kv.Key
			Local ext:=ExtractExt( src ).ToLower()
			Select ext
			Case "png","jpg","gif"
				Info_Width=0
				Info_Height=0
				Select ext
				Case "png" GetInfo_PNG( src )
				Case "jpg" GetInfo_JPG( src )
				Case "gif" GetInfo_GIF( src )
				End
				If Info_Width=0 Or Info_Height=0 Die "Unable to load image file '"+src+"'."
				meta.Push "["+kv.Value+"];type=image/"+ext+";"
				meta.Push "width="+Info_Width+";"
				meta.Push "height="+Info_Height+";"
				meta.Push "\n"
			Case "wav", "ogg", "mp3", "m4a"
				meta.Push "[" + kv.Value + "];type=sound/" + ext + ";"
				meta.Push "\n"
			End
		Next
		Return meta.Join("")
	End
	
	Method IsValid:Bool()
		Return True
	End
	
	Method Begin:Void()
		ENV_LANG="js"
		_trans=New JsTranslator
	End
	
	Method MakeTarget:Void()

		CreateDataDir "data"

		Local meta:="var META_DATA=~q"+MetaData()+"~q;~n"
		
		Local main:=LoadString( "main.js" )
		
		main=ReplaceBlock( main,"TRANSCODE",transCode )
		main=ReplaceBlock( main,"METADATA",meta )
		main=ReplaceBlock( main,"CONFIG",Config() )
		
		SaveString main,"main.js"
		
		If tcc.opt_run
			Local p:=RealPath( "MonkeyGame.html" )
			Local t:=tcc.HTML_PLAYER+" ~q"+p+"~q"
			Execute t,False
		Endif
	End
	
End