
Class Url
	Method New(url:String, scheme:String = "", port:Int = 0)
		Set(url)
		
		'now override with passed in variables
		If scheme.Length _scheme = scheme
		If port > 0 _port = port
	End
	
	Method Set:Void(url:String)
		_url = url
		_scheme = "http"
		_username = ""
		_password = ""
		_domain = ""
		_port = 80
		_path = "/"
		_query = ""
		_fragment = ""
		
		'start parsing url
		Local pos1:Int
		Local pos2:Int
		Local cursor:Int = 0
		
		'find _query and _fragment
		Local queryPos:= url.Find("?")
		Local anchorPos:= url.Find("#")
		
		'find non data length
		Local nonDataLength:Int
		If queryPos = -1 And anchorPos = -1
			'has no _query or _fragment
			nonDataLength = url.Length
		ElseIf queryPos > - 1 And anchorPos > - 1
			If queryPos < anchorPos
				'has _query and _fragment
				nonDataLength = queryPos
			Else
				'has just _fragment
				nonDataLength = anchorPos
				queryPos = -1
			EndIf
		ElseIf queryPos > - 1
			'has _query
			nonDataLength = queryPos
		Else
			'has just _fragment
			nonDataLength = anchorPos
		EndIf
		
		'find _scheme
		pos1 = url.Find("://", cursor)
		If pos1 > - 1 And pos1 < nonDataLength
			_scheme = url[cursor .. pos1]
			'move cursor
			cursor = pos1 + 3
		EndIf
		
		'find _username/_password
		pos1 = url.Find("@", cursor)
		If pos1 > - 1 And pos1 < nonDataLength
			'find split
			pos2 = url.Find(":", cursor)
			If pos2 > - 1 And pos2 < pos1
				'_username and _password
				_username = url[cursor .. pos2]
				_password = url[pos2 + 1 .. pos1]
			Else
				'just _username
				_username = url[cursor .. pos1]
			EndIf
			
			'move cursor
			cursor = pos1 + 1
		EndIf
		
		'find _path and _port so we can figure out the address part
		Local portStart:= url.Find(":", cursor)
		Local pathStart:= url.Find("/", cursor)
		Local serverLength:Int
		
		'fix _port/_path start to be within non data section of url
		If portStart > - 1 And portStart >= nonDataLength portStart = -1
		If pathStart > - 1 And pathStart >= nonDataLength pathStart = -1
		
		If portStart = -1 And pathStart = -1
			'has no _port or _path
			_domain = url[cursor .. nonDataLength]
		ElseIf portStart > - 1 And pathStart > - 1
			If portStart < pathStart
				'has _port and _path
				_domain = url[cursor .. portStart]
				_port = Int(url[portStart + 1 .. pathStart])
				_path = url[pathStart .. nonDataLength]
			Else
				'has just _path
				_domain = url[cursor .. pathStart]
				_path = url[pathStart .. nonDataLength]
			EndIf
		ElseIf portStart > - 1
			'has just _port
			_domain = url[cursor .. portStart]
			_port = Int(url[portStart + 1 .. nonDataLength])
		Else
			'has just _path
			_domain = url[cursor .. pathStart]
			_path = url[pathStart .. nonDataLength]
		EndIf
		
		'find _query
		If queryPos > - 1
			If anchorPos > - 1
				'_query up until _fragment
				_query = url[queryPos + 1 .. anchorPos]
			Else
				'just up until end
				_query = url[queryPos + 1 ..]
			EndIf
		EndIf
		
		'find _fragment
		If anchorPos > - 1 _fragment = url[anchorPos + 1 ..]
	End
	
	Method ToString:String()
		Return _url
	End
	
	Method Scheme:String() Property
		Return _scheme
	End
	
	Method Username:String() Property
		Return _username
	End
	
	Method Password:String() Property
		Return _password
	End
	
	Method Domain:String() Property
		Return _domain
	End
	
	Method Port:Int() Property
		Return _port
	End
	
	Method Path:String() Property
		Return _path
	End
	
	Method Query:String() Property
		Return _query
	End
	
	Method Fragment:String() Property
		Return _fragment
	End
	
	Method FullPath:String() Property
		Local full:=_path
		If _query full+="?"+_query
		If _fragment full+="#"+_fragment
		Return full
	End
	
	Private
	
	Field _url:String
	Field _scheme:String
	Field _username:String
	Field _password:String
	Field _domain:String
	Field _port:Int
	Field _path:String
	Field _query:String
	Field _fragment:String
End

#rem
'test cases
Function Main:Int()
	Local url:= New Url("?query=123")
	Print url.DebugString(", ")
	
	url.Set("?query=123#fragment")
	Print url.DebugString(", ")
	
	url.Set("monkey://?query=123#fragment")
	Print url.DebugString(", ")
	
	url.Set("monkey://:81234?query=123#fragment")
	Print url.DebugString(", ")

	url.Set("monkey://user@?query=123#fragment")
	Print url.DebugString(", ")
		
	url.Set("monkey://user:pass@?query=123#fragment")
	Print url.DebugString(", ")
	
	url.Set("monkey://user:pass@domain.com?query=123#fragment")
	Print url.DebugString(", ")
	
	url.Set("http://user:pass@domain.com/pat/goes/here?query=123#fragment")
	Print url.DebugString(", ")
	
	url.Set("http://user:pass@domain.com#/pat/goes/here?query=123#fragment")
	Print url.DebugString(", ")
End
#end
