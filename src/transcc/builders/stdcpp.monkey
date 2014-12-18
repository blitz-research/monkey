
Import builder

Class StdcppBuilder Extends Builder

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
		Select HostOS
		Case "winnt"
			If tcc.MINGW_PATH Return True
		Default
			Return True
		End
		Return False
	End

	Method Begin:Void()
		ENV_LANG="cpp"
		_trans=New CppTranslator
	End
	
	Method MakeTarget:Void()
	
		Select ENV_CONFIG
		Case "debug" SetConfigVar "DEBUG","1"
		Case "release" SetConfigVar "RELEASE","1"
		Case "profile" SetConfigVar "PROFILE","1"
		End
		
		Local main:=LoadString( "main.cpp" )

		main=ReplaceBlock( main,"TRANSCODE",transCode )
		main=ReplaceBlock( main,"CONFIG",Config() )

		SaveString main,"main.cpp"
		
		If tcc.opt_build

			Local out:="main_"+HostOS
			DeleteFile out
			
			Local OPTS:="",LIBS:=""
			
			Select ENV_HOST
			Case "winnt"
				OPTS+=" -Wno-free-nonheap-object"
				LIBS+=" -lwinmm -lws2_32"
			Case "macos"
				OPTS+=" -Wno-parentheses -Wno-dangling-else"
				OPTS+=" -mmacosx-version-min=10.6"
			Case "linux"
				OPTS+=" -Wno-unused-result"
				LIBS+=" -lpthread"
			End
			
			Select ENV_CONFIG
			Case "debug"
				OPTS+=" -O0"
			Case "release"
				OPTS+=" -O3 -DNDEBUG"
			End
			
			Local cc_opts:=GetConfigVar( "CC_OPTS" )
			If cc_opts OPTS+=" "+cc_opts.Replace( ";"," " )
			
			Local cc_libs:=GetConfigVar( "CC_LIBS" )
			If cc_libs LIBS+=" "+cc_libs.Replace( ";"," " )
			
			Execute "g++"+OPTS+" -o "+out+" main.cpp"+LIBS
			
			If tcc.opt_run
				Execute "~q"+RealPath( out )+"~q"
			Endif
		Endif
	End
	
End

