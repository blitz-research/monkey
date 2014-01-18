
Import transcc
Import reflection.reflector

Class Builder

	Method New( tcc:TransCC )
		Self.tcc=tcc
	End
	
	Method IsValid:Bool() Abstract
	
	Method Begin:Void() Abstract
	
	Method MakeTarget:Void() Abstract
	
	Method Make:Void()
	
		Select tcc.opt_config
		Case "","debug"
			tcc.opt_config="debug"
			casedConfig="Debug"
		Case "release" 
			casedConfig="Release"
		Default
			Die "Invalid config"
		End
	
		If FileType( tcc.opt_srcpath )<>FILETYPE_FILE Die "Invalid source file"
		tcc.opt_srcpath=RealPath( tcc.opt_srcpath )

		If Not tcc.opt_modpath tcc.opt_modpath=tcc.monkeydir+"/modules"

		tcc.opt_modpath=".;"+ExtractDir( tcc.opt_srcpath )+";"+tcc.opt_modpath+";"+tcc.monkeydir+"/targets/"+tcc.target.dir+"/modules"
		
		If Not tcc.opt_check
			tcc.opt_check=True
			tcc.opt_update=True
			tcc.opt_build=True
		Endif
		
		ENV_HOST=HostOS
		ENV_CONFIG=tcc.opt_config
		ENV_SAFEMODE=tcc.opt_safe
		ENV_MODPATH=tcc.opt_modpath
		ENV_TARGET=tcc.target.system
			
		Self.Begin

		'***** TRANSLATE *****
		If Not tcc.opt_check Return

		Print "Parsing..."
		
		SetConfigVar "HOST",ENV_HOST
		SetConfigVar "LANG",ENV_LANG
		SetConfigVar "TARGET",ENV_TARGET
		SetConfigVar "CONFIG",ENV_CONFIG
		SetConfigVar "SAFEMODE",ENV_SAFEMODE
		
		app=ParseApp( tcc.opt_srcpath )

		Print "Semanting..."
		If GetConfigVar("REFLECTION_FILTER")
			Local r:=New Reflector
			r.Semant app
		Else
			app.Semant
		Endif
		
		Print "Translating..."
		Local transbuf:=New StringStack
		For Local file$=Eachin app.fileImports
			If ExtractExt( file ).ToLower()=ENV_LANG
				transbuf.Push LoadString( file )
				transbuf.Push "~n"
			Endif
		Next
		transbuf.Push _trans.TransApp( app )
		
		'***** UPDATE *****
		If Not tcc.opt_update Return
		
		Print "Building..."

		transCode=transbuf.Join()
		
		Local buildPath:=StripExt( tcc.opt_srcpath )+".build"
		
		Local targetPath:=buildPath+"/"+tcc.target.dir	'ENV_TARGET

		If tcc.opt_clean
			DeleteDir targetPath,True
			If FileType( targetPath )<>FILETYPE_NONE Die "Failed to clean target dir"
		Endif

		If FileType( targetPath )=FILETYPE_NONE
			If FileType( buildPath )=FILETYPE_NONE CreateDir buildPath
			If FileType( buildPath )<>FILETYPE_DIR Die "Failed to create build dir: "+buildPath
			If Not CopyDir( tcc.monkeydir+"/targets/"+tcc.target.dir+"/template",targetPath,True,False ) Die "Failed to copy target dir"
		Endif
		If FileType( targetPath )<>FILETYPE_DIR Die "Failed to create target dir: "+targetPath
		
		Local cfgPath:=targetPath+"/CONFIG.MONKEY"
		If FileType( cfgPath )=FILETYPE_FILE PreProcess cfgPath
		
		For Local kv:=EachIn GetConfigVars()
			If kv.Key.EndsWith( "_FILES" )
				Local value:=kv.Value.Replace( ";", "|" )
				
				Select kv.Key
					Case "TEXT_FILES"
						TEXT_FILES=value
					Case "IMAGE_FILES"
						IMAGE_FILES=value
					Case "SOUND_FILES"
						SOUND_FILES=value
					Case "MUSIC_FILES"
						MUSIC_FILES=value
				End
			
				If DATA_FILES.Length()>0 DATA_FILES+="|"
				DATA_FILES+=value
			Endif
		Next
	
		Local cd:=CurrentDir

		ChangeDir targetPath
		Self.MakeTarget
		ChangeDir cd

	End
	
	Field tcc:TransCC
	Field app:AppDecl
	Field transCode:String
	Field casedConfig:String
	Field dataFiles:=New StringMap<String>	'maps real src path to virtual target path
	Field DATA_FILES$
	Field TEXT_FILES$
	Field IMAGE_FILES$
	Field SOUND_FILES$
	Field MUSIC_FILES$
	
	Method Execute:Bool( cmd:String,failHard:Bool=True )
		Return tcc.Execute( cmd,failHard )
	End
	
	Method CreateDataDir:Void( dir:String )
		dir=RealPath( dir )
	
		DeleteDir dir,True
		CreateDir dir
		
		Local dataPath:=StripExt( tcc.opt_srcpath )+".data"
		
		If FileType( dataPath )=FILETYPE_DIR
		
			Local srcs:=New StringStack
			srcs.Push dataPath
			
			While Not srcs.IsEmpty()
			
				Local src:=srcs.Pop()
				
				For Local f:=Eachin LoadDir( src )
					If f.StartsWith( "." ) Continue

					Local p:=src+"/"+f
					Local r:=p[dataPath.Length+1..]
					Local t:=dir+"/"+r
					
					Select FileType( p )
					Case FILETYPE_FILE
						If MatchPath( r,DATA_FILES )
							CopyFile p,t
							dataFiles.Set p,r
						Endif
					Case FILETYPE_DIR
						CreateDir t
						srcs.Push p
					End
				Next
			
			Wend
		
		Endif
		
		For Local p:=Eachin app.fileImports
			Local r:=StripDir( p )
			Local t:=dir+"/"+r
			If MatchPath( r,DATA_FILES )
				CopyFile p,t
				dataFiles.Set p,r
			Endif
		Next
		
	End
	
End
