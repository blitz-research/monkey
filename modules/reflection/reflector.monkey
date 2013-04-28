
Import trans

Const ARRAY_PREFIX:="monkey.boxes.ArrayObject<"

Class Reflector

	Field debug?
	
	Field refmod:ModuleDecl
	Field langmod:ModuleDecl
	Field boxesmod:ModuleDecl
	
	Field output:=New StringStack
	Field munged:=New StringMap<Int>
	
	Field refmods:=New StringSet			'mods to reflect
	Field modpaths:=New StringMap<String>
	Field modexprs:=New StringMap<String>
	
	Field classids:=New StringMap<Int>		'Maps DeclExpr->classes[] index
	Field classdecls:=New Stack<ClassDecl>
	
	'value->Object
	Method Box$( ty:Type,expr$ )
		If VoidType( ty ) Return expr
		If BoolType( ty ) Return "New BoolObject("+expr+")"
		If IntType( ty ) Return "New IntObject("+expr+")"
		If FloatType( ty ) Return "New FloatObject("+expr+")"
		If StringType( ty ) Return "New StringObject("+expr+")"
		If ArrayType( ty )	Return "New ArrayObject<"+TypeExpr( ArrayType(ty).elemType )+">("+expr+")"
		If ObjectType( ty ) Return expr
		InternalErr
	End
	
	'Object->value
	Method Unbox$( ty:Type,expr$ )
		If BoolType( ty ) Return "BoolObject("+expr+").value"
		If IntType( ty ) Return "IntObject("+expr+").value"
		If FloatType( ty ) Return "FloatObject("+expr+").value"
		If StringType( ty ) Return "StringObject("+expr+").value"
		If ArrayType( ty ) Return "ArrayObject<"+TypeExpr( ArrayType(ty).elemType )+">("+expr+").value"
		If ObjectType( ty )	Return DeclExpr( ty.GetClass() )+"("+expr+")"
		InternalErr
	End
	
	Method Mung$( ident$ )
	
		If debug 
			ident="R"+ident
			ident=ident.Replace( "_","_0" )
			ident=ident.Replace( "[","_1" )
			ident=ident.Replace( "]","_2" )
			ident=ident.Replace( "<","_3" )
			ident=ident.Replace( ">","_4" )
			ident=ident.Replace( ",","_5" )
			ident=ident.Replace( ".","_" )
		Else
			ident="R"
		Endif
		
		If munged.Contains( ident )
			Local n=munged.Get( ident )
			n+=1
			munged.Set ident,n
			ident+=String(n)
		Else
			munged.Set ident,1
		Endif
		Return ident
	End
	
	'Return full module path, eg: monkey.lang or mojo.graphics
	'
	Method ModPath$( mdecl:ModuleDecl )
	
		Local p:=mdecl.filepath.Replace( "\","/" )
		If Not p.EndsWith( ".monkey" ) InternalErr
		p=p[..-7]		
		
		For Local dir:=Eachin GetCfgVar( "MODPATH" ).Split( ";" )
			If Not dir or dir="." Continue
			
			dir=dir.Replace( "\","/" )
			If Not dir.EndsWith("/") dir+="/"
			If Not p.StartsWith( dir ) Continue
			
			p=p[dir.Length-1..]
			
			Local i=p.FindLast( "/" )
			If i<>-1
				Local e:=p[i..]
				If p.EndsWith( e+e )	'eg: ends with /mojo/mojo
					p=p[..i]
				Endif
			Endif
			
			p=p[1..].Replace( "/","." )

			Return p
		Next
		Print "MODPATH="+GetCfgVar( "MODPATH" )
		Error "Invalid module path for module:"+mdecl.filepath
	End
	
	Function MatchPath?( text$,pattern$ )
	
		Local alts:=pattern.Split( "|" )

		For Local alt:=Eachin alts
			If Not alt Continue
			
			Local bits:=alt.Split( "*" )
			If bits.Length=1
				If bits[0]=text Return True
				Continue
			Endif
			
			If Not text.StartsWith( bits[0] ) Continue
	
			Local i:=bits[0].Length
			For Local j=1 Until bits.Length-1
				Local bit:=bits[j]
				i=text.Find( bit,i )
				If i=-1 Exit
				i+=bit.Length
			Next
	
			If i<>-1 And text[i..].EndsWith( bits[bits.Length-1] ) Return True
		Next
		Return False
	End
	
	Method TypeInfo$( ty:Type )
		If VoidType( ty ) Return "Null"
		If BoolType( ty ) Return "_boolClass"
		If IntType( ty ) Return "_intClass"
		If FloatType( ty ) Return "_floatClass"
		If StringType( ty ) Return "_stringClass"
		If ArrayType( ty )
			Local elemType:=ArrayType(ty).elemType
			Local name:="monkey.boxes.ArrayObject<"+TypeExpr( elemType,True )+">"
			If classids.Contains( name ) Return "_classes["+classids.Get( name )+"]"
			If debug Print "Instantiating class: "+name
			Local cdecl:=boxesmod.FindType( "ArrayObject",[elemType] ).GetClass()
			For Local decl:=Eachin cdecl.Decls()
				If Not AliasDecl( decl ) decl.Semant
			Next
			Local id:=classdecls.Length
			classids.Set name,id
			classdecls.Push cdecl
			Return "_classes["+id+"]"
		Endif
		If ObjectType( ty )
			Local name:=DeclExpr( ty.GetClass(),True )
			If classids.Contains( name ) Return "_classes["+classids.Get( name )+"]"
			Return "_unknownClass"
		Endif
		InternalErr
	End
	
	Method TypeExpr$( ty:Type,path?=False )
		If VoidType( ty ) Return "Void"
		If BoolType( ty ) Return "Bool"
		If IntType( ty ) Return "Int"
		If FloatType( ty ) Return "Float"
		If StringType( ty ) Return "String"
		If ArrayType( ty ) Return TypeExpr( ArrayType(ty).elemType,path )+"[]"
		If ObjectType( ty ) Return DeclExpr( ty.GetClass(),path )
		InternalErr
	End
	
	Method DeclExpr$( decl:Decl,path?=False )
	
		If path And ClassDecl( decl.scope ) Return decl.ident
			
		Local mdecl:=ModuleDecl( decl )
		If mdecl
			If path Return modpaths.Get( mdecl.filepath )
			Return modexprs.Get( mdecl.filepath )
		Endif
		
		Local cdecl:=ClassDecl( decl )
		If cdecl And cdecl.munged="Object"
			If path Return "monkey.lang.Object"
			Return "Object"
		Endif
		If cdecl And cdecl.munged="ThrowableObject"
			If path Return "monkey.lang.Throwable"
			Return "Throwable"
		Endif
	
		Local ident:=DeclExpr( decl.scope,path )+"."+decl.ident
		
		If cdecl And cdecl.instArgs
			Local t:=""
			For Local arg:=Eachin cdecl.instArgs
				If t t+=","
				t+=TypeExpr( arg,path )
			Next
			ident+="<"+t+">"
		Endif
		
		Return ident
	End
	
	Method ValidType?( ty:Type )
		If ArrayType( ty ) Return ValidType( ArrayType( ty ).elemType )
		If ObjectType( ty ) Return ValidClass( ty.GetClass() )
		Return True
	End
	
	Method ValidClass?( cdecl:ClassDecl )
		If cdecl.munged="Object" Return True
		If cdecl.munged="ThrowableObject" Return True
		If Not cdecl.ExtendsObject() Return False
		If Not refmods.Contains( cdecl.ModuleScope().filepath ) Return False
		For Local arg:=Eachin cdecl.instArgs
			If ObjectType( arg ) And Not ValidClass( arg.GetClass() ) Return False
		Next
		If cdecl.superClass Return ValidClass( cdecl.superClass )
		Return True
	End
	
	Method Emit( t$ )
		output.Push t
	End
	
	Method Attrs( decl:Decl )
		Return (decl.attrs Shr 8) & 255
	End
	
	Method Emit$( tdecl:ConstDecl )
		If Not ValidType( tdecl.type ) Return
		
		Local name:=DeclExpr( tdecl,True )
		Local expr:=DeclExpr( tdecl )
		Local type:=TypeInfo( tdecl.type )

		Return "New ConstInfo(~q"+name+"~q,"+Attrs(tdecl)+","+type+","+Box( tdecl.type,expr )+")"
	End
	
	Method Emit$( gdecl:GlobalDecl )
		If Not ValidType( gdecl.type ) Return
		
		Local name:=DeclExpr( gdecl,True )
		Local expr:=DeclExpr( gdecl )
		Local ident:=Mung( name )
		Local type:=TypeInfo( gdecl.type )
		
		Emit "Class "+ident+" Extends GlobalInfo"
		Emit " Method New()"
		Emit "  Super.New(~q"+name+"~q,"+Attrs(gdecl)+","+type+")"
		Emit " End"
		Emit " Method GetValue:Object()"
		Emit "  Return "+Box( gdecl.type,expr )
		Emit " End"
		Emit " Method SetValue:Void(v:Object)"
		Emit "  "+expr+"="+Unbox( gdecl.type,"v" )
		Emit " End"
		Emit "End"
		
		Return ident
	End
	
	Method Emit$( tdecl:FieldDecl )
		If Not ValidType( tdecl.type ) Return
	
		Local name:=tdecl.ident
		Local ident:=Mung( name )
		Local type:=TypeInfo( tdecl.type )
		Local clas:=DeclExpr( tdecl.ClassScope() )
		Local expr:=clas+"(i)."+tdecl.ident
		
		Emit "Class "+ident+" Extends FieldInfo"
		Emit " Method New()"
		Emit "  Super.New(~q"+name+"~q,"+Attrs(tdecl)+","+type+")"
		Emit " End"
		Emit " Method GetValue:Object(i:Object)"
		Emit "  Return "+Box( tdecl.type,expr )
		Emit " End"
		Emit " Method SetValue:Void(i:Object,v:Object)"
		Emit "  "+expr+"="+Unbox( tdecl.type,"v" )
		Emit " End"
		Emit "End"
		
		Return ident
	End
	
	Method Emit$( fdecl:FuncDecl )
		If Not ValidType( fdecl.retType ) Return
		If fdecl.ident = "DebugStop" Or fdecl.ident = "DebugLog" Return
		For Local arg:=Eachin fdecl.argDecls
			If Not ValidType( arg.type ) Return
		Next
		
		Local name:=DeclExpr( fdecl,True )
		Local expr:=DeclExpr( fdecl )
		Local ident:=Mung( name )
		Local rtype:=TypeInfo( fdecl.retType )

		Local base:="FunctionInfo"
		If fdecl.IsMethod()
			Local clas:=DeclExpr( fdecl.ClassScope() )
			expr=clas+"(i)."+fdecl.ident
			base="MethodInfo"
		Endif

		Local argtys:=New String[fdecl.argDecls.Length]
		For Local i=0 Until argtys.Length
			argtys[i]=TypeInfo( fdecl.argDecls[i].type )
		Next
		
		Emit "Class "+ident+" Extends "+base
		Emit " Method New()"
		Emit "  Super.New(~q"+name+"~q,"+Attrs(fdecl)+","+rtype+",["+",".Join( argtys )+"])"
		Emit " End"
		
		If fdecl.IsMethod()
			Emit " Method Invoke:Object(i:Object,p:Object[])"
		Else
			Emit " Method Invoke:Object(p:Object[])"
		Endif
		Local args:=New StringStack
		For Local i:=0 Until fdecl.argDecls.Length
			Local arg:=fdecl.argDecls[i]
			args.Push Unbox( arg.type,"p["+i+"]" )
		Next
		If fdecl.IsCtor()
			Local cdecl:=fdecl.ClassScope()
			If cdecl.IsAbstract()
				Emit "  Return Null"
			Else
				Emit "  Return New "+DeclExpr( cdecl )+"("+args.Join(",")+")"
			Endif
		Else If VoidType( fdecl.retType )
			Emit "  "+expr+"("+args.Join(",")+")"
		Else
			Emit "  Return "+Box( fdecl.retType,expr+"("+args.Join(",")+")" )
		Endif
		Emit " End"

		Emit "End"
		
		Return ident
	End
	
	Method Emit$( cdecl:ClassDecl )
		If cdecl.args InternalErr
		
		Local name:=DeclExpr( cdecl,True )
		Local expr:=DeclExpr( cdecl )
		Local ident:=Mung( name )
		
		Local sclass:="Null"
		If cdecl.superClass sclass=TypeInfo( cdecl.superClass.objectType )
		
		Local ifaces$
		For Local idecl:=Eachin cdecl.implments
			If ifaces ifaces+=","
			ifaces+=TypeInfo( idecl.objectType )
		Next

		Local consts:=New StringStack
		Local globals:=New StringStack		
		Local fields:=New StringStack
		Local methods:=New StringStack
		Local functions:=New StringStack
		Local ctors:=New StringStack
		
		For Local decl:=Eachin cdecl.Decls	'emit in declaration order...
			If AliasDecl( decl )
'				Local ty:=Type( AliasDecl( decl ).decl )
'				If ty
'					'Maps generic param to concrete type, eg: T->Actor
'					Print "Class:"+name+", alias:"+decl.ident+"->"+ty.ToString()
'				Endif
				Continue
			Endif
			
			If Not decl.IsSemanted() Continue

			Local pdecl:=ConstDecl( decl )
			If pdecl
				Local p:=Emit( pdecl )
				If p consts.Push p
				Continue
			End
			
			Local gdecl:=GlobalDecl( decl )
			If gdecl
				Local g:=Emit( gdecl )
				If g globals.Push g
				Continue
			Endif
			
			Local tdecl:=FieldDecl( decl )
			If tdecl
				Local f:=Emit( tdecl )
				If f fields.Push f
				Continue
			Endif
			
			Local fdecl:=FuncDecl( decl )
			If fdecl
				Local f:=Emit( fdecl )
				If f
					If fdecl.IsCtor()
						ctors.Push f
					Else If fdecl.IsMethod()
						methods.Push f
					Else
						functions.Push f
					Endif
				Endif
				Continue
			Endif
		Next
		
		Emit "Class "+ident+" Extends ClassInfo"
		Emit " Method New()"
		Emit "  Super.New(~q"+name+"~q,"+Attrs(cdecl)+","+sclass+",["+ifaces+"])"
		Select name
		Case "monkey.boxes.BoolObject"
			Emit "  _boolClass=Self"
		Case "monkey.boxes.IntObject"
			Emit "  _intClass=Self"
		Case "monkey.boxes.FloatObject"
			Emit "  _floatClass=Self"
		Case "monkey.boxes.StringObject"
			Emit "  _stringClass=Self"
		End
		Emit " End"
		
		If name.StartsWith( ARRAY_PREFIX )
			Local elemType:=cdecl.instArgs[0]
			Local elemExpr:=TypeExpr( elemType )
			Local i=elemExpr.Find( "[]" )
			If i=-1 i=elemExpr.Length
			Local ARRAY_PREFIX:=modexprs.Get( boxesmod.filepath )+".ArrayObject<"
			Emit " Method ElementType:ClassInfo() Property"
			Emit "  Return "+TypeInfo( elemType )
			Emit " End"
			Emit " Method ArrayLength:Int(i:Object) Property"
			Emit "  Return "+ARRAY_PREFIX+elemExpr+">(i).value.Length"
			Emit " End"
			Emit " Method GetElement:Object(i:Object,e)"
			Emit "  Return "+Box( elemType,ARRAY_PREFIX+elemExpr+">(i).value[e]" )
			Emit " End"
			Emit " Method SetElement:Void(i:Object,e,v:Object)"
			Emit "  "+ARRAY_PREFIX+elemExpr+">(i).value[e]="+Unbox( elemType,"v" )
			Emit " End"
			Emit " Method NewArray:Object(l:Int)"
'			Emit "  Return "+Box( elemType.ArrayOf(),"New "+elemExpr+"[l]" )
			Emit "  Return "+Box( elemType.ArrayOf(),"New "+elemExpr[..i]+"[l]"+elemExpr[i..] )
			Emit " End"
		Endif

		If Not cdecl.IsAbstract() And Not cdecl.IsExtern()
			Emit " Method NewInstance:Object()"
			Emit "  Return New "+expr
			Emit " End"
		Endif

		Emit " Method Init()"
		If consts.Length
			Emit "  _consts=new ConstInfo["+consts.Length+"]"
			For Local i=0 Until consts.Length
				Emit "  _consts["+i+"]="+consts.Get(i)
			Next
		Endif
		If globals.Length
			Emit "  _globals=new GlobalInfo["+globals.Length+"]"
			For Local i=0 Until globals.Length
				Emit "  _globals["+i+"]=New "+globals.Get(i)
			Next
		Endif
		If fields.Length
			Emit "  _fields=New FieldInfo["+fields.Length+"]"
			For Local i=0 Until fields.Length
				Emit "  _fields["+i+"]=New "+fields.Get(i)
			Next
		Endif
		If methods.Length
			Emit "  _methods=New MethodInfo["+methods.Length+"]"
			For Local i=0 Until methods.Length
				Emit "  _methods["+i+"]=New "+methods.Get(i)
			Next
		Endif
		If functions.Length
			Emit "  _functions=New FunctionInfo["+functions.Length+"]"
			For Local i=0 Until functions.Length
				Emit "  _functions["+i+"]=New "+functions.Get(i)
			Next
		Endif
		If ctors.Length
			Emit "  _ctors=New FunctionInfo["+ctors.Length+"]"
			For Local i=0 Until ctors.Length
				Emit "  _ctors["+i+"]=New "+ctors.Get(i)
			Next
		Endif
		Emit " InitR()"
		Emit " End"
		Emit "End"
		
		Return ident
	End

	Method Semant( app:AppDecl )

		Local filter:=GetCfgVar( "REFLECTION_FILTER" )
		If Not filter Return
		filter=filter.Replace( ";","|" )
		
		debug=GetCfgVar( "DEBUG_REFLECTION" )="1"
		
		For Local mdecl:=Eachin app.imported.Values()
			Local path:=ModPath( mdecl )
			If path="reflection"
				refmod=mdecl
			Else If path="monkey.lang"
				langmod=mdecl
			Else If path="monkey.boxes"
				boxesmod=mdecl
			Endif
		Next
		If Not refmod Error "reflection module not found!"
		
		If debug Print "Semanting all"

		For Local mdecl:=Eachin app.imported.Values()
			Local path:=ModPath( mdecl )
			
			If mdecl<>boxesmod And mdecl<>langmod And Not MatchPath( path,filter ) Continue
'			If mdecl<>boxesmod And Not MatchPath( path,filter ) Continue
			
			Local expr:=Mung( path )
			refmod.InsertDecl New AliasDecl( expr,0,mdecl )
			modpaths.Set mdecl.filepath,path
			modexprs.Set mdecl.filepath,expr
			
			refmods.Insert mdecl.filepath
			mdecl.SemantAll
		Next
		
		Repeat
			Local n:=app.allSemantedDecls.Count()
			For Local mdecl:=Eachin app.imported.Values()
				If Not refmods.Contains( mdecl.filepath ) Continue
				mdecl.SemantAll
			Next
			n=app.allSemantedDecls.Count()-n
			If Not n Exit
			If debug Print "Semanting more: "+n
		Forever

		'Enum classes in 'super first' order...
		For Local decl:=Eachin app.allSemantedDecls
'			If decl.IsPrivate() Continue
			
			If Not refmods.Contains( decl.ModuleScope().filepath ) Continue
			
			Local cdecl:=ClassDecl( decl )
			If cdecl And ValidClass( cdecl )
				classids.Set DeclExpr( cdecl,True ),classdecls.Length
				classdecls.Push cdecl
				Continue
			Endif
		Next
		
		Local classes:=New StringStack
		Local consts:=New StringStack
		Local globals:=New StringStack
		Local functions:=New StringStack
		
		If debug Print "Generating reflection info"
		
		For Local decl:=Eachin app.allSemantedDecls
'			If decl.IsPrivate() Continue
			
			If Not refmods.Contains( decl.ModuleScope().filepath ) Continue
			
			Local pdecl:=ConstDecl( decl )
			If pdecl
				Local p:=Emit( pdecl )
				If p consts.Push p
				Continue
			End
			
			Local gdecl:=GlobalDecl( decl )
			If gdecl
				Local g:=Emit( gdecl )
				If g globals.Push g
				Continue
			Endif
			
			Local fdecl:=FuncDecl( decl )
			If fdecl
				Local f:=Emit( fdecl )
				If f functions.Push f
				Continue
			Endif
		Next
		
		If debug Print "Finalizing classes"
		
		'Need to do this to update ABSTRACT attribute...
		app.FinalizeClasses
		
		If debug Print "Generating class reflection info"
		
		For Local i:=0 Until classdecls.Length
			classes.Push Emit( classdecls.Get(i) )
		Next
		
		Emit "Global _init:=__init()"
		Emit "Function __init()"
		If classes.Length
			Emit " _classes=New ClassInfo["+classes.Length+"]"
			For Local i:=0 Until classes.Length
				Emit " _classes["+i+"]=New "+classes.Get(i)
			Next
			For Local i:=0 Until classes.Length
				Emit " _classes["+i+"].Init()"
			Next
		Endif
		If consts.Length
			Emit " _consts=new ConstInfo["+consts.Length+"]"
			For Local i=0 Until consts.Length
				Emit " _consts["+i+"]="+consts.Get(i)
			Next
		Endif
		If globals.Length
			Emit " _globals=New GlobalInfo["+globals.Length+"]"
			For Local i:=0 Until globals.Length
				Emit " _globals["+i+"]=New "+globals.Get(i)
			Next
		Endif
		If functions.Length
			Emit " _functions=New FunctionInfo["+functions.Length+"]"
			For Local i:=0 Until functions.Length
				Emit " _functions["+i+"]=New "+functions.Get(i)
			Next
		Endif
		Emit " _getClass=New __GetClass"
		Emit "End"

		Emit "Class __GetClass Extends _GetClass"
		Emit " Method GetClass:ClassInfo(o:Object)"
		For Local i=classes.Length-1 To 0 Step -1
			Local expr:=DeclExpr( classdecls.Get(i) )
			Emit "  If "+expr+"(o)<>Null Return _classes["+i+"]"
		Next
		Emit "  Return _unknownClass"
		Emit " End"
		Emit "End"
		
		Local source:=output.Join( "~n" )
		
		Local attrs:=DECL_REFLECTOR
		
		If debug
			Print "Reflection source:~n"+source
		Else
			attrs|=DECL_NODEBUG
		Endif
		
		ParseSource source,app,refmod,attrs
		
		refmod.FindValDecl "_init"
		
		app.Semant
		
	End

End
