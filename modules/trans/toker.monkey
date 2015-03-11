
' Module trans.toker
'
' Placed into the public domain 24/02/2011.
' No warranty implied; use at your own risk.

Import trans

'toke_type
Const TOKE_EOF=0
Const TOKE_SPACE=1
Const TOKE_IDENT=2
Const TOKE_KEYWORD=3
Const TOKE_INTLIT=4
Const TOKE_FLOATLIT=5
Const TOKE_STRINGLIT=6
Const TOKE_STRINGLITEX=7
Const TOKE_SYMBOL=8
Const TOKE_LINECOMMENT=9

'***** Tokenizer *****
Class Toker

	Global _symbols:StringSet
	Global _keywords:StringSet

	Field _path$
	Field _line
	Field _source$
	Field _length
	Field _toke$
	Field _tokeType
	Field _tokePos
	
	Method _init()
		If _keywords Return
		
		Const keywords:="void strict "+
		"public private property internal "+
		"bool int float string array object mod continue exit "+
		"include import module extern "+
		"new self super eachin true false null not "+
		"extends abstract final select case default "+
		"const local global field method function class "+
		"and or shl shr end if then else elseif endif while wend repeat until forever "+
		"for to step next return "+
		"interface implements inline alias try catch throw throwable"

		_keywords=New StringSet
		For Local t:=Eachin keywords.Split( " " )
			_keywords.Insert t
		Next
		_symbols=New StringSet
		_symbols.Insert ".."
		_symbols.Insert ":="
		_symbols.Insert "*="
		_symbols.Insert "/="
		_symbols.Insert "+="
		_symbols.Insert "-="
		_symbols.Insert "|="
		_symbols.Insert "&="
		_symbols.Insert "~~="
	End
	
	Method New( path$,source$ )
		_init
		_path=path
		_line=1
		_source=source
		_length=_source.Length
		_toke=""
		_tokeType=TOKE_EOF
		_tokePos=0
	End
	
	Method New( toker:Toker )
		_init
		_path=toker._path
		_line=toker._line
		_source=toker._source
		_length=_source.Length
		_toke=toker._toke
		_tokeType=toker._tokeType
		_tokePos=toker._tokePos
	End
	
	Method Path$()
		Return _path
	End
	
	Method Line:Int()
		Return _line
	End
	
	Method NextToke$()
	
		_toke=""

		If _tokePos=_length
			_tokeType=TOKE_EOF
			Return _toke
		Endif
		
		Local chr:=TCHR()
		Local str:=TSTR()
		Local start:=_tokePos
		_tokePos+=1
		
		If str="~n"
			_tokeType=TOKE_SYMBOL
			_line+=1
		Else If IsSpace( chr )
			_tokeType=TOKE_SPACE
			While _tokePos<_length And IsSpace( TCHR() ) And TSTR()<>"~n"
				_tokePos+=1
			Wend
		Else If str="_" Or IsAlpha( chr )
			_tokeType=TOKE_IDENT
			While _tokePos<_length
				Local chr=_source[_tokePos]
				If chr<>95 And Not IsAlpha( chr ) And Not IsDigit( chr ) Exit
'				If chr<>Asc("_") And Not IsAlpha( chr ) And Not IsDigit( chr ) Exit
				_tokePos+=1
			Wend
			_toke=_source[start.._tokePos]
			If _keywords.Contains( _toke.ToLower() ) _tokeType=TOKE_KEYWORD
		Else If IsDigit( chr ) Or str="." And IsDigit( TCHR() )
			_tokeType=TOKE_INTLIT
			If str="." _tokeType=TOKE_FLOATLIT
			While IsDigit( TCHR() )
				_tokePos+=1
			Wend
			If _tokeType=TOKE_INTLIT And TSTR()="." And IsDigit( TCHR(1) )
				_tokeType=TOKE_FLOATLIT
				_tokePos+=2
				While IsDigit( TCHR() )
					_tokePos+=1
				Wend
			Endif
			If TSTR().ToLower()="e"
				_tokeType=TOKE_FLOATLIT
				_tokePos+=1
				If TSTR()="+" Or TSTR()="-" _tokePos+=1
				While IsDigit( TCHR() )
					_tokePos+=1
				Wend
			Endif
		Else If str="%" And IsBinDigit( TCHR() )
			_tokeType=TOKE_INTLIT
			_tokePos+=1
			While IsBinDigit( TCHR() )
				_tokePos+=1
			Wend
		Else If str="$" And IsHexDigit( TCHR() )
			_tokeType=TOKE_INTLIT
			_tokePos+=1
			While IsHexDigit( TCHR() )
				_tokePos+=1
			Wend
		Else If str="~q"
			_tokeType=TOKE_STRINGLIT
			While _tokePos<_length And TSTR()<>"~q"
				_tokePos+=1
			Wend
			If _tokePos<_length _tokePos+=1 Else _tokeType=TOKE_STRINGLITEX
		Else If str="'"
			_tokeType=TOKE_LINECOMMENT
			While _tokePos<_length And TSTR()<>"~n"
				_tokePos+=1
			Wend
			If _tokePos<_length
				_tokePos+=1
				_line+=1
			Endif
		Else If str="["
			_tokeType=TOKE_SYMBOL
			Local i
			While _tokePos+i<_length
				If TSTR(i)="]"
					_tokePos+=i+1
					Exit
				Endif
				If TSTR(i)="~n" Or Not IsSpace( TCHR(i) ) Exit
				i+=1
			Wend
		Else
			_tokeType=TOKE_SYMBOL
			If _symbols.Contains( _source[_tokePos-1.._tokePos+1] ) _tokePos+=1
		Endif
		
		If Not _toke _toke=_source[start.._tokePos]

		Return _toke
	End
	
	Method Toke$()
		Return _toke
	End
	
	Method TokeType()
		Return _tokeType
	End
	
	Method SkipSpace()
		While _tokeType=TOKE_SPACE
			NextToke
		Wend
	End
	
Private

	Method TCHR( i=0 )
		i+=_tokePos
		If i<_length Return _source[i]
	End
	
	Method TSTR$( i=0 )
		i+=_tokePos
		If i<_length Return _source[i..i+1]
	End
	
End
