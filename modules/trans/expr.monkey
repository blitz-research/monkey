
' Module trans.expr
'
' Placed into the public domain 24/02/2011.
' No warranty implied; use at your own risk.

Import trans

Class Expr
	Field exprType:Type
	
	Method ToString$()
		Return "<Expr>"
	End
	
	Method Copy:Expr()
		InternalErr
	End
	
	Method Semant:Expr()
		InternalErr
	End
	
	Method SemantSet:Expr( op$,rhs:Expr )
		Err ToString()+" cannot be assigned to."
	End
	
	Method SemantFunc:Expr( args:Expr[] )
		Err ToString()+" cannot be invoked."
	End
	
	Method SemantScope:ScopeDecl()
		Return Null
	End
	
	Method Eval$()
		Err ToString()+" cannot be statically evaluated."
	End
	
	Method EvalConst:Expr()
		Return New ConstExpr( exprType,Eval() ).Semant()
	End
	
	Method SideEffects?()
		Return True
	End
	
	Method Trans$()
		Err "TODO!"
	End
	
	Method TransStmt$()
		Return Trans()
	End
	
	Method TransVar$()
		InternalErr
	End
	
	'semant and cast
	Method Semant:Expr( ty:Type,castFlags=0 )
		Local expr:=Semant()
		If expr.exprType.EqualsType( ty ) Return expr
		Return New CastExpr( ty,expr,castFlags ).Semant()
	End

	'expr and ty already semanted!
	Method Cast:Expr( ty:Type,castFlags=0 )
		If exprType.EqualsType( ty ) Return Self
		Return New CastExpr( ty,Self,castFlags ).Semant()
	End
	
	Method SemantArgs:Expr[]( args:Expr[] )
		args=args[..]
		For Local i=0 Until args.Length
			If args[i] args[i]=args[i].Semant()
		Next
		Return args
	End
	
	Method CastArgs:Expr[]( args:Expr[],funcDecl:FuncDecl )
		If args.Length>funcDecl.argDecls.Length InternalErr

		args=args.Resize( funcDecl.argDecls.Length )
		
		For Local i=0 Until args.Length
			If args[i]
				args[i]=args[i].Cast( funcDecl.argDecls[i].type )
			Else If funcDecl.argDecls[i].init
				args[i]=funcDecl.argDecls[i].init	
			Else
				Err "Missing function argument '"+funcDecl.argDecls[i].ident+"'."
			Endif
		Next
		Return args
	End
	
	Method BalanceTypes:Type( lhs:Type,rhs:Type )
		If StringType( lhs ) Or StringType( rhs ) Return Type.stringType
		If FloatType( lhs ) Or FloatType( rhs ) Return Type.floatType
		If IntType( lhs ) Or IntType( rhs ) Return Type.intType
		If lhs.ExtendsType( rhs ) Return rhs
		If rhs.ExtendsType( lhs ) Return lhs
		Err "Can't balance types "+lhs.ToString()+" and "+rhs.ToString()+"."
	End
	
	Method CopyExpr:Expr( expr:Expr )
		If Not expr Return
		Return expr.Copy()
	End
	
	Method CopyArgs:Expr[]( exprs:Expr[] )
		exprs=exprs[..]
		For Local i=0 Until exprs.Length
			exprs[i]=CopyExpr( exprs[i] )
		Next
		Return exprs
	End

End

'	exec a stmt, return an expr
Class StmtExpr Extends Expr
	Field stmt:Stmt
	Field expr:Expr
	
	Method New( stmt:Stmt,expr:Expr )
		Self.stmt=stmt
		Self.expr=expr
	End
	
	Method Copy:Expr()
		Return New StmtExpr( stmt,CopyExpr(expr) )
	End
	
	Method ToString$()
		Return "StmtExpr(,"+expr.ToString()+")"
	End
		
	Method Semant:Expr()
		If exprType Return Self
		
		stmt.Semant()
		expr=expr.Semant()
		exprType=expr.exprType
		Return Self
	End
	
	Method Trans$()
		Return _trans.TransStmtExpr( Self )
	End

End

'	literal
Class ConstExpr Extends Expr
	Field ty:Type
	Field value$
	
	Method New( ty:Type,value$ )
		If IntType( ty )
			If value.StartsWith( "%" )
				value=StringToInt( value[1..],2 )
			Else If value.StartsWith( "$" )
				value=StringToInt( value[1..],16 )
			Else
				'strip leading 0's or we can end up with an octal const!
				While value.StartsWith( "0" )
					value=value[1..]
				Wend
			Endif
		Else If FloatType( ty )
			If Not (value.Contains("e") Or value.Contains("E") Or value.Contains("."))
				value+=".0"
			Endif
		Endif
		Self.ty=ty
		Self.value=value
	End
	
	Method Copy:Expr()
		Return New ConstExpr( ty,value )
	End
	
	Method ToString$()
		Return "ConstExpr(~q"+value+"~q)"
	End
	
	Method SideEffects?()
		Return False
	End
	
	Method Semant:Expr()
		If exprType Return Self
		
		exprType=ty.Semant()
		Return Self
	End
	
	Method Eval$()
		Return value
	End
	
	Method EvalConst:Expr()
		Return Self
	End
	
	Method Trans$()
		Return _trans.TransConstExpr( Self )
	End

End

Class VarExpr Extends Expr
	Field decl:VarDecl
	
	Method New( decl:VarDecl )
		Self.decl=decl
	End
	
	Method ToString$()
		Return "VarExpr("+decl.ToString()+")"
	End
	
	Method SideEffects?()
		Return False
	End
	
	Method Semant:Expr()
		If exprType Return Self
		If Not decl.IsSemanted() Err "Internal error - decl not semanted: "+decl.ident
		exprType=decl.type
		Return Self
	End
	
	Method SemantSet:Expr( op$,rhs:Expr )
		Return Semant()
	End
	
	Method Trans$()
		Semant
		Return _trans.TransVarExpr( Self )
	End
	
	Method TransVar$()
		Semant
		Return _trans.TransVarExpr( Self )
	End
	
End

Class MemberVarExpr Extends Expr
	Field expr:Expr
	Field decl:VarDecl
	
	Method New( expr:Expr,decl:VarDecl )
		Self.expr=expr
		Self.decl=decl
	End
	
	Method ToString$()
		Return "MemberVarExpr("+expr.ToString()+","+decl.ToString()+")"
	End
	
	Method SideEffects?()
		Return expr.SideEffects()
	End
	
	Method Semant:Expr()
		If exprType Return Self
		If Not decl.IsSemanted() InternalErr
		exprType=decl.type
		Return Self
	End
	
	Method SemantSet:Expr( op$,rhs:Expr )
		Return Semant()
	End
	
	Method Trans$()
		Return _trans.TransMemberVarExpr( Self )
	End
	
	Method TransVar$()
		Return _trans.TransMemberVarExpr( Self )
 	End

End

Class InvokeExpr Extends Expr
	Field decl:FuncDecl
	Field args:Expr[]

	Method New( decl:FuncDecl,args:Expr[] )
		Self.decl=decl
		Self.args=args
	End
	
	Method ToString$()
		Local t$="InvokeExpr("+decl.ToString()
		For Local arg:=Eachin args
			t+=","+arg.ToString()
		Next
		Return t+")"
	End
	
	Method Semant:Expr()
		If exprType Return Self
		exprType=decl.retType
		args=CastArgs( args,decl )
		Return Self
	End
	
	Method Trans$()
'		Return _trans.TransTemplateCast( exprType,FuncDecl(decl.actual).retType,_trans.TransInvokeExpr( Self ) )
		Return _trans.TransInvokeExpr( Self )
	End
	
	Method TransStmt$()
		Return _trans.TransInvokeExpr( Self )
	End

End

Class InvokeMemberExpr Extends Expr
	Field expr:Expr
	Field decl:FuncDecl
	Field args:Expr[]
	Field isResize	'FIXME - butt ugly!
	
	Method New( expr:Expr,decl:FuncDecl,args:Expr[] )
		Self.expr=expr
		Self.decl=decl
		Self.args=args
	End
	
	Method ToString$()
		Local t$="InvokeMemberExpr("+expr.ToString()+","+decl.ToString()
		For Local arg:=Eachin args
			t+=","+arg.ToString()
		Next
		Return t+")"
	End
	
	Method Semant:Expr()
		If exprType Return Self
		
		exprType=decl.retType
		args=CastArgs( args,decl )

		'Array $resize hack!
		If ArrayType( exprType ) And VoidType( ArrayType( exprType ).elemType )
			isResize=True
			exprType=expr.exprType
		Endif
		
		Return Self
	End
	
	Method Trans$()
		'Array $resize hack!
		If isResize Return _trans.TransInvokeMemberExpr( Self )
		Return _trans.TransInvokeMemberExpr( Self )
	End
	
	Method TransStmt$()
		Return _trans.TransInvokeMemberExpr( Self )
	End
	
End

Class NewObjectExpr Extends Expr
	Field ty:Type
	Field args:Expr[]
	Field ctor:FuncDecl	
	Field classDecl:ClassDecl
	
	Method New( ty:Type,args:Expr[] )
		Self.ty=ty
		Self.args=args
	End
	
	Method Copy:Expr()
		Return New NewObjectExpr( ty,CopyArgs(args) )
	End
	
	Method Semant:Expr()
		If exprType Return Self
		
		ty=ty.Semant()
		args=SemantArgs( args )
		
		Local objTy:ObjectType=ObjectType( ty )
		If Not objTy
			Err "Expression is not a class."
		Endif

		classDecl=objTy.classDecl
		
		If classDecl.IsInterface() Err "Cannot create instance of an interface."
		If classDecl.IsAbstract() Err "Cannot create instance of an abstract class."
		If classDecl.args And Not classDecl.instanceof Err "Cannot create instance of a generic class."

		If classDecl.IsExtern()
			If args Err "No suitable constructor found for class "+classDecl.ToString()+"."
		Else				
			ctor=classDecl.FindFuncDecl( "new",args )
			If Not ctor	Err "No suitable constructor found for class "+classDecl.ToString()+"."
			args=CastArgs( args,ctor )
		Endif
		
		classDecl.attrs|=CLASS_INSTANCED

		exprType=ty
		Return Self
	End
	
	Method Trans$()
		Return _trans.TransNewObjectExpr( Self )
	End
End

Class NewArrayExpr Extends Expr
	Field ty:Type
	Field expr:Expr
	
	Method New( ty:Type,expr:Expr )
		Self.ty=ty
		Self.expr=expr
	End
	
	Method Copy:Expr()
		If exprType InternalErr
		Return New NewArrayExpr( ty,CopyExpr(expr) )
	End
	
	Method Semant:Expr()
		If exprType Return Self
		
		ty=ty.Semant()
		exprType=ty.ArrayOf()
		expr=expr.Semant( Type.intType )
		Return Self
	End
	
	Method Trans$()
		Return _trans.TransNewArrayExpr( Self )
	End

End

'	super.ident( args )
Class InvokeSuperExpr Extends Expr
	Field ident$
	Field args:Expr[]
	Field funcDecl:FuncDecl
'	Field classScope:ClassDecl
'	Field superClass:ClassDecl

	Method New( ident$,args:Expr[] )
		Self.ident=ident
		Self.args=args
	End
	
	Method Copy:Expr()
		Return New InvokeSuperExpr( ident,CopyArgs(args) )
	End
	
	Method Semant:Expr()
		If exprType Return Self
	
		If _env.FuncScope().IsStatic() Err "Illegal use of Super."
		
		Local classScope:=_env.ClassScope()
		Local superClass:=classScope.superClass
'		classScope=_env.ClassScope()
'		superClass=classScope.superClass

		If Not superClass Err "Class has no super class."

		args=SemantArgs( args )
		funcDecl=superClass.FindFuncDecl( ident,args )
		If Not funcDecl Err "Can't find superclass method '"+ident+"'."
		
		If funcDecl.IsAbstract() Err "Can't invoke abstract superclass method '"+ident+"'."
		
		args=CastArgs( args,funcDecl )
		exprType=funcDecl.retType
		Return Self
	End
	
	Method Trans$()
		Return _trans.TransInvokeSuperExpr( Self )
	End

End

'	Self
Class SelfExpr Extends Expr

	Method Copy:Expr()
		Return New SelfExpr
	End
	
	Method SideEffects?()
		Return False
	End
	
	Method Semant:Expr()
		If exprType Return Self
		
		If _env.FuncScope()
			If _env.FuncScope().IsStatic() Err "Illegal use of Self within static scope."
		Else
			Err "Self cannot be used here."
		Endif

		exprType=_env.ClassScope().objectType
		Return Self
	End
	
	Method Trans$()
		Return _trans.TransSelfExpr( Self )
	End

End

Const CAST_EXPLICIT=1

Class CastExpr Extends Expr
	Field ty:Type
	Field expr:Expr
	Field flags
	
	Method New( ty:Type,expr:Expr,flags=0 )
		Self.ty=ty
		Self.expr=expr
		Self.flags=flags
	End
	
	Method Copy:Expr()
		Return New CastExpr( ty,CopyExpr(expr),flags )
	End
	
	Method Semant:Expr()
		If exprType Return Self
		
		ty=ty.Semant()
		expr=expr.Semant()
		
		Local src:Type=expr.exprType
		
		'equal?
		If src.EqualsType( ty ) Return expr
		
		'upcast?
		If src.ExtendsType( ty )
		
			'cast from void[] to T[]
			If ArrayType(src) And VoidType( ArrayType(src).elemType )
				Return New ConstExpr( ty,"" ).Semant()
			Endif
		
			'Box/unbox?...
			If ObjectType( ty ) And Not ObjectType( src )

				'Box!
				expr=New NewObjectExpr( ty,[expr] ).Semant()
				
			Else If ObjectType( src ) And Not ObjectType( ty )
			
				'Unbox!
				Local op$
				If BoolType( ty )
					op="ToBool"
				Else If IntType( ty ) 
					op="ToInt"
				Else If FloatType( ty )
					op="ToFloat"
				Else If StringType( ty )
					op="ToString"
				Else
					InternalErr
				Endif
				Local fdecl:FuncDecl=src.GetClass().FindFuncDecl( op,[] )
				expr=New InvokeMemberExpr( expr,fdecl,[] ).Semant()

			Endif

			exprType=ty

		Else If BoolType( ty )
		
			If VoidType( src )				
				Err "Cannot convert from Void to Bool."
			Endif

			If  flags & CAST_EXPLICIT 
				exprType=ty
			Endif
			
		Else If ty.ExtendsType( src )
		
			If flags & CAST_EXPLICIT
			
				'if both objects or both non-objects...
				If (ObjectType(ty)<>Null)=(ObjectType(src)<>Null) exprType=ty

			Endif
'#rem			
		Else If ObjectType( ty ) And ObjectType( src )
		
			If flags & CAST_EXPLICIT
			
				If src.GetClass().IsInterface() Or ty.GetClass().IsInterface
					exprType=ty
				Endif

			Endif
'#end			
		Endif
		
		If Not exprType
			Err "Cannot convert from "+src.ToString()+" to "+ty.ToString()+"."
		Endif
		
		If ConstExpr( expr ) Return EvalConst()

		Return Self
	End
	
	Method Eval$()
		Local val$=expr.Eval()
		If Not val Return val
		If BoolType( exprType )
			If IntType( expr.exprType )
				If Int( val ) Return "1"
				Return ""
			Else If FloatType( expr.exprType )
				If Float( val ) Return "1"
				Return ""
			Else If StringType( expr.exprType )
				If val.Length Return "1"
				Return ""
			Endif
		Else If IntType( exprType )
			If BoolType( expr.exprType )
				If val Return "1"
				Return "0"
			Endif
			Return Int( val )
		Else If FloatType( exprType )
			Return Float( val )
		Else If StringType( exprType )
			Return String( val )
		Endif
		Return Super.Eval()
	End
	
	Method Trans$()
		Return _trans.TransCastExpr( Self )
	End

End

'op = '+', '-', '~' 
Class UnaryExpr Extends Expr
	Field op$,expr:Expr
	
	Method New( op$,expr:Expr )
		Self.op=op
		Self.expr=expr
	End
	
	Method Copy:Expr()
		Return New UnaryExpr( op,CopyExpr(expr) )
	End
	
	Method Semant:Expr()
		If exprType Return Self
		
		Select op
		Case "+","-"
			expr=expr.Semant()
			If Not NumericType( expr.exprType ) Err expr.ToString()+" must be numeric for use with unary operator '"+op+"'"
			exprType=expr.exprType
		Case "~~"
			expr=expr.Semant( Type.intType )
			exprType=Type.intType
		Case "not"
			expr=expr.Semant( Type.boolType,CAST_EXPLICIT )
			exprType=Type.boolType
		Default
			InternalErr
		End Select
		
		If ConstExpr( expr ) Return EvalConst()

		Return Self
	End
	
	Method Eval$()
		Local val$=expr.Eval()
		Select op
		Case "~~"
			Return ~Int( val )
		Case "+"
			Return val
		Case "-"
			If val.StartsWith( "-" ) Return val[1..]
			Return "-"+val
		Case "not"
			If val Return ""
			Return "1"
		End Select
		InternalErr
	End
	
	Method Trans$()
		Return _trans.TransUnaryExpr( Self )
	End

End

Class BinaryExpr Extends Expr
	Field op$
	Field lhs:Expr
	Field rhs:Expr
	
	Method New( op$,lhs:Expr,rhs:Expr )
		Self.op=op
		Self.lhs=lhs
		Self.rhs=rhs
	End
	
	Method Trans$()
		Return _trans.TransBinaryExpr( Self )
	End

End

' * / mod + - & | ~ shl shr
Class BinaryMathExpr Extends BinaryExpr

	Method New( op$,lhs:Expr,rhs:Expr )
		Self.op=op
		Self.lhs=lhs
		Self.rhs=rhs
	End
	
	Method Copy:Expr()
		Return New BinaryMathExpr( op,CopyExpr(lhs),CopyExpr(rhs) )
	End
	
	Method Semant:Expr()
		If exprType Return Self
	
		lhs=lhs.Semant()
		rhs=rhs.Semant()
		
		Select op
		Case "&","~~","|","shl","shr"
			exprType=Type.intType
		Default
			exprType=BalanceTypes( lhs.exprType,rhs.exprType )
			If StringType( exprType )
				If op<>"+" 
					Err "Illegal string operator."
				Endif
			Else If Not NumericType( exprType )
				Err "Illegal expression type."
			Endif
		End Select
		
		lhs=lhs.Cast( exprType )
		rhs=rhs.Cast( exprType )
		
		If ConstExpr( lhs ) And ConstExpr( rhs ) Return EvalConst()

		Return Self
	End
	
	Method Eval$()
		Local lhs$=Self.lhs.Eval()
		Local rhs$=Self.rhs.Eval()
		If IntType( exprType )
			Local x=Int(lhs),y=Int(rhs)
			Select op
			Case "/" 
				If Not y Err "Divide by zero error."
				Return x/y
			Case "*" Return x*y
			Case "mod"
				If Not y Err "Divide by zero error."
				Return x Mod y
			Case "shl" Return x Shl y
			Case "shr" Return x Shr y
			Case "+" Return x + y
			Case "-" Return x - y
			Case "&" Return x & y
			Case "~~" Return x ~ y
			Case "|" Return x | y
			End
		Else If FloatType( exprType )
			Local x#=Float(lhs),y#=Float(rhs)
			Select op
			Case "/" 
				If Not y Err "Divide by zero error."
				Return x / y
			Case "*" Return x * y
			Case "+" Return x + y
			Case "-" Return x - y
			End
		Else If StringType( exprType )
			Select op
			Case "+" Return lhs+rhs
			End
		Endif
		InternalErr
	End
	
End

'=,<>,<,<=,>,>=
Class BinaryCompareExpr Extends BinaryExpr
	Field ty:Type

	Method New( op$,lhs:Expr,rhs:Expr )
		Self.op=op
		Self.lhs=lhs
		Self.rhs=rhs
	End
	
	Method Copy:Expr()
		Return New BinaryCompareExpr( op,CopyExpr(lhs),CopyExpr(rhs) )
	End
	
	Method Semant:Expr()
		If exprType Return Self
		
		lhs=lhs.Semant()
		rhs=rhs.Semant()

		ty=BalanceTypes( lhs.exprType,rhs.exprType )
		
		If ArrayType( ty ) Err "Arrays cannot be compared."

		If BoolType( ty ) And op<>"=" And op<>"<>" Err "Bools can only be compared for equality."
		
		If ObjectType( ty ) And op<>"=" And op<>"<>" Err "Objects can only be compared for equality."

		lhs=lhs.Cast( ty )
		rhs=rhs.Cast( ty )

		exprType=Type.boolType
		
		If ConstExpr( lhs ) And ConstExpr( rhs ) Return EvalConst()
		
		Return Self
	End
	
	Method Eval$()
		Local r=-1
		If BoolType( ty )
			Local lhs:=Self.lhs.Eval()
			Local rhs:=Self.rhs.Eval()
			Select op
			Case "="  r=(lhs= rhs)
			Case "<>" r=(lhs<>rhs)
			End Select
		Else If IntType( ty )
			Local lhs:=Int( Self.lhs.Eval() )
			Local rhs:=Int( Self.rhs.Eval() )
			Select op
			Case "="  r=(lhs= rhs)
			Case "<>" r=(lhs<>rhs)
			Case "<"  r=(lhs< rhs)
			Case "<=" r=(lhs<=rhs)
			Case ">"  r=(lhs> rhs)
			Case ">=" r=(lhs>=rhs)
			End Select
		Else If FloatType( ty )
			Local lhs:=Float( Self.lhs.Eval() )
			Local rhs:=Float( Self.rhs.Eval() )
			Select op
			Case "="  r=(lhs= rhs)
			Case "<>" r=(lhs<>rhs)
			Case "<"  r=(lhs< rhs)
			Case "<=" r=(lhs<=rhs)
			Case ">"  r=(lhs> rhs)
			Case ">=" r=(lhs>=rhs)
			End Select
		Else If StringType( ty )
			Local lhs:=String( Self.lhs.Eval() )
			Local rhs:=String( Self.rhs.Eval() )
			Select op
			Case "="  r=(lhs= rhs)
			Case "<>" r=(lhs<>rhs)
			Case "<"  r=(lhs< rhs)
			Case "<=" r=(lhs<=rhs)
			Case ">"  r=(lhs> rhs)
			Case ">=" r=(lhs>=rhs)
			End Select
		Endif
		If r=1 Return "1"
		If r=0 Return ""
		InternalErr
	End
End

'and, or
Class BinaryLogicExpr Extends BinaryExpr

	Method New( op$,lhs:Expr,rhs:Expr )
		Self.op=op
		Self.lhs=lhs
		Self.rhs=rhs
	End
	
	Method Copy:Expr()
		Return New BinaryLogicExpr( op,CopyExpr(lhs),CopyExpr(rhs) )
	End
	
	Method Semant:Expr()
		If exprType Return Self
		
		lhs=lhs.Semant( Type.boolType,CAST_EXPLICIT )
		rhs=rhs.Semant( Type.boolType,CAST_EXPLICIT )
		
		exprType=Type.boolType
		
		If ConstExpr( lhs ) And ConstExpr( rhs ) Return EvalConst()
		
		Return Self
	End
	
	Method Eval$()
		Select op
		Case "and" If lhs.Eval() And rhs.Eval() Return "1" Else Return ""
		Case "or"  If lhs.Eval() Or rhs.Eval() Return "1" Else Return ""
		End Select
		InternalErr
	End
End

Class IndexExpr Extends Expr
	Field expr:Expr
	Field index:Expr
	
	Method New( expr:Expr,index:Expr )
		Self.expr=expr
		Self.index=index
	End
	
	Method Copy:Expr()
		Return New IndexExpr( CopyExpr(expr),CopyExpr(index) )
	End
	
	Method SideEffects?()
		Return ENV_CONFIG="debug"
	End
	
	Method Semant:Expr()
		If exprType Return Self
	
		expr=expr.Semant()
		index=index.Semant( Type.intType )
		
		If StringType( expr.exprType )
			exprType=Type.intType
		Else If ArrayType( expr.exprType )
			exprType=ArrayType( expr.exprType ).elemType
		Else
			Err "Only strings and arrays may be indexed."
		Endif
		
		If StringType( expr.exprType ) And ConstExpr( expr ) And ConstExpr( index ) Return EvalConst()

		Return Self
	End
	
	Method Eval$()
		If StringType( expr.exprType )
			Local str:=expr.Eval()
			Local idx:=Int( index.Eval() )
			If idx<0 Or idx>=str.Length Err "String index out of range."
			Return String( str[idx] )
		Endif
		InternalErr
	End
	
	Method SemantSet:Expr( op$,rhs:Expr )
		Semant
		If StringType( expr.exprType ) Err "Strings are read only."
		Return Self
	End

	Method Trans$()
		Return _trans.TransIndexExpr( Self )
	End
	
	Method TransVar$()
		Return _trans.TransIndexExpr( Self )
	End

End

Class SliceExpr Extends Expr
	Field expr:Expr
	Field from:Expr
	Field term:Expr
	
	Method New( expr:Expr,from:Expr,term:Expr )
		Self.expr=expr
		Self.from=from
		Self.term=term
	End
	
	Method Copy:Expr()
		Return New SliceExpr( CopyExpr(expr),CopyExpr(from),CopyExpr(term) )
	End
	
	Method Semant:Expr()
		If exprType Return Self
	
		expr=expr.Semant()
		If ArrayType( expr.exprType ) Or StringType( expr.exprType )
			If from from=from.Semant( Type.intType )
			If term term=term.Semant( Type.intType )
			exprType=expr.exprType
		Else
			Err "Slices can only be used on strings or arrays."
		Endif
		
'		If ConstExpr( expr ) And ConstExpr( from ) And ConstExpr( term ) Return EvalConst()

		Return Self
	End
	
	Method Eval$()
		Local from=Int( Self.from.Eval() )
		Local term=Int( Self.term.Eval() )
		If StringType( expr.exprType )
			Return expr.Eval()[ from..term ]
		Else If ArrayType( expr.exprType )
			Err "TODO!"
		Endif
	End
	
	Method Trans$()
		Return _trans.TransSliceExpr( Self )
	End
End

Class ArrayExpr Extends Expr
	Field exprs:Expr[]
	
	Method New( exprs:Expr[] )
		Self.exprs=exprs
	End
	
	Method Copy:Expr()
		Return New ArrayExpr( CopyArgs(exprs) )
	End

	Method Semant:Expr()
		If exprType Return Self
		
		exprs[0]=exprs[0].Semant()
		Local ty:Type=exprs[0].exprType
		
		For Local i=1 Until exprs.Length
			exprs[i]=exprs[i].Semant()
			ty=BalanceTypes( ty,exprs[i].exprType )
		Next
		
		For Local i=0 Until exprs.Length
			exprs[i]=exprs[i].Cast( ty )
		Next
		
		exprType=ty.ArrayOf()
		Return Self	
	End
	
	Method Trans$()
		Return _trans.TransArrayExpr( Self )
	End

End
