
' Module trans.parser
'
' Placed into the public domain 24/02/2011.
' No warranty implied; use at your own risk.

Import trans

Global FILE_EXT$="monkey"

Class ScopeExpr Extends Expr
	Field scope:ScopeDecl

	Method New( scope:ScopeDecl )
		Self.scope=scope
	End
	
	Method Copy:Expr()
		Return Self
	End

	Method ToString$()
		Print "ScopeExpr("+scope.ToString()+")"
	End
		
	Method Semant:Expr()
		InternalErr
	End
	
	Method SemantScope:ScopeDecl()
		Return scope
	End

End

Class ForEachinStmt Extends Stmt
	Field varid$
	Field varty:Type
	Field varlocal
	Field expr:Expr
	Field block:BlockDecl
	
	Method New( varid$,varty:Type,varlocal,expr:Expr,block:BlockDecl )
		Self.varid=varid
		Self.varty=varty
		Self.varlocal=varlocal
		Self.expr=expr
		Self.block=block
	End
	
	Method OnCopy:Stmt( scope:ScopeDecl )
		Return New ForEachinStmt( varid,varty,varlocal,expr.Copy(),block.CopyBlock( scope ) )
	End
	
	Method OnSemant()
		expr=expr.Semant()
		
		If ArrayType( expr.exprType ) Or StringType( expr.exprType )
		
			Local exprTmp:LocalDecl=New LocalDecl( "",0,Null,expr )
			Local indexTmp:LocalDecl=New LocalDecl( "",0,Null,New ConstExpr( Type.intType,"0" ) )

			Local lenExpr:Expr=New IdentExpr( "Length",New VarExpr( exprTmp ) )

			Local cmpExpr:Expr=New BinaryCompareExpr( "<",New VarExpr( indexTmp ),lenExpr )
			
			Local indexExpr:Expr=New IndexExpr( New VarExpr( exprTmp ),New VarExpr( indexTmp ) )
			Local addExpr:Expr=New BinaryMathExpr( "+",New VarExpr( indexTmp ),New ConstExpr( Type.intType,"1" ) )
			
			block.stmts.AddFirst New AssignStmt( "=",New VarExpr( indexTmp ),addExpr )
			
			If varlocal
				Local varTmp:LocalDecl=New LocalDecl( varid,0,varty,indexExpr )
				block.stmts.AddFirst New DeclStmt( varTmp )
			Else
				block.stmts.AddFirst New AssignStmt( "=",New IdentExpr( varid ),indexExpr )
			Endif
			
			Local whileStmt:WhileStmt=New WhileStmt( cmpExpr,block )
			
			block=New BlockDecl( block.scope )
			block.AddStmt New DeclStmt( exprTmp )
			block.AddStmt New DeclStmt( indexTmp )
			block.AddStmt whileStmt
		
		Else If ObjectType( expr.exprType )
		
			Local enumerInit:Expr=New FuncCallExpr( New IdentExpr( "ObjectEnumerator",expr ),[] )
			Local enumerTmp:LocalDecl=New LocalDecl( "",0,Null,enumerInit )

			Local hasNextExpr:Expr=New FuncCallExpr( New IdentExpr( "HasNext",New VarExpr( enumerTmp ) ),[] )
			Local nextObjExpr:Expr=New FuncCallExpr( New IdentExpr( "NextObject",New VarExpr( enumerTmp ) ),[] )

			If varlocal
				Local varTmp:LocalDecl=New LocalDecl( varid,0,varty,nextObjExpr )
				block.stmts.AddFirst New DeclStmt( varTmp )
			Else
				block.stmts.AddFirst New AssignStmt( "=",New IdentExpr( varid ),nextObjExpr )
			Endif
			
			Local whileStmt:WhileStmt=New WhileStmt( hasNextExpr,block )
			
			block=New BlockDecl( block.scope )
			block.AddStmt New DeclStmt( enumerTmp )
			block.AddStmt whileStmt

		Else
		
			Err "Expression cannot be used with For Each."

		Endif
		
		block.Semant
	End
	
	Method Trans$()
		Return _trans.TransBlock( block )
	End

End

Class IdentTypeExpr Extends Expr
	Field cdecl:ClassDecl
	
	Method New( type:Type )
		Self.exprType=type
	End
	
	Method Copy:Expr()
		Return New IdentTypeExpr( exprType )
	End

	Method _Semant()
		If cdecl Return
		exprType=exprType.Semant()
		cdecl=exprType.GetClass()
		If Not cdecl InternalErr
	End
		
	Method Semant:Expr()
		_Semant
		Err "Expression can't be used in this way"
	End
	
	Method SemantFunc:Expr( args:Expr[] )
		_Semant
		If args.Length=1 And args[0] Return args[0].Cast( cdecl.objectType,CAST_EXPLICIT )
		Err "Illegal number of arguments for type conversion"
	End
	
	Method SemantScope:ScopeDecl()
		_Semant
		Return cdecl
	End	

End

Class IdentExpr Extends Expr
	Field ident$
	Field expr:Expr
	Field scope:ScopeDecl
	Field static?

	Method New( ident$,expr:Expr=Null )
		Self.ident=ident
		Self.expr=expr
	End
	
	Method Copy:Expr()
		Return New IdentExpr( ident,CopyExpr(expr) )
	End
	
	Method ToString$()
		Local t$="IdentExpr(~q"+ident+"~q"
		If expr t+=","+expr.ToString()
		Return t+")"
	End
	
	Method _Semant()
	
		If scope Return

		If expr
			scope=expr.SemantScope()
			If scope
				static=True
			Else
				expr=expr.Semant()
				scope=expr.exprType.GetClass()
				If Not scope Err "Expression has no scope"
			Endif
		Else
			scope=_env
			static=_env.FuncScope()=Null Or _env.FuncScope().IsStatic()
		Endif
		
	End
	
	Method IdentErr()
		Local close$
		For Local decl:=Eachin scope.Decls
			If ident.ToLower()=decl.ident.ToLower()
				close=decl.ident
			Endif
		Next
		If close And ident<>close Err "Identifier '"+ident+"' not found - perhaps you meant '"+close+"'?"
		Err "Identifier '"+ident+"' not found."
	End
	
	Method Semant:Expr()
	
		Return SemantSet( "",Null )

	End
	
	Method SemantSet:Expr( op$,rhs:Expr )

		_Semant
		
		Local vdecl:ValDecl=scope.FindValDecl( ident )
		If vdecl
			If ConstDecl( vdecl )
				If rhs Err "Constant '"+ident+"' cannot be modified."
				Local cexpr:=New ConstExpr( vdecl.type,ConstDecl( vdecl ).value )
'				If Not static And expr Return New StmtExpr( New ExprStmt( expr ),cexpr ).Semant()
				If Not static And (InvokeExpr( expr ) Or InvokeMemberExpr( expr )) Return New StmtExpr( New ExprStmt( expr ),cexpr ).Semant()
				Return cexpr.Semant()
			Else If FieldDecl( vdecl )
				If static Err "Field '"+ident+"' cannot be accessed from here."
				If expr Return New MemberVarExpr( expr,VarDecl( vdecl ) ).Semant()
			Endif
			Return New VarExpr( VarDecl( vdecl ) ).Semant()
		Endif
		
		If op And op<>"="

			Local fdecl:FuncDecl=scope.FindFuncDecl( ident,[] )
			If Not fdecl IdentErr

			If _env.ModuleScope().IsStrict() And Not fdecl.IsProperty() Err "Identifier '"+ident+"' cannot be used in this way."
			
			Local lhs:Expr
			
			If fdecl.IsStatic() Or (scope=_env And Not _env.FuncScope().IsStatic())
				lhs=New InvokeExpr( fdecl,[] )
			Else If expr
				Local tmp:=New LocalDecl( "",0,Null,expr )
				lhs=New InvokeMemberExpr( New VarExpr( tmp ),fdecl,[] )
				lhs=New StmtExpr( New DeclStmt( tmp ),lhs )
			Else
				Return Null
			Endif
			
			Local bop$=op[..1]
			Select bop
			Case "*","/","shl","shr","+","-","&","|","~~"
				rhs=New BinaryMathExpr( bop,lhs,rhs )
			Default
				InternalErr
			End Select
			rhs=rhs.Semant()
		Endif
		
		Local args:Expr[]
		If rhs args=[rhs]
		
		Local fdecl:FuncDecl=scope.FindFuncDecl( ident,args )
		If fdecl
		
			If _env.ModuleScope().IsStrict() And Not fdecl.IsProperty() Err "Identifier '"+ident+"' cannot be used in this way."
			
			If Not fdecl.IsStatic()
				If static Err "Method '"+ident+"' cannot be accessed from here."
				If expr Return New InvokeMemberExpr( expr,fdecl,args ).Semant()
			Endif
			Return New InvokeExpr( fdecl,args ).Semant()
		Endif
		
		IdentErr
	End

	Method SemantFunc:Expr( args:Expr[] )
	
		_Semant
	
		Local fdecl:FuncDecl=scope.FindFuncDecl( ident,args )
		If fdecl
			If Not fdecl.IsStatic()
				If static Err "Method '"+ident+"' cannot be accessed from here."
				If expr Return New InvokeMemberExpr( expr,fdecl,args ).Semant()
			Endif
			Return New InvokeExpr( fdecl,args ).Semant()
		Endif
		
		Local type:=scope.FindType( ident,[] )
		If type
			If args.Length=1 And args[0] Return args[0].Cast( type,CAST_EXPLICIT )
			Err "Illegal number of arguments for type conversion"
		Endif
		
		IdentErr
	End
	
	Method SemantScope:ScopeDecl()

		_Semant
		
		Return scope.FindScopeDecl( ident )

	End
End

Class FuncCallExpr Extends Expr
	Field expr:Expr
	Field args:Expr[]
	
	Method New( expr:Expr,args:Expr[] )
		Self.expr=expr
		Self.args=args
	End
	
	Method Copy:Expr()
		Return New FuncCallExpr( CopyExpr(expr),CopyArgs(args) )
	End
	
	Method ToString$()
		Local t$="FuncCallExpr("+expr.ToString()
		For Local arg:=Eachin args
			t+=","+arg.ToString()
		Next
		Return t+")"
	End
	
	Method Semant:Expr()

		args=SemantArgs( args )
		Return expr.SemantFunc( args )
	End

End

'***** Parser *****
Class Parser

	Field _toker:Toker
	Field _toke$
	Field _tokeType
	
	Field _block:BlockDecl
	Field _blockStack:=New List<BlockDecl>
	Field _errStack:=New StringList
	
	Field _selTmpId
		
	Field _app:AppDecl
	Field _module:ModuleDecl
	Field _defattrs
	
	Method SetErr()
		If _toker.Path _errInfo=_toker.Path+"<"+_toker.Line+">"
	End
	
	Method PushErr()
		_errStack.AddLast _errInfo
	End
	
	Method PopErr()
		_errInfo=_errStack.RemoveLast()
	End
	
	Method PushBlock( block:BlockDecl )
		_blockStack.AddLast _block
		_errStack.AddLast _errInfo
		_block=block
	End
	
	Method PopBlock()
		_block=_blockStack.RemoveLast()
		_errInfo=_errStack.RemoveLast()
	End
	
	Method RealPath$( path$ )	
		Local popDir$=CurrentDir()
		ChangeDir ExtractDir( _toker.Path() )
		path=os.RealPath( path )
		ChangeDir popDir
		Return path
	End
	
	Method NextToke$()
		Local toke$=_toke
		
		Repeat
			_toke=_toker.NextToke()
			_tokeType=_toker.TokeType()
		Until _tokeType<>TOKE_SPACE
		
		Select _tokeType
		Case TOKE_KEYWORD
			_toke=_toke.ToLower()
		Case TOKE_SYMBOL
			If _toke[0]=91 And _toke[_toke.Length-1]=93
'			If _toke[0]=Asc("[") And _toke[_toke.Length-1]=Asc("]")
				_toke="[]"
			Endif
		End

		If toke="," SkipEols

		Return _toke
	End
	
	Method CParse( toke$ )
		If _toke<>toke
			Return False
		Endif
		NextToke
		Return True
	End

	Method Parse( toke$ )
		If Not CParse( toke )
			Err "Syntax error - expecting '"+toke+"'."
		Endif
	End
	
	Method AtEos()
		Return _toke="" Or _toke=";" Or _toke="~n" Or _toke="else"
	End
	
	Method SkipEols()
		While CParse( "~n" )
		Wend
		SetErr
	End
	
	Method ParseStringLit$()
		If _tokeType<>TOKE_STRINGLIT Err "Expecting string literal."
		Local str$=Dequote( _toke,"monkey" )
		NextToke
		Return str
	End
	
	Method ParseIdent$()
		Select _toke
		Case "@" 
			NextToke
		Case "object","throwable"
			'			
		Default	
			If _tokeType<>TOKE_IDENT Err "Syntax error - expecting identifier."
		End
		Local id$=_toke
		NextToke
		Return id
	End
	
	Method CParsePrimitiveType:Type()
		If CParse( "void" ) Return Type.voidType
		If CParse( "bool" ) Return Type.boolType
		If CParse( "int" ) Return Type.intType
		If CParse( "float" ) Return Type.floatType
		If CParse( "string" ) Return Type.stringType
		If CParse( "object" ) Return Type.objectType
		If CParse( "throwable" ) Return Type.throwableType
	End	
	
	Method ParseType:Type()
		Local ty:=CParsePrimitiveType()
		If ty Return ty
		Return ParseIdentType()
	End
	
	Method ParseIdentType:IdentType()
		Local id$=ParseIdent()
		If CParse( "." ) id+="."+ParseIdent()
		Local args:=New Stack<Type>
		If CParse( "<" )
			Repeat
				Local arg:=ParseType()
				While CParse( "[]" )
					arg=arg.ArrayOf()
				Wend
				args.Push arg
			Until Not CParse(",")
			Parse ">"
		Endif
		Return New IdentType( id,args.ToArray() )
	End
	
	Method CParseIdentType:IdentType( inner?=False )
		If _tokeType<>TOKE_IDENT Return
		Local id:=ParseIdent()
		If CParse( "." )
			If _tokeType<>TOKE_IDENT Return
			id+="."+ParseIdent()
		End
		If Not CParse( "<" ) 
			If inner Return New IdentType( id,[] )
			Return
		Endif
		Local args:=New Stack<Type>
		Repeat
			Local arg:Type=CParsePrimitiveType()
			If Not arg 
				arg=CParseIdentType( True )
				If Not arg Return
			Endif
			While CParse( "[]" )
				arg=arg.ArrayOf()
			Wend
			args.Push arg
		Until Not CParse(",")
		If Not CParse( ">" ) Return
		Return New IdentType( id,args.ToArray() )
	End
	
	Method ParseDeclType:Type()
		Local ty:Type
		Select _toke
		Case "?"
			NextToke
			ty=Type.boolType
		Case "%"
			NextToke
			ty=Type.intType
		Case "#"
			NextToke
			ty=Type.floatType
		Case "$"
			NextToke
			ty=Type.stringType
		Case ":"
			NextToke
			ty=ParseType()
		Default
			If _module.IsStrict() Err "Illegal type expression."
			ty=Type.intType
		End Select
		While CParse( "[]" )
			ty=ty.ArrayOf()
		Wend
		Return ty
	End
	
	Method ParseArrayExpr:ArrayExpr()
		Parse "["
		Local args:=New Stack<Expr>
		Repeat
			args.Push ParseExpr()
		Until Not CParse(",")
		Parse "]"
		Return New ArrayExpr( args.ToArray() )
	End
	
	Method ParseArgs:Expr[]( stmt )

		Local args:Expr[]
		
		If stmt
			If AtEos() Return args
		Else
			If _toke<>"(" Return args
		Endif
		
		Local nargs,eat
		
		If _toke="("
			If stmt
				Local toker:=New Toker( _toker ),bra=1
				Repeat
					toker.NextToke
					toker.SkipSpace
					Select toker.Toke().ToLower()
					Case "","else"
						Err "Parenthesis mismatch error."
					Case "(","["
						bra+=1
					Case "]",")"
						bra-=1
						If bra Continue
						toker.NextToke
						toker.SkipSpace
						Select toker.Toke().ToLower()
						Case ".","(","[","",";","~n","else"
							eat=True
						End
						Exit
					Case ","
						If bra<>1 Continue
						eat=True
						Exit
					End
				Forever
			Else
				eat=True
			Endif
			If eat And NextToke()=")" 
				NextToke
				Return args
			Endif
		Endif
		
		Repeat
			Local arg:Expr
			If _toke And _toke<>"," arg=ParseExpr()
			If args.Length=nargs args=args.Resize( nargs+10 )
			args[nargs]=arg
			nargs+=1
		Until Not CParse(",")
		args=args[..nargs]
		
		If eat Parse ")"
		
		Return args
	End
	
	Method ParsePrimaryExpr:Expr( stmt )
	
		Local expr:Expr

		Select _toke
		Case "("
			NextToke
			expr=ParseExpr()
			Parse ")"
		Case "["
			expr=ParseArrayExpr()
		Case "[]"
			NextToke
			expr=New ConstExpr( Type.emptyArrayType,"" )
		Case "."
			expr=New ScopeExpr( _module )
		Case "new"
			NextToke
			Local ty:Type=ParseType()
			If CParse( "[" )
				Local len:=ParseExpr()
				Parse "]"
				While CParse( "[]" )
					ty=ty.ArrayOf()
				Wend
				expr=New NewArrayExpr( ty,len )
			Else
				expr=New NewObjectExpr( ty,ParseArgs( stmt ) )
			Endif
		Case "null"
			NextToke
			expr=New ConstExpr( Type.nullObjectType,"" )
		Case "true"
			NextToke
			expr=New ConstExpr( Type.boolType,"1" )
		Case "false"
			NextToke
			expr=New ConstExpr( Type.boolType,"" )
		Case "bool","int","float","string","object","throwable"
			Local id$=_toke
			Local ty:Type=ParseType()
			If CParse( "(" )
				expr=ParseExpr()
				Parse ")"
				expr=New CastExpr( ty,expr,CAST_EXPLICIT )
			Else
				expr=New IdentExpr( id )
			Endif
		Case "self"
			NextToke
			expr=New SelfExpr
		Case "super"
			NextToke
			Parse "."
			If _toke="new"
				NextToke
				Local func:=FuncDecl( _block )
				If Not func Or Not stmt Or Not func.IsCtor() Or Not func.stmts.IsEmpty()
					Err "Call to Super.new must be first statement in a constructor."
				Endif
				expr=New InvokeSuperExpr( "new",ParseArgs( stmt ) )
				func.attrs|=FUNC_CALLSCTOR
			Else
				Local id$=ParseIdent()
				expr=New InvokeSuperExpr( id,ParseArgs( stmt ) )
			Endif
		Default
			Select _tokeType
			Case TOKE_IDENT

				Local toker:=New Toker( _toker )
				
				Local ty:=CParseIdentType()
				If ty
					expr=New IdentTypeExpr( ty )
				Else
					_toker=toker
					_toke=_toker.Toke()
					_tokeType=_toker.TokeType()
					expr=New IdentExpr( ParseIdent() )
				Endif

			Case TOKE_INTLIT
				expr=New ConstExpr( Type.intType,_toke )
				NextToke
			Case TOKE_FLOATLIT
				expr=New ConstExpr( Type.floatType,_toke )
				NextToke
			Case TOKE_STRINGLIT
				expr=New ConstExpr( Type.stringType,Dequote( _toke,"monkey" ) )
				NextToke
			Default
				Err "Syntax error - unexpected token '"+_toke+"'"
			End Select
		End Select

		Repeat
			
			Select _toke
			Case "."

				NextToke
				If False	'_toke="new"	'experimental Self.New - needs more testing/thinking.
					NextToke
					If Not SelfExpr( expr )
						Err "Member 'New' can only by accessed using Self."
					Endif
					Local func:=FuncDecl( _block )
					If Not func Or Not stmt Or Not func.IsCtor() Or Not func.stmts.IsEmpty()
						Err "Call to Self.New must be first statement in a constructor."
					Endif
					expr=New FuncCallExpr( New IdentExpr( "new",expr ),ParseArgs( True ) )
					func.attrs|=FUNC_CALLSCTOR
				Else
					Local id$=ParseIdent()
					expr=New IdentExpr( id,expr )
				Endif
				
			Case "("
			
				expr=New FuncCallExpr( expr,ParseArgs( stmt ) )

			Case "["
			
				NextToke
				If CParse( ".." )
					If _toke="]"
						expr=New SliceExpr( expr,Null,Null )
					Else
						expr=New SliceExpr( expr,Null,ParseExpr() )
					Endif
				Else
					Local from:Expr=ParseExpr()
					If CParse( ".." )
						If _toke="]"
							expr=New SliceExpr( expr,from,Null )
						Else
							expr=New SliceExpr( expr,from,ParseExpr() )
						Endif
					Else
						expr=New IndexExpr( expr,from )
					Endif
				Endif
				Parse "]"
			Default
				Return expr
			End Select
		Forever
		
	End
	
	Method ParseUnaryExpr:Expr()
		SkipEols
		Local op$=_toke
		Select op
		Case "+","-","~~","not"
			NextToke
			Local expr:Expr=ParseUnaryExpr()
			Return New UnaryExpr( op,expr )
		End Select
		Return ParsePrimaryExpr( False )
	End
	
	Method ParseMulDivExpr:Expr()
		Local expr:Expr=ParseUnaryExpr()
		Repeat
			Local op$=_toke
			Select op
			Case "*","/","mod","shl","shr"
				NextToke
				Local rhs:Expr=ParseUnaryExpr()
				expr=New BinaryMathExpr( op,expr,rhs )
			Default
				Return expr
			End Select
		Forever
	End
	
	Method ParseAddSubExpr:Expr()
		Local expr:Expr=ParseMulDivExpr()
		Repeat
			Local op$=_toke
			Select op
			Case "+","-"
				NextToke
				Local rhs:Expr=ParseMulDivExpr()
				expr=New BinaryMathExpr( op,expr,rhs )
			Default
				Return expr
			End Select
		Forever
	End
	
	Method ParseBitandExpr:Expr()
		Local expr:Expr=ParseAddSubExpr()
		Repeat
			Local op$=_toke
			Select op
			Case "&","~~"
				NextToke
				Local rhs:Expr=ParseAddSubExpr()
				expr=New BinaryMathExpr( op,expr,rhs )
			Default
				Return expr
			End Select
		Forever
	End
	
	Method ParseBitorExpr:Expr()
		Local expr:Expr=ParseBitandExpr()
		Repeat
			Local op$=_toke
			Select op
			Case "|"
				NextToke
				Local rhs:Expr=ParseBitandExpr()
				expr=New BinaryMathExpr( op,expr,rhs )
			Default
				Return expr
			End Select
		Forever
	End
	
	Method ParseCompareExpr:Expr()
		Local expr:Expr=ParseBitorExpr()
		Repeat
			Local op$=_toke
			Select op
			Case "=","<",">","<=",">=","<>"
				NextToke
				If op=">" And (_toke="=")
					op+=_toke
					NextToke
				Else If op="<" And (_toke="=" Or _toke=">")
					op+=_toke
					NextToke
				Endif
				Local rhs:Expr=ParseBitorExpr()
				expr=New BinaryCompareExpr( op,expr,rhs )
			Default
				Return expr
			End Select
		Forever
	End
	
	Method ParseAndExpr:Expr()
		Local expr:Expr=ParseCompareExpr()
		Repeat
			Local op$=_toke
			If op="and"
				NextToke
				Local rhs:Expr=ParseCompareExpr()
				expr=New BinaryLogicExpr( op,expr,rhs )
			Else
				Return expr
			Endif
		Forever
	End
	
	Method ParseOrExpr:Expr()
		Local expr:Expr=ParseAndExpr()
		Repeat
			Local op$=_toke
			If op="or"
				NextToke
				Local rhs:Expr=ParseAndExpr()
				expr=New BinaryLogicExpr( op,expr,rhs )
			Else
				Return expr
			Endif
		Forever
	End
	
	Method ParseExpr:Expr()
		Return ParseOrExpr()
	End
	
	Method ParseIfStmt( term$ )

		CParse "if"

		Local expr:Expr=ParseExpr()
		
		CParse "then"
		
		Local thenBlock:BlockDecl=New BlockDecl( _block )
		Local elseBlock:BlockDecl=New BlockDecl( _block )
		
		Local eatTerm
		If Not term
			If _toke="~n" term="end" Else term="~n"
			eatTerm=True
		Endif

		PushBlock thenBlock
		While _toke<>term
			Select _toke
			Case "endif"
				If term="end" Exit
				Err "Syntax error - expecting 'End'."
			Case "else","elseif"
				Local elif=_toke="elseif"
				NextToke
				If _block=elseBlock
					Err "If statement can only have one 'else' block."
				Endif
				PopBlock
				PushBlock elseBlock
				If elif Or _toke="if"
					ParseIfStmt term
				Endif
			Default
				ParseStmt
			End
		Wend
		PopBlock

		If eatTerm
			NextToke
			If term="end" CParse "if"
		Endif
		
		Local stmt:IfStmt=New IfStmt( expr,thenBlock,elseBlock )
		
		_block.AddStmt stmt
	End
	
	Method ParseWhileStmt()
	
		Parse "while"
		
		Local expr:Expr=ParseExpr()
		Local block:BlockDecl=New BlockDecl( _block )
		
		PushBlock block
		While Not CParse( "wend" )
			If CParse( "end" )
				CParse "while"
				Exit
			Endif
			ParseStmt
		Wend
		PopBlock
		
		Local stmt:WhileStmt=New WhileStmt( expr,block )
		
		_block.AddStmt stmt
	End
	
	Method ParseRepeatStmt()

		Parse "repeat"
		
		Local block:BlockDecl=New BlockDecl( _block )
		
		PushBlock block
		While _toke<>"until" And _toke<>"forever"
			ParseStmt
		Wend
		PopBlock
		
		Local expr:Expr
		If CParse( "until" )
			PushErr
			expr=ParseExpr()
			PopErr
		Else
			Parse "forever"
			expr=New ConstExpr( Type.boolType,"" )
		Endif
		
		Local stmt:RepeatStmt=New RepeatStmt( block,expr )
		
		_block.AddStmt stmt
	End
	
	Method ParseForStmt()
	
		Parse "for"
		
		Local varid$,varty:Type,varlocal
		
		If CParse( "local" )
			varlocal=True
			varid=ParseIdent()
			If Not CParse( ":=" )
				varty=ParseDeclType()
				Parse( "=" )
			Endif
		Else
			varlocal=False
			varid=ParseIdent()
			Parse "="
		Endif
		
		If CParse( "eachin" )
			Local expr:Expr=ParseExpr()
			Local block:BlockDecl=New BlockDecl( _block )
			
			PushBlock block
			While Not CParse( "next" )
				If CParse( "end" )
					CParse "for"
					Exit
				Endif
				ParseStmt
			Wend
			If _tokeType=TOKE_IDENT And ParseIdent()<>varid Err "Next variable name does not match For variable name"
			PopBlock
			
			Local stmt:ForEachinStmt=New ForEachinStmt( varid,varty,varlocal,expr,block )
			
			_block.AddStmt stmt

			Return
		Endif
		
		Local from:Expr=ParseExpr()
		
		Local op$
		If CParse( "to" )
			op="<="
		Else If CParse( "until" )
			op="<"
		Else
			Err "Expecting 'To' or 'Until'."
		Endif
		
		Local term:Expr=ParseExpr()
		Local stp:Expr
		
		If CParse( "step" )
			stp=ParseExpr()
		Else
			stp=New ConstExpr( Type.intType,"1" )
		Endif
		
		Local init:Stmt,expr:Expr,incr:Stmt
		
		If varlocal
			Local indexVar:LocalDecl=New LocalDecl( varid,0,varty,from )
			init=New DeclStmt( indexVar )
		Else
			init=New AssignStmt( "=",New IdentExpr( varid ),from )
		Endif

		expr=New BinaryCompareExpr( op,New IdentExpr( varid ),term )
		incr=New AssignStmt( "=",New IdentExpr( varid ),New BinaryMathExpr( "+",New IdentExpr( varid ),stp ) )
		
		Local block:BlockDecl=New BlockDecl( _block )
		
		PushBlock block
		While Not CParse( "next" )
			If CParse( "end" )
				CParse "for"
				Exit
			Endif
			ParseStmt
		Wend
		If _tokeType=TOKE_IDENT And ParseIdent()<>varid Err "Next variable name does not match For variable name"
		PopBlock

		Local stmt:ForStmt=New ForStmt( init,expr,incr,block )
		
		_block.AddStmt stmt
	End
	
	Method ParseReturnStmt()
		Parse "return"
		Local expr:Expr
		If Not AtEos() expr=ParseExpr()
		_block.AddStmt New ReturnStmt( expr )
	End
	
	Method ParseExitStmt()
		Parse "exit"
		_block.AddStmt New BreakStmt
	End
	
	Method ParseContinueStmt()
		Parse "continue"
		_block.AddStmt New ContinueStmt
	End
	
	Method ParseTryStmt()
		Parse "try"
		
		Local block:=New BlockDecl( _block )
		Local catches:=New Stack<CatchStmt>
		
		PushBlock block
		While _toke<>"end"
			If CParse( "catch" )
				Local id:=ParseIdent()
				Parse ":"
				Local ty:=ParseType()
				Local init:=New LocalDecl( id,0,ty,Null )
				Local block:=New BlockDecl( _block )
				catches.Push New CatchStmt( init,block )
				PopBlock
				PushBlock block
			Else
				ParseStmt
			Endif
		Wend
		If Not catches.Length Err "Try block must have at least one catch block"
		PopBlock
		NextToke
		CParse "try"

		_block.AddStmt New TryStmt( block,catches.ToArray() )
	End
	
	Method ParseThrowStmt()
		Parse "throw"
		
		_block.AddStmt New ThrowStmt( ParseExpr() )
	End
	
	Method ParseSelectStmt()
		Parse "select"
		
		Local expr:=ParseExpr()
		
		Local block:BlockDecl=_block

		_selTmpId+=1
		Local tmpId:=String( _selTmpId )	'1,2,3...
		block.AddStmt New DeclStmt( tmpId,Null,expr )
		Local tmpExpr:=New IdentExpr( tmpId )
		
'		Local tmpVar:LocalDecl=New LocalDecl( "",0,Null,expr )
'		Local tmpExpr:=New VarExpr( tmpVar )
'		block.AddStmt New DeclStmt( tmpVar )
		
		While _toke<>"end" And _toke<>"default"
			SetErr
			Select _toke
			Case "~n"
				NextToke
			Case "case"
				NextToke
				Local comp:Expr
				Repeat
				
					Local expr:Expr=New IdentExpr( tmpId )
					expr=New BinaryCompareExpr( "=",expr,ParseExpr() )

'					local expr:=New BinaryCompareExpr( "=",tmpExpr,ParseExpr() )
					
					If comp
						comp=New BinaryLogicExpr( "or",comp,expr )
					Else
						comp=expr
					Endif
				Until Not CParse(",")
				
				Local thenBlock:BlockDecl=New BlockDecl( _block )
				Local elseBlock:BlockDecl=New BlockDecl( _block )
				
				Local ifstmt:IfStmt=New IfStmt( comp,thenBlock,elseBlock )
				block.AddStmt ifstmt
				block=ifstmt.thenBlock
				
				PushBlock block
				While _toke<>"case" And _toke<>"default" And _toke<>"end"
					ParseStmt
				Wend
				PopBlock
				
				block=elseBlock
			Default
				Err "Syntax error - expecting 'Case', 'Default' or 'End'."
			End Select
		Wend
		
		If _toke="default"
			NextToke
			PushBlock block
			While _toke<>"end"
				SetErr
				Select _toke
				Case "case"
					Err "Case can not appear after default."
				Case "default"
					Err "Select statement can have only one default block."
				End Select
				ParseStmt
			Wend
			PopBlock
		Endif
		
		SetErr
		Parse "end"
		CParse "select"
	End
	
	Method ParseStmt()
		SetErr
		Select _toke
		Case ";","~n"
			NextToke
		Case "const","local"
			ParseDeclStmts
		Case "return"
			ParseReturnStmt()
		Case "exit"
			ParseExitStmt()
		Case "continue"
			ParseContinueStmt()
		Case "if"
			ParseIfStmt( "" )
		Case "while"
			ParseWhileStmt()
		Case "repeat"
			ParseRepeatStmt()
		Case "for"
			ParseForStmt()
		Case "select"
			ParseSelectStmt()
		Case "try"
			ParseTryStmt()
		Case "throw"
			ParseThrowStmt()
		Default
			Local expr:Expr=ParsePrimaryExpr( True )
			
			Select _toke
			Case "=","*=","/=","+=","-=","&=","|=","~~=","mod","shl","shr"
				If IdentExpr( expr ) Or IndexExpr( expr )
					Local op$=_toke
					NextToke
					If Not op.EndsWith( "=" )
						Parse "="
						op+="="
					Endif
					_block.AddStmt New AssignStmt( op,expr,ParseExpr() )
				Else
					Err "Assignment operator '"+_toke+"' cannot be used this way."
				Endif
				Return
			End
			
			If IdentExpr( expr )
			
				expr=New FuncCallExpr( expr,ParseArgs( True ) )
				
			Else If FuncCallExpr( expr) Or InvokeSuperExpr( expr ) Or NewObjectExpr( expr )

			Else
				Err "Expression cannot be used as a statement."
			Endif
			
			_block.AddStmt New ExprStmt( expr )

		End Select
	End
	
	Method ParseDecl:Decl( toke$,attrs )
		SetErr
		Local id$=ParseIdent()
		Local ty:Type
		Local init:Expr
		If attrs & DECL_EXTERN
			ty=ParseDeclType()
		Else If CParse( ":=" )
			init=ParseExpr()
		Else
			ty=ParseDeclType()
			If CParse( "=" )
				init=ParseExpr()
			Else If CParse( "[" )
				Local len:=ParseExpr()
				Parse "]"
				While CParse( "[]" )
					ty=ty.ArrayOf()
				Wend
				init=New NewArrayExpr( ty,len )
				ty=ty.ArrayOf()
			Else If toke<>"const"
				init=New ConstExpr( ty,"" )
			Else
				Err "Constants must be initialized."
			Endif
		Endif
		
		Local decl:ValDecl
		
		Select toke
		Case "global" decl=New GlobalDecl( id,attrs,ty,init )
		Case "field"  decl=New FieldDecl( id,attrs,ty,init )
		Case "const"  decl=New ConstDecl( id,attrs,ty,init )
		Case "local"  decl=New LocalDecl( id,attrs,ty,init )
		End Select
		
		If decl.IsExtern() Or CParse( "extern" )
			decl.munged=decl.ident
			If CParse( "=" ) decl.munged=ParseStringLit()
		Endif
	
		Return decl
	End
	
	Method ParseDecls:List<Decl>( toke$,attrs )
		If toke Parse toke

		Local decls:=New List<Decl>
		Repeat
			Local decl:Decl=ParseDecl( toke,attrs )
			decls.AddLast decl
			If Not CParse(",") Return decls
		Forever
	End
	
	Method ParseDeclStmts()
		Local toke$=_toke
		NextToke
		Repeat
			Local decl:Decl=ParseDecl( toke,0 )
			_block.AddStmt New DeclStmt( decl )
		Until Not CParse(",")
	End
	
	Method ParseFuncDecl:FuncDecl( attrs )

		SetErr
		
		If CParse( "method" )
			attrs|=FUNC_METHOD
		Else If Not CParse( "function" )
			InternalErr
		Endif
		
		attrs|=_defattrs
	
		Local id$
		Local ty:Type
		
		If attrs & FUNC_METHOD
			If _toke="new"
				If attrs & DECL_EXTERN Err "Extern classes cannot have constructors."
				id=_toke
				NextToke
				attrs|=FUNC_CTOR
				attrs&=~FUNC_METHOD
			Else
				id=ParseIdent()
				ty=ParseDeclType()
			Endif
		Else
			id=ParseIdent()
			ty=ParseDeclType()
		Endif

		Local args:=New Stack<ArgDecl>
		
		Parse "("
		SkipEols
		If _toke<>")"
			Repeat
				Local id$=ParseIdent()
				Local ty:Type=ParseDeclType()
				Local init:Expr
				If CParse( "=" ) init=ParseExpr()
				args.Push New ArgDecl( id,0,ty,init )
				If _toke=")" Exit
				Parse ","
			Forever
		Endif
		Parse ")"
		
		Repeat		
			If CParse( "final" )
				If Not (attrs & FUNC_METHOD) Err "Functions cannot be final."
				If attrs & DECL_FINAL Err "Duplicate method attribute."
				If attrs & DECL_ABSTRACT Err "Methods cannot be both final and abstract."
				attrs|=DECL_FINAL
			Else If CParse( "abstract" )
				If Not (attrs & FUNC_METHOD) Err "Functions cannot be abstract."
				If attrs & DECL_ABSTRACT Err "Duplicate method attribute."
				If attrs & DECL_FINAL Err "Methods cannot be both final and abstract."
				attrs|=DECL_ABSTRACT
			Else If CParse( "property" )
				If Not (attrs & FUNC_METHOD) Err "Functions cannot be properties."	'why not?
				If attrs & FUNC_PROPERTY Err "Duplicate method attribute."
				attrs|=FUNC_PROPERTY
			Else
				Exit
			Endif
		Forever
		
		Local funcDecl:FuncDecl=New FuncDecl( id,attrs,ty,args.ToArray() )
		
		If funcDecl.IsExtern() Or CParse( "extern" )
			funcDecl.munged=funcDecl.ident
			If CParse( "=" )
				funcDecl.munged=ParseStringLit()
				'Array $resize hack! move outta here...
				If funcDecl.munged="$resize" funcDecl.retType=Type.emptyArrayType
			Endif
		Endif
		
		If funcDecl.IsExtern() Or funcDecl.IsAbstract() Return funcDecl
		
		PushBlock funcDecl
		While _toke<>"end"
			ParseStmt
		Wend
		PopBlock

		NextToke

		If attrs & (FUNC_CTOR|FUNC_METHOD)
			CParse "method"
		Else
			CParse "function"
		Endif
		
		Return funcDecl
	End
	
	Method ParseClassDecl:ClassDecl( attrs )
	
		SetErr
		Local toke:=_toke
	
		If CParse( "interface" )
			If attrs & DECL_EXTERN Err "Interfaces cannot be extern."
			attrs|=CLASS_INTERFACE|DECL_ABSTRACT
		Else If Not CParse( "class" )
			InternalErr
		Endif
		
		Local id$=ParseIdent()
		Local args:=New StringStack
		Local superTy:IdentType=Type.objectType
		Local imps:=New Stack<IdentType>
		
		If CParse( "<" )
			If attrs & DECL_EXTERN Err "Extern classes cannot be generic."
			'If attrs & CLASS_INTERFACE Err "Interfaces cannot be generic."
			Repeat
				args.Push ParseIdent()
			Until Not CParse(",")
			Parse ">"
		Endif
		
		If CParse( "extends" )
			If CParse( "null" )
				If attrs & CLASS_INTERFACE Err "Interfaces cannot extend null"
				If Not (attrs & DECL_EXTERN) Err "Only extern objects can extend null."
				superTy=Null
			Else If attrs & CLASS_INTERFACE
				Repeat
					imps.Push ParseIdentType()
				Until Not CParse(",")
				superTy=Type.objectType
			Else
				superTy=ParseIdentType()
			Endif
		Endif

		If CParse( "implements" )
			If attrs & DECL_EXTERN Err "Implements cannot be used with external classes."
			If attrs & CLASS_INTERFACE Err "Implements cannot be used with interfaces."
			Repeat
				imps.Push ParseIdentType()
			Until Not CParse(",")
		Endif

		Repeat
			If CParse( "final" )
				If attrs & CLASS_INTERFACE Err "Interfaces cannot be final."
				If attrs & DECL_FINAL Err "Duplicate class attribute."
				If attrs & DECL_ABSTRACT Err "Classes cannot be both final and abstract."
				attrs|=DECL_FINAL
			Else If CParse( "abstract" )
				If attrs & CLASS_INTERFACE Err "Interfaces cannot be abstract."
				If attrs & DECL_ABSTRACT Err "Duplicate class attribute."
				If attrs & DECL_FINAL Err "Classes cannot be both final and abstract."
				attrs|=DECL_ABSTRACT
			Else
				Exit
			Endif
		Forever

		Local classDecl:ClassDecl=New ClassDecl( id,attrs,args.ToArray(),superTy,imps.ToArray() )
		
		If classDecl.IsExtern() Or CParse( "extern" )
			classDecl.munged=classDecl.ident
			If CParse( "=" ) classDecl.munged=ParseStringLit()
		Endif

		Local decl_attrs=(attrs & DECL_EXTERN)
		
		Local func_attrs:=0
		If attrs & CLASS_INTERFACE func_attrs|=DECL_ABSTRACT
		
		Repeat
			SkipEols
			Select _toke
			Case "end"
				NextToke
				Exit
			Case "private"
				NextToke
				decl_attrs|=DECL_PRIVATE
			Case "public"
				NextToke
				decl_attrs&=~DECL_PRIVATE
			Case "const","global","field"
				If (attrs & CLASS_INTERFACE) And _toke<>"const" Err "Interfaces can only contain constants and methods."
				classDecl.InsertDecls ParseDecls( _toke,decl_attrs )
			Case "method"
				classDecl.InsertDecl ParseFuncDecl( decl_attrs|func_attrs )
			Case "function"
				If (attrs & CLASS_INTERFACE) Err "Interfaces can only contain constants and methods."
				classDecl.InsertDecl ParseFuncDecl( decl_attrs|func_attrs )
			Default
				Err "Syntax error - expecting class member declaration."
			End Select
		Forever
		
		If toke CParse toke
		
		Return classDecl
	End
	
	Method ParseModPath$()
		Local path$=ParseIdent()
		While CParse( "." )
			path+="."+ParseIdent()
		Wend
		Return path
	End
	
	Method ExtractModIdent$( modpath$ )
		Local i=modpath.FindLast( "." )
		If i<>-1 Return modpath[i+1..]
		Return modpath
	End
	
	Method ImportFile( filepath$ )

		If ENV_SAFEMODE
			If _app.mainModule=_module
				Err "Import of external files not permitted in safe mode."
			Endif
		Endif

		filepath=RealPath( filepath )
		
		If FileType( filepath )<>FILETYPE_FILE
			Err "File '"+filepath+"' not found."
		Endif
		
		_app.fileImports.AddLast filepath
		
	End
	
	Method ImportModule( modpath$,attrs )
		'done by preprocessor now...	
	End
	
	Method ParseMain()
	
		SkipEols
		
		If _module And CParse( "strict" ) _module.attrs|=MODULE_STRICT
			
		Local attrs
		
		'Parse header - imports etc.
		While _toke
			SetErr
			Select _toke
			Case "~n"
				NextToke
			Case "public"
				NextToke
				attrs=0
			Case "private"
				NextToke
				attrs=DECL_PRIVATE
			Case "import"
				NextToke
				If _tokeType=TOKE_STRINGLIT
					ImportFile EvalConfigTags( ParseStringLit() )
				Else
					ImportModule ParseModPath(),attrs
				Endif
			Case "alias"
				NextToke
				Repeat
					Local ident$=ParseIdent()
					Parse "="
					Local decl:Object

					Select _toke
					Case "int"
						decl=Type.intType
					Case "float"
						decl=Type.floatType
					Case "string"
						decl=Type.stringType
					End
					
					If decl
						_module.InsertDecl New AliasDecl( ident,attrs,decl )
						NextToke
						Continue
					Endif

					Local scope:ScopeDecl=_module
					
					_env=_module	'naughty! Shouldn't be doing GetDecl in parser...
					
					Repeat
						Local id:=ParseIdent()
						decl=scope.FindDecl( id )
						If Not decl Err "Identifier '"+id+"' not found."
						If Not CParse( "." ) Exit
						scope=ScopeDecl( decl )
						If Not scope Or FuncDecl( scope ) Err "Invalid scope '"+id+"'."
					Forever
					
					_env=Null	'/naughty
					
					_module.InsertDecl New AliasDecl( ident,attrs,decl )
					
				Until Not CParse(",")
			Default
				Exit
			End Select
		Wend
		
		'Parse main app
		While _toke
		
			SetErr
			Select _toke
			Case "~n"
				NextToke
			Case "public"
				NextToke
				attrs=0
			Case "private"
				NextToke
				attrs=DECL_PRIVATE
			Case "extern"
				If ENV_SAFEMODE
					If _app.mainModule=_module
						Err "Extern not permitted in safe mode."
					Endif
				Endif
				NextToke
				attrs=DECL_EXTERN
				If CParse( "private" ) attrs|=DECL_PRIVATE
			Case "const","global"
				_module.InsertDecls ParseDecls( _toke,attrs )
			Case "class"
				_module.InsertDecl ParseClassDecl( attrs )
			Case "interface"
				_module.InsertDecl ParseClassDecl( attrs )
			Case "function"
				_module.InsertDecl ParseFuncDecl( attrs )
			Default
				Err "Syntax error - expecting declaration."
			End Select
			
		Wend
		
		_errInfo=""
		
	End
	
	Method New( toker:Toker,app:AppDecl,mdecl:ModuleDecl=Null,defattrs=0 )
		_toke="~n"
		_toker=toker
		_app=app
		_module=mdecl
		_defattrs=defattrs
		SetErr
		NextToke
	End

End

'***** PUBLIC API ******

'for reflector to tack on code to reflection module...
Function ParseSource( source$,app:AppDecl,mdecl:ModuleDecl,defattrs=0 )

	Local toker:=New Toker( "$SOURCE",source )
	
	Local parser:=New Parser( toker,app,mdecl,defattrs )
	
	parser.ParseMain
	
End

Function ParseModule:ModuleDecl( modpath$,filepath$,app:AppDecl )

	Local ident:=modpath
	If ident.Contains( "." ) ident=ExtractExt( ident )
	
	Local mdecl:=New ModuleDecl( ident,0,"",modpath,filepath,app )
	
	mdecl.ImportModule "monkey",0

	Local source:=PreProcess( filepath,mdecl )
	
	Local toker:=New Toker( filepath,source )

	Local parser:=New Parser( toker,app,mdecl )
	
	parser.ParseMain
	
	Return parser._module
End

Function ParseApp:AppDecl( filepath$ )

	_errInfo=filepath+"<1>"
	
	Local app:AppDecl=New AppDecl
	
	Local modpath:=StripAll( filepath )

	ParseModule modpath,filepath,app
	
	Return app

End

