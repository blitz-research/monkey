
#If MOJO_VERSION_X
#Error "Mojo version error"
#Endif

Function FixDataPath:String( path:String )
	Local i:=path.Find( ":/" )
	If i<>-1 And path.Find("/")=i+1 Return path
	If path.StartsWith("./") Or path.StartsWith("/") Return path
	Return "monkey://data/"+path
End
