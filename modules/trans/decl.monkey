
' Module trans.decl
'
' Placed into the public domain 24/02/2011.
' No warranty implied; use at your own risk.

Import trans

Const DECL_EXTERN=		$000100
Const DECL_PRIVATE=		$000200
Const DECL_ABSTRACT=	$000400
Const DECL_FINAL=		$000800
Const DECL_PROTECTED=	$004000

Const CLASS_INTERFACE=	$001000
Const CLASS_THROWABLE=	$002000

Const DECL_SEMANTED=	$100000
Const DECL_SEMANTING=	$200000

Const DECL_NODEBUG=		$400000
Const DECL_REFLECTOR=	$800000

Global _env:ScopeDecl
Global _envStack:=New List<ScopeDecl>

Global _loopnest

Function PushEnv( env:ScopeDecl )
	_envStack.AddLast _env
	_env=env
End Function

Function PopEnv()
	If _envStack.IsEmpty() InternalErr
	_env=ScopeDecl( _envStack.RemoveLast() )
End Function

Class FuncDeclList Extends List<FuncDecl>

End

Class Decl
	Field ident$
	Field attrs
	Field munged$
	Field errInfo$
	Field scope:ScopeDecl
	
	Method New()
		errInfo=_errInfo
	End
	
	Method OnCopy:Decl() Abstract
	
	Method OnSemant() Abstract
	
	Method ToString$()
		If ClassDecl( scope ) Return scope.ToString()+"."+ident
		Return ident
	End
	
	Method IsExtern()
		Return (attrs & DECL_EXTERN)<>0
	End
	
	Method IsPublic()
		Return (attrs & (DECL_PRIVATE|DECL_PROTECTED))=0
	End
	
	Method IsPrivate()
		Return (attrs & DECL_PRIVATE)<>0
	End
	
	Method IsProtected()
		Return (attrs & DECL_PROTECTED)<>0
	End
	
	Method IsFinal()
		Return (attrs & DECL_FINAL)<>0
	End
	
	Method IsAbstract()
		Return (attrs & DECL_ABSTRACT)<>0
	End
	
	Method IsSemanted()
		Return (attrs & DECL_SEMANTED)<>0
	End
	
	Method IsSemanting()
		Return (attrs & DECL_SEMANTING)<>0
	End
	
	Method FuncScope:FuncDecl()
		If FuncDecl( Self ) Return FuncDecl( Self )
		If scope Return scope.FuncScope()
	End

	Method ClassScope:ClassDecl()
		If ClassDecl( Self ) Return ClassDecl( Self )
		If scope Return scope.ClassScope()
	End
	
	Method ModuleScope:ModuleDecl()
		If ModuleDecl( Self ) Return ModuleDecl( Self )
		If scope Return scope.ModuleScope()
	End
	
	Method AppScope:AppDecl()
		If AppDecl( Self ) Return AppDecl( Self )
		If scope Return scope.AppScope()
	End
	
	Method CheckAccess()

		' if no environment, just let us through
		If Not _env Return True
		
		' if public, always accessible
		If IsPublic() Return True
		
		Local mdecl:=ModuleScope()
		If mdecl
			Local mdecl2:=_env.ModuleScope()
			If mdecl=mdecl2 Return True
			If mdecl2 And mdecl.friends.Contains( mdecl2.rmodpath ) Return True
		Endif
		
		' if same module, always accessible
		'If ModuleScope()=_env.ModuleScope() Return True
		
		'if protected...
		If IsProtected()
			Local thisClass:=ClassScope()
			Local currentClass:=_env.ClassScope()
			While currentClass
				If currentClass=thisClass Return True
				currentClass=currentClass.superClass
			End
		End
		
		'accessible if reflecting
		Local fdecl:=_env.FuncScope()
		If fdecl And fdecl.attrs & DECL_REFLECTOR Return True
		
		Return False	

	End
	
	Method AssertAccess()
		If CheckAccess() Return
		If IsPrivate() Err ToString()+" is private."
		If IsProtected() Err ToString()+" is protected."
		Err ToString()+" is inaccessible."
	End
	
	Method Copy:Decl()
		Local t:=OnCopy()
		t.munged=munged
		t.errInfo=errInfo
		Return t
	End

	Method Semant()
		If IsSemanted() Return
		
		If IsSemanting() Err "Cyclic declaration of '"+ident+"'."

		Local cscope:=ClassDecl( scope )

		If cscope cscope.attrs&=~CLASS_FINALIZED
		
		PushErr errInfo
		
		If scope
			PushEnv scope
		Endif
		
		attrs|=DECL_SEMANTING

'		If ident Print "Semanting: "+ident

		OnSemant
		
		attrs&=~DECL_SEMANTING

		attrs|=DECL_SEMANTED

		If scope 
			If IsExtern()
				If ModuleDecl( scope )
					AppScope.allSemantedDecls.AddLast Self
				Endif
			Else

				scope.semanted.AddLast Self
				
				If GlobalDecl( Self )
					AppScope.semantedGlobals.AddLast GlobalDecl( Self )
				Endif
				
				If ModuleDecl( scope )
					AppScope.semanted.AddLast Self
					AppScope.allSemantedDecls.AddLast Self
				Endif
			
			Endif
			
			PopEnv
		Endif
		
		PopErr
	End

End

Class ValDecl Extends Decl

	Field type:Type
	Field init:Expr
	
	Method ToString$()
		Local t$=Super.ToString()
		If type Return t+":"+type.ToString()
		Return t
	End

	Method CopyInit:Expr()
		If init Return init.Copy()
	End
	
	Method OnSemant()
		If type
			type=type.Semant()
			If init init=init.Semant( type )
		Else If init
			init=init.Semant()
			type=init.exprType
		Else
			InternalErr
		Endif
		If VoidType( type ) Err "Declaration has void type."
	End
	
End

Class ConstDecl Extends ValDecl
	Field value$
	
	Method New( ident$,attrs,type:Type,init:Expr )
		Self.ident=ident
		Self.munged=ident
		Self.attrs=attrs
		Self.type=type
		Self.init=init
	End
	
	Method OnCopy:Decl()
		Return New ConstDecl( ident,attrs,type,CopyInit() )
	End
	
	Method OnSemant()
		Super.OnSemant()
		If Not IsExtern() value=init.Eval()
	End
	
End

Class VarDecl Extends ValDecl

End

Class LocalDecl Extends VarDecl

	Method New( ident$,attrs,type:Type,init:Expr )
		Self.ident=ident
		Self.attrs=attrs
		Self.type=type
		Self.init=init
	End
	
	Method OnCopy:Decl()
		Return New LocalDecl( ident,attrs,type,CopyInit() )
	End
	
	Method ToString$()
		Return "Local "+Super.ToString()
	End

End

Class ArgDecl Extends LocalDecl
	
	Method New( ident$,attrs,type:Type,init:Expr )
		Self.ident=ident
		Self.attrs=attrs
		Self.type=type
		Self.init=init
	End
	
	Method OnCopy:Decl()
		Return New ArgDecl( ident,attrs,type,CopyInit() )
	End
	
	Method ToString$()
		Return Super.ToString()
	End
	
End

Class GlobalDecl Extends VarDecl
	
	Method New( ident$,attrs,type:Type,init:Expr )
		Self.ident=ident
		Self.attrs=attrs
		Self.type=type
		Self.init=init
	End
	
	Method OnCopy:Decl()
		Return New GlobalDecl( ident,attrs,type,CopyInit() )
	End
	
	Method ToString$()
		Return "Global "+Super.ToString()
	End

End

Class FieldDecl Extends VarDecl

	Method New( ident$,attrs,type:Type,init:Expr )
		Self.ident=ident
		Self.attrs=attrs
		Self.type=type
		Self.init=init
	End
	
	Method OnCopy:Decl()
		Return New FieldDecl( ident,attrs,type,CopyInit() )
	End
	
	Method ToString$()
		Return "Field "+Super.ToString()
	End
	
End

Class AliasDecl Extends Decl

	Field decl:Object
	
	Method New( ident$,attrs,decl:Object )
		Self.ident=ident
		Self.attrs=attrs
		Self.decl=decl
	End
	
	Method OnCopy:Decl()
		Return New AliasDecl( ident,attrs,decl )
	End
	
	Method OnSemant()
	End
	
End

Class ScopeDecl Extends Decl

	Global GetDecl_Fail:Int
	Global GetDecl_Success:Int

Private

	Field decls:=New List<Decl>
	Field semanted:=New List<Decl>
	Field declsMap:=New StringMap<Object>

Public

	Method OnCopy:Decl()
		InternalErr
	End

	Method Decls:List<Decl>()
		Return decls
	End
	
	Method Semanted:List<Decl>()
		Return semanted
	End
	
	Method FuncDecls:List<FuncDecl>( id$="" )
		Local fdecls:=New List<FuncDecl>
		For Local decl:Decl=Eachin decls
			If id And decl.ident<>id Continue
			Local fdecl:=FuncDecl( decl )
			If fdecl fdecls.AddLast fdecl
		Next
		Return fdecls
	End
	
	Method MethodDecls:List<FuncDecl>( id$="" )
		Local fdecls:=New List<FuncDecl>
		For Local decl:Decl=Eachin decls
			If id And decl.ident<>id Continue
			Local fdecl:=FuncDecl( decl )
			If fdecl And fdecl.IsMethod() fdecls.AddLast fdecl
		Next
		Return fdecls
	End
	
	Method SemantedFuncs:List<FuncDecl>( id$="" )
		Local fdecls:=New List<FuncDecl>
		For Local decl:Decl=Eachin semanted
			If id And decl.ident<>id Continue
			Local fdecl:=FuncDecl( decl )
			If fdecl fdecls.AddLast fdecl
		Next
		Return fdecls
	End
	
	Method SemantedMethods:List<FuncDecl>( id$="" )
		Local fdecls:=New List<FuncDecl>
		For Local decl:Decl=Eachin semanted
			If id And decl.ident<>id Continue
			Local fdecl:=FuncDecl( decl )
			If fdecl And fdecl.IsMethod() fdecls.AddLast fdecl
		Next
		Return fdecls
	End
	
	Method InsertDecl( decl:Decl )
		If decl.scope InternalErr
		
		Local ident$=decl.ident
		If Not ident Return
		
		decl.scope=Self
		decls.AddLast decl
		
		Local decls:StringMap<Object>
		Local tdecl:=declsMap.Get( ident )
		
		If FuncDecl( decl )
			Local funcs:=FuncDeclList( tdecl )
			If funcs Or Not tdecl
				If Not funcs
					funcs=New FuncDeclList
					declsMap.Insert ident,funcs
				Endif
				funcs.AddLast FuncDecl( decl )
			Else
				Err "Duplicate identifier '"+ident+"'."
			Endif
		Else If Not tdecl
			declsMap.Insert ident,decl
		Else
			Err "Duplicate identifier '"+ident+"'."
		Endif
		
		If decl.IsSemanted() semanted.AddLast decl

	End

	Method InsertDecls( decls:List<Decl> )
		For Local decl:Decl=Eachin decls
			InsertDecl decl
		Next
	End
	
	'This is overridden by ClassDecl and ModuleDecl
	Method GetDecl:Object( ident$ )
		Local decl:=declsMap.Get( ident )
		If Not decl Return
		
		Local adecl:=AliasDecl( decl )
		If Not adecl Return decl
		
		If adecl.CheckAccess() Return adecl.decl
	End
	
	Method FindDecl:Object( ident$ )
	
		If _env<>Self Return GetDecl( ident )
		
		Local tscope:=Self
		While tscope
			Local decl:=tscope.GetDecl( ident )
			If decl Return decl
			tscope=tscope.scope
		Wend
	End
	
	Method FindValDecl:ValDecl( ident$ )
		Local decl:=ValDecl( FindDecl( ident ) )
		If Not decl Return
		decl.AssertAccess
		decl.Semant
		Return decl
	End
	
	Method FindType:Type( ident$,args:Type[] )
		Local decl:=GetDecl( ident )
		If decl
			Local type:=Type( decl )
			If type
				If args.Length Err "Wrong number of type arguments"
				Return type
			Endif
			Local cdecl:=ClassDecl( decl )
			If cdecl
				cdecl.AssertAccess
				cdecl=cdecl.GenClassInstance( args )
				cdecl.Semant
				Return cdecl.objectType
			Endif
		Endif
		If scope Return scope.FindType( ident,args )
	End
	
	Method FindScopeDecl:ScopeDecl( ident$ )
		Local decl:=FindDecl( ident )
		Local type:=Type( decl )
		If type
			If Not ObjectType( type ) Return
			Return type.GetClass()
		Endif
		Local scope:=ScopeDecl( decl )
		If scope
			Local cdecl:=ClassDecl( scope )
			If cdecl And cdecl.args Return
			scope.AssertAccess
			scope.Semant
			Return scope
		Endif
	End
	
	Method FindModuleDecl:ModuleDecl( ident$ )
		Local decl:=ModuleDecl( GetDecl( ident ) )
		If decl
			decl.AssertAccess
			decl.Semant
			Return decl
		Endif
		If scope Return scope.FindModuleDecl( ident )
	End
	
	Method FindFuncDecl:FuncDecl( ident$,argExprs:Expr[],explicit=False )
	
		Local funcs:=FuncDeclList( FindDecl( ident ) )
		If Not funcs Return
	
		For Local func:=Eachin funcs
			func.Semant()
		Next
		
		Local match:FuncDecl,isexact,err$

		For Local func:FuncDecl=Eachin funcs
'			If Not func.CheckAccess() Continue
			
			Local argDecls:ArgDecl[]=func.argDecls
			
			If argExprs.Length>argDecls.Length Continue
			
			Local exact=True
			Local possible=True
			
			For Local i=0 Until argDecls.Length

				If i<argExprs.Length And argExprs[i]
				
					Local declTy:Type=argDecls[i].type
					Local exprTy:Type=argExprs[i].exprType
					
					If exprTy.EqualsType( declTy ) Continue
					
					exact=False
					
					If Not explicit And exprTy.ExtendsType( declTy ) Continue

				Else If argDecls[i].init
				
					If Not explicit Continue
					
				Endif
			
				possible=False
				Exit
			Next
			
			If Not possible Continue
			
			If exact
				If isexact
					Err "Unable to determine overload to use: "+match.ToString()+" or "+func.ToString()+"."
				Else
					err=""
					match=func
					isexact=True
				Endif
			Else
				If Not isexact
					If match 
						err="Unable to determine overload to use: "+match.ToString()+" or "+func.ToString()+"."
					Else
						match=func
					Endif
				Endif
			Endif
			
		Next
		
		If Not isexact
			If err Err err
			If explicit Return
		Endif
		
		If Not match
			Local t$
			For Local i=0 Until argExprs.Length
				If t t+=","
				If argExprs[i] t+=argExprs[i].exprType.ToString()
			Next
			Err "Unable to find overload for "+ident+"("+t+")."
		Endif
		
		match.AssertAccess

		Return match
	End
	
	Method OnSemant()
	End
	
End

Class BlockDecl Extends ScopeDecl
	Field stmts:=New List<Stmt>
	
	Method New( scope:ScopeDecl )
		Self.scope=scope
		
	End
	
	Method AddStmt( stmt:Stmt )
		stmts.AddLast stmt
	End
	
	Method OnCopy:Decl()
		Local t:=New BlockDecl
		For Local stmt:=Eachin stmts
			t.AddStmt stmt.Copy( t )
		Next
		Return t
	End
	
	Method OnSemant()
		PushEnv Self
		For Local stmt:Stmt=Eachin stmts
			stmt.Semant
		Next
		PopEnv
	End
	
	Method CopyBlock:BlockDecl( scope:ScopeDecl )
		Local t:=BlockDecl( Copy() )
		t.scope=scope
		Return t
	End
	
End

Const FUNC_METHOD=1		'mutually exclusive with ctor
Const FUNC_CTOR=2
Const FUNC_PROPERTY=4
Const FUNC_CALLSCTOR=8
Const FUNC_OVERRIDDEN=16

'Fix! A func is NOT a block/scope!
'
Class FuncDecl Extends BlockDecl

	Field retType:Type
	Field argDecls:ArgDecl[]

	Field overrides:FuncDecl
	
	Method New( ident$,attrs,retType:Type,argDecls:ArgDecl[] )
		Self.ident=ident
		Self.attrs=attrs
		Self.retType=retType
		Self.argDecls=argDecls
	End
	
	Method OnCopy:Decl()
		Local args:=argDecls[..]
		For Local i=0 Until args.Length
			args[i]=ArgDecl( args[i].Copy() )
		Next
		Local t:=New FuncDecl( ident,attrs,retType,args )
		For Local stmt:=Eachin stmts
			t.AddStmt stmt.Copy( t )
		Next
		Return  t
	End
	
	Method OnSemant()

		'get cdecl, sclass
		Local cdecl:=ClassScope(),sclass:ClassDecl
		
		If cdecl sclass=ClassDecl( cdecl.superClass )
		
		'semant ret type
		If IsCtor()
			retType=cdecl.objectType
		Else
			retType=retType.Semant()
		Endif
		
		'semant args
		For Local arg:=Eachin argDecls
			InsertDecl arg
			arg.Semant
		Next
		
		'check for duplicate decl
		For Local decl:=Eachin scope.SemantedFuncs( ident )
			If decl<>Self And EqualsArgs( decl )
				Err "Duplicate declaration "+ToString()
			Endif
		Next
		
		'prefix call to super ctor if necessary
		If IsCtor() And Not (attrs & FUNC_CALLSCTOR)
			If sclass.FindFuncDecl( "new",[] )
				Local expr:=New InvokeSuperExpr( "new",[] )
				stmts.AddFirst New ExprStmt( expr )
			Endif
		Endif
		
		'Find an override
		If sclass And IsMethod()
			While sclass
				Local found
				For Local decl:=Eachin sclass.MethodDecls( ident )
					found=True
					decl.Semant
					If EqualsFunc( decl ) 
						overrides=decl
						decl.attrs|=FUNC_OVERRIDDEN
						Exit
					Endif
				Next
				If found
					If Not overrides Err "Overriding method does not match any overridden method."
					If overrides.IsFinal() Err "Cannot override final method."
					If overrides.munged
						If munged And munged<>overrides.munged InternalErr
						munged=overrides.munged
					Endif
					Exit
				Endif
				sclass=sclass.superClass
			Wend
		Endif
		
		attrs|=DECL_SEMANTED
		
		Super.OnSemant()
	End
	
	Method ToString$()
		Local t$
		For Local decl:ArgDecl=Eachin argDecls
			If t t+=","
			t+=decl.ToString()
		Next
		Local q$
		If IsCtor()
			q="Method "+Super.ToString()
		Else
			If IsMethod() q="Method " Else q="Function "
			q+=Super.ToString()+":"
			q+=retType.ToString()
		Endif
		Return q+"("+t+")"
	End
	
	Method IsCtor?()
		Return (attrs & FUNC_CTOR)<>0
	End

	Method IsMethod?()
		Return (attrs & FUNC_METHOD)<>0
	End
	
	Method IsProperty?()
		Return (attrs & FUNC_PROPERTY)<>0
	End

	Method IsVirtual?()	
		Return (attrs & (DECL_ABSTRACT|FUNC_OVERRIDDEN))<>0
	End

	'Not a method AND not a ctor
	Method IsStatic?()
		Return (attrs & (FUNC_METHOD|FUNC_CTOR))=0
	End
	
	Method EqualsArgs?( decl:FuncDecl )
		If argDecls.Length<>decl.argDecls.Length Return False
		For Local i=0 Until argDecls.Length
			If Not argDecls[i].type.EqualsType( decl.argDecls[i].type ) Return False
		Next
		Return True
	End

	Method EqualsFunc?( decl:FuncDecl )
		Return retType.EqualsType( decl.retType ) And EqualsArgs( decl )
	End
	

End

Const CLASS_INSTANCED=1
Const CLASS_EXTENDSOBJECT=2
Const CLASS_FINALIZED=4

Class ClassDecl Extends ScopeDecl

	Field args$[]
	Field superTy:IdentType
	Field impltys:IdentType[]
	
	Field superClass:ClassDecl
	
	Field implments:ClassDecl[]			'interfaces immediately implemented
	Field implmentsAll:ClassDecl[]		'all interfaces implemented
	
	Field instances:List<ClassDecl>		'for actual (non-arg, non-instance)
	Field instanceof:ClassDecl			'for instances
	Field instArgs:Type[]
	
	Field objectType:ObjectType			'"canned" objectType
	
	Global nullObjectClass:=New ClassDecl( "{NULL}",DECL_ABSTRACT|DECL_EXTERN,[],Null,[] )
	
	Method New( ident$,attrs,args$[],superTy:IdentType,impls:IdentType[] )
		Self.ident=ident
		Self.attrs=attrs
		Self.args=args
		Self.superTy=superTy
		Self.impltys=impls
		Self.objectType=New ObjectType( Self )
		If args instances=New List<ClassDecl>
	End
	
	Method OnCopy:Decl()
		InternalErr
	End
	
	Method ToString$()
		Local t$
		If args
			t=",".Join( args )
		Else If instArgs
			For Local arg:=Eachin instArgs
				If t t+=","
				t+=arg.ToString()
			Next
		Endif
		If t t="<"+t+">"
		Return ident+t
	End
	
	Method GenClassInstance:ClassDecl( instArgs:Type[] )

		If instanceof InternalErr
		
		'no args
		If Not instArgs
			If Not args Return Self
			For Local inst:=Eachin instances
				If _env.ClassScope()=inst Return inst
			Next
		Endif
		
		'check number of args
		If args.Length<>instArgs.Length
			Err "Wrong number of type arguments for class "+ToString()
		Endif
		
		'look for existing instance
		For Local inst:=Eachin instances
			Local equal=True
			For Local i=0 Until args.Length
				If Not inst.instArgs[i].EqualsType( instArgs[i] )
					equal=False
					Exit
				Endif
			Next
			If equal Return inst
		Next
		
		Local inst:=New ClassDecl( ident,attrs,[],superTy,impltys )

		inst.attrs&=~DECL_SEMANTED
		inst.munged=munged
		inst.errInfo=errInfo
		inst.scope=scope
		inst.instanceof=Self
		inst.instArgs=instArgs
		instances.AddLast inst
		
		For Local i=0 Until args.Length
			inst.InsertDecl New AliasDecl( args[i],0,instArgs[i] )
		Next
		
		For Local decl:Decl=Eachin decls
			inst.InsertDecl decl.Copy()
		Next

		Return inst
	End

	Method IsInterface()
		Return (attrs & CLASS_INTERFACE)<>0
	End
	
	Method IsInstanced()
		Return (attrs & CLASS_INSTANCED)<>0
	End
	
	Method IsFinalized()
		Return (attrs & CLASS_FINALIZED)<>0
	End
	
	Method IsThrowable()
		Return (attrs & CLASS_THROWABLE)<>0
	End
	
	Method ExtendsObject()
		Return (attrs & CLASS_EXTENDSOBJECT)<>0
	End
	
	Method GetDecl:Object( ident$ )
		Local cdecl:ClassDecl=Self
		While cdecl
			Local decl:=cdecl.GetDecl2( ident )
			If decl Return decl
			cdecl=cdecl.superClass
		Wend
	End
	
	'needs this 'coz you can't go blah.Super.GetDecl()...
	Method GetDecl2:Object( ident$ )
		Return Super.GetDecl( ident )
	End
	
	Method FindFuncDecl:FuncDecl( ident$,args:Expr[],explicit=False )
	
		If Not IsInterface()
			Return FindFuncDecl2( ident,args,explicit )
		Endif
		
		Local fdecl:=FindFuncDecl2( ident,args,True )
		
		For Local iface:=Eachin implmentsAll
			Local decl:=iface.FindFuncDecl2( ident,args,True )
			If Not decl Continue
			
			If fdecl
				If fdecl.EqualsFunc( decl ) Continue
				Err "Unable to determine overload to use: "+fdecl.ToString()+" or "+decl.ToString()+"."
			Endif
			fdecl=decl
		Next
		
		If fdecl Or explicit Return fdecl
		
		fdecl=FindFuncDecl2( ident,args,False )
		
		For Local iface:=Eachin implmentsAll
			Local decl:=iface.FindFuncDecl2( ident,args,False )
			If Not decl Continue
			
			If fdecl
				If fdecl.EqualsFunc( decl ) Continue
				Err "Unable to determine overload to use: "+fdecl.ToString()+" or "+decl.ToString()+"."
			Endif
			fdecl=decl
		Next
		
		Return fdecl
	End
	
	Method FindFuncDecl2:FuncDecl( ident$,args:Expr[],explicit )
		Return Super.FindFuncDecl( ident,args,explicit )
	End
	
	Method ExtendsClass( cdecl:ClassDecl )
		If Self=nullObjectClass Return True

		Local tdecl:=Self
		While tdecl
			If tdecl=cdecl Return True
			If cdecl.IsInterface()
				For Local iface:=Eachin tdecl.implmentsAll
					If iface=cdecl Return True
				Next
			Endif
			tdecl=tdecl.superClass
		Wend
		
		Return False
	End
	
	Method OnSemant()
	
		If args Return
	
		PushEnv Self
		
		'Semant superclass		
		If superTy
			superClass=superTy.SemantClass()
			If superClass.IsFinal() Err "Cannot extend final class."
			If superClass.IsInterface() Err "Cannot extend an interface."
			If munged="ThrowableObject" Or superClass.IsThrowable() attrs|=CLASS_THROWABLE
			If superClass.ExtendsObject() attrs|=CLASS_EXTENDSOBJECT
		Else
			If munged="Object" attrs|=CLASS_EXTENDSOBJECT
		Endif
		
		'Semant implemented interfaces
		Local impls:=New ClassDecl[impltys.Length]
		Local implsall:=New Stack<ClassDecl>
		For Local i=0 Until impltys.Length
			Local cdecl:=impltys[i].SemantClass()
			If Not cdecl.IsInterface()
				Err cdecl.ToString()+" is a class, not an interface."
			Endif
			For Local j=0 Until i
				If impls[j]=cdecl
					Err "Duplicate interface "+cdecl.ToString()+"."
				Endif
			Next
			impls[i]=cdecl
			implsall.Push cdecl
			For Local tdecl:=Eachin cdecl.implmentsAll
				implsall.Push tdecl
			Next
		Next
		implmentsAll=New ClassDecl[implsall.Length]
		For Local i=0 Until implsall.Length
			implmentsAll[i]=implsall.Get(i)
		Next
		implments=impls

		PopEnv
		
		'Are we abstract?
		If Not IsAbstract()
			For Local decl:Decl=Eachin decls
				Local fdecl:=FuncDecl( decl )
				If fdecl And fdecl.IsAbstract()
					attrs|=DECL_ABSTRACT
					Exit
				Endif
			Next
		Endif

		If Not IsExtern() And Not IsInterface()
			Local fdecl:FuncDecl
			For Local decl:FuncDecl=Eachin FuncDecls
				If Not decl.IsCtor() Continue
				Local nargs
				For Local arg:=Eachin decl.argDecls
					If Not arg.init nargs+=1
				Next
				If nargs Continue
				fdecl=decl
				Exit
			Next
			If Not fdecl
				fdecl=New FuncDecl( "new",FUNC_CTOR,objectType,[] )
				fdecl.AddStmt New ReturnStmt( Null )
				InsertDecl fdecl
			Endif
		Endif
		
		'NOTE: do this AFTER super semant so UpdateAttrs order is cool.
		AppScope.semantedClasses.AddLast Self
	End
	
	'Ok, this dodgy looking beast 'resurrects' methods that may not currently be alive, but override methods that ARE.
	Method UpdateLiveMethods()
	
		If IsFinalized() Return
	
		If IsInterface() Return

		If Not superClass Return

		Local n
		For Local decl:=Eachin MethodDecls
			If decl.IsSemanted() Continue
			
			Local live
			Local unsem:=New List<FuncDecl>
			
			unsem.AddLast decl
			
			Local sclass:=superClass
			While sclass
				For Local decl2:=Eachin sclass.MethodDecls( decl.ident )
					If decl2.IsSemanted()
						live=True
					Else
						unsem.AddLast decl2
						If decl2.IsExtern() live=True
						If decl2.IsSemanted() live=True
					Endif
				Next
				sclass=sclass.superClass
			Wend
			
			If Not live
				Local cdecl:=Self
				While cdecl
					For Local iface:=Eachin cdecl.implmentsAll
						For Local decl2:=Eachin iface.MethodDecls( decl.ident )
							If decl2.IsSemanted()
								live=True
							Else
								unsem.AddLast decl2
								If decl2.IsExtern() live=True
								If decl2.IsSemanted() live=True
							Endif
						Next
					Next
					cdecl=cdecl.superClass
				Wend
			Endif
			
			If Not live Continue
			
			For Local decl:=Eachin unsem
				decl.Semant
				n+=1
			Next
		Next
		
		Return n
	End
	
	Method FinalizeClass()
	
		If IsFinalized() Return
		
		attrs|=CLASS_FINALIZED
	
		If IsInterface() Return

		PushErr errInfo
		
		'check for duplicate fields!
		'
		For Local decl:=Eachin Semanted
			Local fdecl:=FieldDecl( decl )
			If Not fdecl Continue
			Local cdecl:=superClass
			While cdecl
				For Local decl:=Eachin cdecl.Semanted
					If decl.ident=fdecl.ident 
						_errInfo=fdecl.errInfo
						Err "Field '"+fdecl.ident+"' in class "+ToString()+" overrides existing declaration in class "+cdecl.ToString()
					Endif
				Next
				cdecl=cdecl.superClass
			Wend
		Next
		'
		'Check we implement all abstract methods!
		'
		If IsAbstract()
			If IsInstanced()
				Err "Can't create instance of abstract class "+ToString()+"."
			Endif
		Else
			Local cdecl:=Self
			Local impls:=New List<FuncDecl>
			While cdecl And Not IsAbstract()
				For Local decl:=Eachin cdecl.SemantedMethods()
					If decl.IsAbstract()
						Local found
						For Local decl2:=Eachin impls
							If decl.ident=decl2.ident And decl.EqualsFunc( decl2 )
								found=True
								Exit
							Endif
						Next
						If Not found
							If IsInstanced()
								Err "Can't create instance of class "+ToString()+" due to abstract method "+decl.ToString()+"."
							Endif
							attrs|=DECL_ABSTRACT
							Exit
						Endif
					Else
						impls.AddLast decl
					Endif
				Next
				cdecl=cdecl.superClass
			Wend
		Endif
		'
		'Check we implement all interface methods!
		'
		For Local iface:=Eachin implmentsAll
		
			'Fancy fix!
			'
			'See if any super class already implements this iface...
			'
			Local cdecl:=superClass,found:=False
			While cdecl
				For Local iface2:=Eachin cdecl.implmentsAll
					If iface<>iface2 Continue
					found=True
					Exit
				Next
				If found Exit
				cdecl=cdecl.superClass
			Wend
			If found Continue
			
			For Local decl:=Eachin iface.SemantedMethods()
				Local found:=False
				For Local decl2:=Eachin SemantedMethods( decl.ident )
					If decl.EqualsFunc( decl2 )
						If decl2.munged
							Err "Extern methods cannot be used to implement interface methods."
						Endif
						found=True
					Endif
				Next
				If Not found
					Err decl.ToString()+" must be implemented by class "+ToString()
				Endif
			Next
		Next
		
		PopErr
		
	End
	
End

Const MODULE_STRICT=1
Const MODULE_SEMANTALL=2

Class DeclMDeclPair
	Field tdecl:Object
	Field mdecl:ModuleDecl
End

Class SynonymList
	Field list:List<DeclMDeclPair> = New List<DeclMDeclPair>
End

Class ModuleDecl Extends ScopeDecl

	Global master_uid:Int = 0
	Global master_im_version:Int = 1
	
	Field uid:Int = 0
	Field indirectMapsVersion:Int = 0
	Field indirectDeclMapPublicOnly:= New StringMap<SynonymList>
	Field indirectDeclMapPublicPrivate:= New StringMap<SynonymList>
	Field accessibleModuleScopesPublic:= New IntMap<ModuleDecl>
	Field accessibleModuleScopesPublicPrivate:= New IntMap<ModuleDecl>

	Field modpath$,rmodpath$,filepath$
	Field imported:=New StringMap<ModuleDecl>		'Maps filepath to modules
	Field pubImported:=New StringMap<ModuleDecl>	'Ditto for publicly imported modules
	Field friends:=New StringSet
	
	Method ToString$()
		Return "Module "+modpath
	End
	
	Method New( ident$,attrs,munged$,modpath$,filepath$,app:AppDecl )
	
		Self.uid = master_uid
		master_uid += 1
	
		Self.ident=ident
		Self.attrs=attrs
		Self.munged=munged
		Self.modpath=modpath
		Self.rmodpath=modpath
		Self.filepath=filepath
		
		If modpath.Contains( "." )
			Local bits:=modpath.Split( "." ),n:=bits.Length
			If n>1 And bits[n-2]=bits[n-1] Self.rmodpath=StripExt( modpath )
		Endif
		
		imported.Set filepath,Self
		app.InsertModule Self
		
'		Print "Created module: ident="+Self.ident+", modpath="+Self.rmodpath+", filepath="+Self.filepath
	End
	
	Method IsStrict()
		Return (attrs & MODULE_STRICT)<>0
	End
	
	Method GetDeclFromImports:Object(ident:String, map:StringMap<SynonymList>, decl:Object)
	
		Local candidates:SynonymList = map.Get(ident)
		If Not candidates
			ScopeDecl.GetDecl_Fail += 1
			Return decl
		EndIf
		ScopeDecl.GetDecl_Success += 1
		Local n:= candidates.list.FirstNode
		Local pair:DeclMDeclPair
		While n
			pair = n.Value
			Local mdecl:ModuleDecl = pair.mdecl
			Local tdecl:Object = pair.tdecl
			
			'AC: Handle aliases here (it's normally done inside Super.GetDecl but we don't call that.)
			Local adecl:= AliasDecl(tdecl)
			If adecl
				tdecl = Null
				If adecl.CheckAccess() tdecl = adecl.decl
			Endif
			
			'ignore private decls
			Local ddecl:= Decl(tdecl)
			If ddecl And Not ddecl.CheckAccess() tdecl=Null
				
			'ignore funclists with no public funcs
			Local flist:=FuncDeclList( tdecl )
			If flist
				Local pub:=False
				For Local fdecl:=Eachin flist
					If Not fdecl.CheckAccess() Continue
					pub=True
					Exit
				Next
				If Not pub tdecl=Null
			EndIf
			
			If tdecl And tdecl <> decl
				If mdecl=Self Return tdecl
				If decl
					'AC: Easier to let the slow version handle this error:
					GetDecl_Slow(ident)
					'AC: We should definitely not get back from that call. If we do, this optimised process is broken!
					Err "Uh oh! Duplicate identifier '" + ident + "' found via GelDecl but not via GetDecl_Slow!"
				Endif
				decl=tdecl
			Endif		
			n = n.NextNode
		Wend
		
		Return decl
	
	End
		
	Method BuildIndirectDeclMaps()

		indirectDeclMapPublicOnly = New StringMap<SynonymList>
		indirectDeclMapPublicPrivate = New StringMap<SynonymList>
		accessibleModuleScopesPublic = New IntMap<ModuleDecl>
		accessibleModuleScopesPublicPrivate = New IntMap<ModuleDecl>
		
		indirectMapsVersion = master_im_version
		Local todo:= New List<ModuleDecl>
		Local accListPublic:List<ModuleDecl> = New List<ModuleDecl>
		Local accListPublicPrivate:List<ModuleDecl> = New List<ModuleDecl>
		
		'AC: First create the list of accessible modules publicly available via this module scope.
		
		todo.AddLast Self
		accessibleModuleScopesPublic.Set(uid, Self)
		accListPublic.AddLast(Self)
		accListPublicPrivate.AddLast(Self)

		While Not todo.IsEmpty()
	
			Local mdecl:ModuleDecl = todo.RemoveLast()
						
			Local imps:= mdecl.pubImported

			For Local mdecl2:= EachIn imps.Values()
				If Not accessibleModuleScopesPublic.Contains(mdecl2.uid)
					todo.AddLast mdecl2
					accessibleModuleScopesPublic.Set(mdecl2.uid, mdecl2)
					accListPublic.AddLast(mdecl2)
					accListPublicPrivate.AddLast(mdecl2)
				Endif
			Next
		Wend
		
		'AC: Now create an expanded list of modules available privately to this module scope.
		
		Local extraPrivates:Bool = False
		accessibleModuleScopesPublicPrivate.Clone(accessibleModuleScopesPublic)
		For Local mdecl2:= EachIn imported.Values()
			If Not accessibleModuleScopesPublicPrivate.Contains(mdecl2.uid)
				todo.AddLast mdecl2
				accessibleModuleScopesPublicPrivate.Set(mdecl2.uid, mdecl2)
				accListPublicPrivate.AddLast(mdecl2)
				extraPrivates = True
			Endif
		Next
		
		While Not todo.IsEmpty()
	
			Local mdecl:ModuleDecl = todo.RemoveLast()
						
			Local imps:= mdecl.pubImported

			For Local mdecl2:= EachIn imps.Values()
				If Not accessibleModuleScopesPublicPrivate.Contains(mdecl2.uid)
					todo.AddLast mdecl2
					accessibleModuleScopesPublicPrivate.Set(mdecl2.uid, mdecl2)
					accListPublicPrivate.AddLast(mdecl2)
					extraPrivates = True
				Endif
			Next
		Wend
		
		'AC: Now build decl maps from those accessibility lists
		BuildIndirectDeclMap(indirectDeclMapPublicOnly, accListPublic)
		If extraPrivates
			BuildIndirectDeclMap(indirectDeclMapPublicPrivate, accListPublicPrivate)
		Else
			indirectDeclMapPublicPrivate = indirectDeclMapPublicOnly
		EndIf

	End
	
	Method AddIndirectDecl(idm:StringMap<SynonymList>, ident:String, decl:Object, mdecl:ModuleDecl)
		Local syn:SynonymList = idm.Get(ident)
		Local dmdp:DeclMDeclPair
		If syn = Null
			syn = New SynonymList
			idm.Set(ident, syn)
		EndIf
		Local n:= syn.list.FirstNode
		While n
			dmdp = n.Value
			If dmdp.tdecl = decl
				Return
			EndIf
			n = n.NextNode
		Wend
		
		dmdp = New DeclMDeclPair
		dmdp.tdecl = decl
		dmdp.mdecl = mdecl
		syn.list.AddLast(dmdp)
	End
	
	Method BuildIndirectDeclMap(idm:StringMap<SynonymList>, acclist:List<ModuleDecl>)
		Local mn:= acclist.FirstNode
		While mn
			Local declmap:StringMap<Object> = mn.Value.declsMap
			Local dn:= declmap.FirstNode
			While dn
				AddIndirectDecl(idm, dn.Key, dn.Value, mn.Value)
				dn = dn.NextNode
			Wend
			mn = mn.NextNode
		Wend
	End
	
	Method GetDecl:Object(ident:String)
	
		If indirectMapsVersion < master_im_version
			'Print "Building IDMs for " + Self.ident + "..."
			BuildIndirectDeclMaps()
			'Print "Done."
		EndIf
		
		If Not _env
			'AC: 'Slow' version probably quicker in this case as it's a smaller stringmap.
			Return GetDecl_Slow(ident)
		EndIf
		
		Local mdecl:ModuleDecl = _env.ModuleScope()
		
		Local decl:Object
		
		If Self = mdecl
			'AC: Just check the indirect map that includes this module's public AND private imports.
			'Print "Scope match! Checking public/private map."
			decl = GetDeclFromImports(ident, indirectDeclMapPublicPrivate, Null)
			'Print "Done."
		Else
			If accessibleModuleScopesPublic.Contains(mdecl.uid)
				If mdecl.indirectMapsVersion < master_im_version
					mdecl.BuildIndirectDeclMaps()
				EndIf
				'AC: The _env's own module scope is accessible from here.
				'AC: Check the indirect map that only includes this module's public imports,
				'    AND the _env's own module scope's public/private map.
				'Print "Scope mismatch, but env scope accessible! Checking public map and env scope public/private map."
				decl = GetDeclFromImports(ident, mdecl.indirectDeclMapPublicPrivate, GetDeclFromImports(ident, indirectDeclMapPublicOnly, Null))
				'Print "Done."
			Else
				'AC: The _env's own module scope is NOT accessible from here.
				'    Just check our public imports.
				'Print "Scope mismatch, env scope inaccessible! Checking public map."
				decl = GetDeclFromImports(ident, indirectDeclMapPublicOnly, Null)
				'Print "Done."
			EndIf
		EndIf
		
		#rem

		'AC: Uncomment this to validate decls found against the original method, and debug why they're different (if they are!)
		Local decl2:Object = GetDecl_Slow(ident)		
		
		If decl <> decl2
			'AC: Uh oh.
			DebugStop
			'AC: Do it again so we can watch.
			decl2 = GetDecl_Slow(ident)
			DebugStop
			'AC: Build the maps again so we can watch.
			BuildIndirectDeclMaps()
			DebugStop
			'AC: Retrieve the decl again so we can watch.
			If Self = mdecl
				decl = GetDeclFromImports(ident, indirectDeclMapPublicPrivate, Null)
			Else
				If accessibleModuleScopesPublic.Contains(mdecl.uid)
					decl = GetDeclFromImports(ident, mdecl.indirectDeclMapPublicPrivate, GetDeclFromImports(ident, indirectDeclMapPublicOnly, Null))
				Else
					decl = GetDeclFromImports(ident, indirectDeclMapPublicOnly, Null)
				EndIf
			EndIf
		EndIf
		#end
		
		Return decl
	
	End
	
	Method GetDecl_Slow:Object(ident:String)
	
		Local todo:=New List<ModuleDecl>
		Local done:=New StringMap<ModuleDecl>
		
		todo.AddLast Self
		done.Insert filepath,Self
		
		Local decl:Object, declmod:String
		
		While Not todo.IsEmpty()
	
			Local mdecl:ModuleDecl=todo.RemoveLast()
			
			Local tdecl:=mdecl.GetDecl2( ident )
			
			If tdecl And _env
				'ignore private decls
				Local ddecl:=Decl( tdecl )
				If ddecl And Not ddecl.CheckAccess() tdecl=Null
				
				'ignore funclists with no public funcs
				Local flist:=FuncDeclList( tdecl )
				If flist
					Local pub:=False
					For Local fdecl:=Eachin flist
						If Not fdecl.CheckAccess() Continue
						pub=True
						Exit
					Next
					If Not pub tdecl=Null
				Endif
			Endif
			
			If tdecl And tdecl<>decl
				If mdecl=Self Return tdecl
				If decl
					Err "Duplicate identifier '"+ident+"' found in module '"+declmod+"' and module '"+mdecl.ident+"'."
				Endif
				decl=tdecl
				declmod=mdecl.ident
			Endif
			
			If Not _env Exit
			
			Local imps:=mdecl.imported
			If mdecl<>_env.ModuleScope() imps=mdecl.pubImported

			For Local mdecl2:=Eachin imps.Values()
				If Not done.Contains( mdecl2.filepath )
					todo.AddLast mdecl2
					done.Insert mdecl2.filepath,mdecl2
				Endif
			Next

		Wend
		
		Return decl
	End
	
	Method GetDecl2:Object( ident$ )
		Return Super.GetDecl( ident )
	End

	Method ImportModule( modpath$,attrs )
	
		Local cdir:=ExtractDir( Self.filepath )
		
		Local dir:="",filepath:="",mpath:=modpath.Replace( ".","/" )+"."+FILE_EXT			'blah/etc.monkey
		
		For dir=Eachin ENV_MODPATH.Split( ";" )
			If Not dir Continue
			
			'blah.monkey path
			If dir="."
				filepath=cdir+"/"+mpath
			Else
				filepath=RealPath( dir )+"/"+mpath
			Endif
			
			'blah/blah.monkey path			
			Local filepath2:=StripExt( filepath )+"/"+StripDir( filepath )
			
			If FileType( filepath )=FILETYPE_FILE
				If FileType( filepath2 )<>FILETYPE_FILE Exit
				Err "Duplicate module file: '"+filepath+"' and '"+filepath2+"'."
			Endif
			
			filepath=filepath2
			If FileType( filepath )=FILETYPE_FILE
				If modpath.Contains( "." ) 	modpath+="."+ExtractExt( modpath ) Else modpath+="."+modpath
				Exit
			Endif
			
			filepath=""
		Next
		
		If dir="." And Self.modpath.Contains( "." )
			modpath=StripExt( Self.modpath )+"."+modpath
		Endif
		
		Local app:=AppDecl( scope )
	
		Local mdecl:=app.imported.Get( filepath )
		If mdecl And mdecl.modpath<>modpath
			Print "Modpath error - import="+modpath+", existing="+mdecl.modpath
		Endif
		
		If Self.imported.Contains( filepath ) Return
		
		If Not mdecl mdecl=ParseModule( modpath,filepath,app )
		
		Self.imported.Insert mdecl.filepath,mdecl
		
		If Not (attrs & DECL_PRIVATE) Self.pubImported.Insert mdecl.filepath,mdecl
		
		Self.InsertDecl New AliasDecl( mdecl.ident,attrs,mdecl )
	End

	Method OnSemant()
	End

	Method SemantAll()	
		For Local decl:=Eachin Decls()
			If AliasDecl( decl ) Continue

			Local cdecl:=ClassDecl( decl )
			
			If cdecl
				If cdecl.args
					For Local inst:=Eachin cdecl.instances
						For Local decl:=Eachin inst.Decls()
							If AliasDecl( decl ) Continue
							decl.Semant
						Next
					Next
				Else
					decl.Semant
					For Local decl:=Eachin cdecl.Decls()
						If AliasDecl( decl ) Continue
						decl.Semant
					Next
				Endif
			Else
				decl.Semant
			Endif
		Next
		attrs|=MODULE_SEMANTALL
	End
	
	Method InsertDecl(decl:Decl)
		Super.InsertDecl(decl)
		master_im_version += 1
	End

	Method InsertDecls(decls:List<Decl>)
		Super.InsertDecls(decls)
		master_im_version += 1
	End
End

Class AppDecl Extends ScopeDecl

	Field imported:=New StringMap<ModuleDecl>			'maps modpath->mdecl
	
	Field mainModule:ModuleDecl
	Field mainFunc:FuncDecl	
		
	Field semantedClasses:=New List<ClassDecl>			'in-order (ie: base before derived) list of semanted classes
	Field semantedGlobals:=New List<GlobalDecl>			'in-order (ie: dependancy sorted) list of semanted globals
	Field allSemantedDecls:=New List<Decl>				'top-level decls including externs
	
	Field fileImports:=New StringList
	
	Method InsertModule( mdecl:ModuleDecl )
		mdecl.scope=Self
		imported.Insert mdecl.filepath,mdecl
		If Not mainModule mainModule=mdecl
	End
	
	Method OnSemant()
	
		_env=Null
		
		mainFunc=mainModule.FindFuncDecl( "Main",[] )
		
		If Not mainFunc Err "Function 'Main' not found."
		
		If Not IntType( mainFunc.retType ) Or mainFunc.argDecls.Length
			Err "Main function must be of type Main:Int()"
		Endif
		
		FinalizeClasses
	End
	
	Method FinalizeClasses()

		_env=Null
		
		Repeat
			Local more
			For Local cdecl:=Eachin semantedClasses
				more+=cdecl.UpdateLiveMethods()
			Next
			If Not more Exit
		Forever
		
		For Local cdecl:=Eachin semantedClasses
			cdecl.FinalizeClass
		Next
	End
	
End
