
Import os

Function LoadModpath:String()

	Local modpath:=GetEnv( "MODPATH" )
	If modpath Return modpath
	
	Local cfg:=LoadString( "bin/config."+HostOS+".txt" )
	
	For Local line:=Eachin cfg.Split( "~n" )
	
		line=line.Trim()
		If line.StartsWith( "'" ) Continue
		
		Local bits:=line.Split( "=" )
		If bits.Length<>2 Continue
		
		Local key:=bits[0].Trim()
		Local val:=bits[1].Trim()
		
		If key<>"MODPATH" Continue
		
		Local i:=0
		Repeat
			i=val.Find( "${",i )
			If i=-1 Exit
			Local e:=val.Find( "}",i+2 )
			If e=-1 Exit
 			Local t:=val[i+2..e]
			Select t
			Case "MONKEYDIR"
				t=CurrentDir
			Default
				t=GetEnv( t )
			End
			val=val[..i]+t+val[e+1..]
			i+=t.Length
		Forever

		Return val
	Next
	
	Return ""
End
