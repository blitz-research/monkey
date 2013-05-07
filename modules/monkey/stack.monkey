
' Module monkey.Stack
'
' Placed into the public domain 24/02/2011.
' No warranty implied; use at your own risk.

Class Stack<T>

	Method New()
	End
	
	Method New( data:T[] )
		Self.data=data[..]
		Self.length=data.Length
	End
	
	Method ToArray:T[]()
		Local t:T[length]
		For Local i:=0 Until length
			t[i]=data[i]
		Next
		Return t
	End

	Method Equals:Bool( lhs:T,rhs:T )
		Return lhs=rhs
	End
	
	Method Compare:Int( lhs:T,rhs:T )
		Error "Unable to compare items"
	End
	
	Method Clear:Void()
		For Local i:=0 Until length
			data[i]=NIL
		Next
		length=0
	End
	
	Method Length:Void( newlength:Int ) Property
		If newlength<length
			For Local i:=newlength Until length
				data[i]=NIL
			Next
		Else If newlength>data.Length
			data=data.Resize( Max( length*2+10,newlength ) )
		Endif
		length=newlength
	End

	Method Length:Int() Property
		Return length
	End

	Method IsEmpty:Bool() Property
		Return length=0
	End
	
	Method Contains:Bool( value:T )
		For Local i:=0 Until length
			If Equals( data[i],value ) Return True
		Next
		Return False
	End Method
	
	Method Push:Void( value:T )
		If length=data.Length
			data=data.Resize( length*2+10 )
		Endif
		data[length]=value
		length+=1
	End
	
	Method Push:Void( values:T[],offset:Int=0 )
		Push values,offset,values.Length-offset
	End

	Method Push:Void( values:T[],offset:Int,count:Int )
		For Local i:=0 Until count
			Push values[offset+i]
		Next
	End

	Method Pop:T()
		length-=1
		Local v:=data[length]
		data[length]=NIL
		Return v
	End
	
	Method Top:T()
		Return data[length-1]
	End

	Method Set:Void( index,value:T )
		data[index]=value
	End

	Method Get:T( index )
		Return data[index]
	End
	
	Method Find:Int( value:T,start:Int=0 )
		For Local i:=start Until length
			If Equals( data[i],value ) Return i
		Next
		Return -1
	End
	
	Method FindLast:Int( value:T )
		Return FindLast( value,length-1 )
	End
	
	Method FindLast:Int( value:T,start:Int )
		For Local i:=start To 0 Step -1
			If Equals( data[i],value ) Return i
		Next
		Return -1
	End
	
	Method Insert:Void( index,value:T )
		If length=data.Length
			data=data.Resize( length*2+10 )
		Endif
		For Local i:=length Until index Step -1
			data[i]=data[i-1]
		Next
		data[index]=value
		length+=1
	End

	Method Remove:Void( index:Int )
		For Local i:=index Until length-1
			data[i]=data[i+1]
		Next
		length-=1
		data[length]=NIL
	End
	
	Method RemoveFirst:Void( value:T )
		Local i:=Find( value )
		If i<>-1 Remove i
	End
	
	Method RemoveLast:Void( value:T )
		Local i:=FindLast( value )
		If i<>-1 Remove i
	End
	
	Method RemoveEach:Void( value:T )
		Local i:=0,j:=length
		While i<length
			If Not Equals( data[i],value )
				i+=1
				Continue
			Endif
			Local b:=i,e:=i+1
			While e<length And Equals( data[e],value )
				e+=1
			Wend
			While e<length
				data[b]=data[e]
				b+=1
				e+=1
			Wend
			length-=e-b
			i+=1
		Wend
		i=length
		While i<j
			data[i]=NIL
			i+=1
		Wend
	End
	
	Method Sort:Void( ascending:Bool=True )
		If Not length Return
		Local t:=1
		If Not ascending t=-1
		_Sort 0,length-1,t
	End
	
	Method ObjectEnumerator:Enumerator<T>()
		Return New Enumerator<T>( Self )
	End
	
	Method Backwards:BackwardsStack<T>()
		Return New BackwardsStack<T>( Self )
	End
	
Private

	Global NIL:T

	Field data:T[]
	Field length:Int
	
	Method _Swap:Void( x:Int,y:Int ) Final
		Local t:=data[x]
		data[x]=data[y]
		data[y]=t
	End
	
	Method _Less:Bool( x:Int,y:Int,ascending:Int ) Final
		Return Compare( data[x],data[y] )*ascending<0
	End
	
	Method _Less2:Bool( x:Int,y:T,ascending:Int ) Final
		Return Compare( data[x],y )*ascending<0
	End
	
	Method _Less3:Bool( x:T,y:Int,ascending:Int ) Final
		Return Compare( x,data[y] )*ascending<0
	End
	
	Method _Sort:Void( lo:Int,hi:Int,ascending:Int ) Final
		If hi<=lo Return
		If lo+1=hi
			If _Less( hi,lo,ascending ) _Swap( hi,lo )
			Return
		Endif
		Local i:=(hi-lo)/2+lo
		If _Less( i,lo,ascending ) _Swap( i,lo )
		If _Less( hi,i,ascending )
			_Swap( hi,i )
			If _Less( i,lo,ascending ) _Swap( i,lo )
		Endif
		Local x:=lo+1
		Local y:=hi-1
		Repeat
			Local p:=data[i]
			While _Less2( x,p,ascending )
				x+=1
			Wend
			While _Less3( p,y,ascending )
				y-=1
			Wend
			If x>y Exit
			If x<y
				_Swap( x,y )
				If i=x i=y Else If i=y i=x
			Endif
			x+=1
			y-=1
		Until x>y
		_Sort( lo,y,ascending )
		_Sort( x,hi,ascending )
	End
	
End

Class Enumerator<T>

	Method New( stack:Stack<T> )
		Self.stack=stack
	End

	Method HasNext:Bool()
		Return index<stack.Length
	End

	Method NextObject:T()
		index+=1
		Return stack.data[index-1]
	End

Private

	Field stack:Stack<T>
	Field index:Int

End

Class BackwardsStack<T>

	Method New( stack:Stack<T> )
		Self.stack=stack
	End

	Method ObjectEnumerator:BackwardsEnumerator<T>()
		Return New BackwardsEnumerator<T>( stack )
	End Method
	
Private

	Field stack:Stack<T>

End

Class BackwardsEnumerator<T>

	Method New( stack:Stack<T> )
		Self.stack=stack
		index=stack.length
	End Method

	Method HasNext:Bool()
		Return index>0
	End 

	Method NextObject:T()
		index-=1
		Return stack.data[index]
	End

Private
	
	Field stack:Stack<T>
	Field index:Int

End

'Helper versions

Class IntStack Extends Stack<Int>

	Method New( data:Int[] )
		Super.New( data )
	End
	
	Method Equals:Bool( lhs:Int,rhs:Int )
		Return lhs=rhs
	End
	
	Method Compare:Int( lhs:Int,rhs:Int )
		Return lhs-rhs
	End

End

Class FloatStack Extends Stack<Float>
	
	Method New( data:Float[] )
		Super.New( data )
	End
	
	Method Equals:Bool( lhs:Float,rhs:Float )
		Return lhs=rhs
	End
	
	Method Compare:Int( lhs:Float,rhs:Float )
		If lhs<rhs Return -1
		Return lhs>rhs
	End
	
End

Class StringStack Extends Stack<String>

	Method New( data:String[] )
		Super.New( data )
	End
	
	Method Join:String( separator:String="" )
		Return separator.Join( ToArray() )
	End
	
	Method Equals:Bool( lhs:String,rhs:String )
		Return lhs=rhs
	End

	Method Compare:Int( lhs:String,rhs:String )
		Return lhs.Compare( rhs )
	End

End
