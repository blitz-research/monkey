
Import builder

Class AndroidNdkBuilder Extends Builder

	Method New( tcc:TransCC )
		Super.New( tcc )
	End
	
	Method Config:String()
		Local config:=New StringStack
		For Local kv:=Eachin GetConfigVars()
			config.Push "#define CFG_"+kv.Key+" "+kv.Value
		Next
		Return config.Join( "~n" )
	End
	
	Method IsValid:Bool()
		Return tcc.ANDROID_PATH<>"" And tcc.ANDROID_NDK_PATH<>""
	End
	
	Method Begin:Void()
		ENV_LANG="cpp"
		_trans=New CppTranslator
	End
	
	Method CreateDirRecursive:Bool( path:String )
		Local i:=0
		Repeat
			i=path.Find( "/",i )
			If i=-1
				CreateDir( path )
				Return FileType( path )=FILETYPE_DIR
			Endif
			Local t:=path[..i]
			CreateDir( t )
			If FileType( t )<>FILETYPE_DIR Return False
			i+=1
		Forever
	End
	
	Method MakeTarget:Void()
		
		SetConfigVar "ANDROID_SDK_DIR",tcc.ANDROID_PATH.Replace( "\","\\" )
		SetConfigVar "ANDROID_MANIFEST_MAIN",GetConfigVar( "ANDROID_MANIFEST_MAIN" ).Replace( ";","~n" )+"~n"
		SetConfigVar "ANDROID_MANIFEST_APPLICATION",GetConfigVar( "ANDROID_MANIFEST_APPLICATION" ).Replace( ";","~n" )+"~n"
		SetConfigVar "ANDROID_MANIFEST_ACTIVITY",GetConfigVar( "ANDROID_MAINFEST_ACTIVITY" ).Replace( ";","~n" )+"~n"
	
		'create data dir
		CreateDataDir "assets/monkey"

		Local app_label:=GetConfigVar( "ANDROID_APP_LABEL" )
		Local app_package:=GetConfigVar( "ANDROID_APP_PACKAGE" )
		
		'translated code
		Local main:=LoadString( "jni/main.cpp" )
		main=ReplaceBlock( main,"TRANSCODE",transCode )
		main=ReplaceBlock( main,"CONFIG",Config() )
		SaveString main,"jni/main.cpp"
		
		DeleteDir "src",True

		'main java file
		Local jmain:=LoadString( "MonkeyGame.java" )
		jmain=ReplaceBlock( jmain,"PACKAGE","package "+app_package+";" )
		Local dir:="src/"+app_package.Replace( ".","/" )
		If Not CreateDirRecursive( dir ) Error "Failed to create dir:"+dir
		SaveString jmain,dir+"/MonkeyGame.java"
		
		'create 'libs' dir		
		For Local lib:=Eachin GetConfigVar( "LIBS" ).Split( ";" )
			Select ExtractExt( lib )
			Case "jar","so"
				Local tdir:=""
				If lib.Contains( "/" )
					tdir=ExtractDir( lib )
					If tdir.Contains( "/" ) tdir=StripDir( tdir )
					Select tdir
					Case "x86","mips","armeabi","armeabi-v7a"
						CreateDir "libs/"+tdir
						tdir+="/"
					Default
						tdir=""
					End
				Endif
				CopyFile lib,"libs/"+tdir+StripDir( lib )
			End
		Next

		'copy src files
		For Local src:=Eachin GetConfigVar( "SRCS" ).Split( ";" )
			Select ExtractExt( src )
			Case "java","aidl"
				Local i:=src.FindLast( "/src/" )
				If i<>-1
					Local dst:=src[i+1..]
					If Not CreateDirRecursive( ExtractDir( dst ) ) Error "Failed to create dir:"+ExtractDir( dst )
					CopyFile src,dst
				Endif
			End
		Next
		
		'templates/
		For Local file:=Eachin LoadDir( "templates",True )
		
			'Recursive CreateDir...	
			Local i:=0
			Repeat
				i=file.Find( "/",i )
				If i=-1 Exit
				CreateDir file[..i]
				If FileType( file[..i] )<>FILETYPE_DIR
					file=""
					Exit
				Endif
				i+=1
			Forever
			If Not file Continue
		
			Select ExtractExt( file ).ToLower()
			Case "xml","properties","java"
				Local str:=LoadString( "templates/"+file )
				str=ReplaceEnv( str )
				SaveString str,file
			Default
				CopyFile "templates/"+file,file
			End
		Next
		
		If tcc.opt_build
		
			If Not Execute( tcc.ANDROID_NDK_PATH+"/ndk-build" )
				Die "Failed to build native code"
			Endif
		
			Local r:=Execute( "ant clean",False ) And Execute( "ant debug install",False )
			
			If Not r
				Die "Android build failed."
			Else If tcc.opt_run
			
				Execute "adb logcat -c",False

				Execute "adb shell am start -n "+app_package+"/"+app_package+".MonkeyGame",False
'				Execute "adb shell am start -n "+app_package+"/com.monkey.AppHelper",False

				Execute "adb logcat [Monkey]:I *:E",False	'?!?!?
'				Execute "adb logcat",False
				'
				'NOTE: This leaves ADB server running which can LOCK the .build dir making it undeletable...
				'
			Endif
		Endif
	End
End
