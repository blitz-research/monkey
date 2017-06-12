
' Module monkey.list
'
' Placed into the public domain 24/02/2011.
' No warranty implied; use at your own risk.

Class List<T>

	Method New()
	End
	
	Method New( data:T[] )
		For Local t:=Eachin data
			AddLast t
		Next
	End
	
	Method ToArray:T[]()
		Local arr:T[Count()],i
		For Local t:=Eachin Self
			arr[i]=t
			i+=1
		Next
		Return arr
	End

	Method Equals?( lhs:T,rhs:T )
		Return lhs=rhs
	End
	
	Method Compare( lhs:T,rhs:T )	'This method should be implemented by subclasses for Sort to work
		Error "Unable to compare items"
	End
	
	Method Clear()
		_head._succ=_head
		_head._pred=_head
	End

	Method Count()
		Local n,node:=_head._succ
		While node<>_head
			node=node._succ
			n+=1
		Wend
		Return n
	End
	
	Method IsEmpty?()
		Return _head._succ=_head
	End
	
	Method Contains?( value:T )
		Local node:=_head._succ
		While node<>_head
			If Equals( node._data,value ) Return True
			node=node._succ
		Wend		
	End Method
	
	Method FirstNode:Node<T>()
		If _head._succ<>_head Return _head._succ
		Return Null
	End
	
	Method LastNode:Node<T>()
		If _head._pred<>_head Return _head._pred
		Return Null
	End
	
	Method First:T()
#If CONFIG="debug"
		If IsEmpty() Error "Illegal operation on empty list"
#Endif
		Return _head._succ._data
	End

	Method Last:T()
#If CONFIG="debug"
		If IsEmpty() Error "Illegal operation on empty list"
#Endif
		Return _head._pred._data
	End
	
	Method RemoveFirst:T()
#If CONFIG="debug"
		If IsEmpty() Error "Illegal operation on empty list"
#Endif
		Local data:=_head._succ._data
		_head._succ.Remove
		Return data
	End

	Method RemoveLast:T()
#If CONFIG="debug"
		If IsEmpty() Error "Illegal operation on empty list"
#Endif
		Local data:=_head._pred._data
		_head._pred.Remove
		Return data
	End
	
	Method AddFirst:Node<T>( data:T )
		Return New Node<T>( _head._succ,_head,data )
	End

	Method AddLast:Node<T>( data:T )
		Return New Node<T>( _head,_head._pred,data )
	End
	
	Method Find:Node<T>( value:T )
		Return Find( value,_head._succ )
	End
	
	Method Find:Node<T>( value:T,start:Node<T> )
		While start<>_head
			If Equals( value,start._data ) Return start
			start=start._succ
		Wend
		Return Null
	End
	
	Method FindLast:Node<T>( value:T )
		Return FindLast( value,_head._pred )
	End
	
	Method FindLast:Node<T>( value:T,start:Node<T> )
		While start<>_head
			If Equals( value,start._data ) Return start
			start=start._pred
		Wend
		Return Null
	End
	
	'***** DEPRECATED *****
	Method Remove:Void( value:T )
		RemoveEach value
	End
	
	Method RemoveFirst:Void( value:T )
		Local node:=Find( value )
		If node node.Remove
	End
	
	Method RemoveLast:Void( value:T )
		Local node:=FindLast( value )
		If node node.Remove
	End
	
	Method RemoveEach( value:T )
		Local node:=_head._succ
		While node<>_head
			Local succ:=node._succ
			If Equals( node._data,value ) node.Remove
			node=succ
		Wend
	End
	
	Method InsertBefore:Node<T>( where:T,data:T )
		Local node:=Find( where )
		If node Return New Node<T>( node,node._pred,data )
	End
	
	Method InsertAfter:Node<T>( where:T,data:T )
		Local node:=Find( where )
		If node Return New Node<T>( node._succ,node,data )
	End
	
	Method InsertBeforeEach:Void( where:T,data:T )
		Local node:=Find( where )
		While node
			New Node<T>( node,node._pred,data )
			node=Find( where,node._succ )
		Wend
	End

	Method InsertAfterEach:Void( where:T,data:T )
		Local node:=Find( where )
		While node
			node=New Node<T>( node._succ,node,data )
			node=Find( where,node._succ )
		Wend
	End
	
	Method ObjectEnumerator:Enumerator<T>()
		Return New Enumerator<T>( Self )
	End
	
	Method Backwards:BackwardsList<T>()
		Return New BackwardsList<T>( Self )
	End
	
	Method Sort( ascending=True )
		Local ccsgn=-1
		If ascending ccsgn=1
		Local insize=1
		
		Repeat
			Local merges
			Local tail:=_head
			Local p:=_head._succ

			While p<>_head
				merges+=1
				Local q:=p._succ,qsize=insize,psize=1
				
				While psize<insize And q<>_head
					psize+=1
					q=q._succ
				Wend

				Repeat
					Local t:Node<T>
					If psize And qsize And q<>_head
						Local cc=Compare( p._data,q._data ) * ccsgn
						If cc<=0
							t=p
							p=p._succ
							psize-=1
						Else
							t=q
							q=q._succ
							qsize-=1
						Endif
					Else If psize
						t=p
						p=p._succ
						psize-=1
					Else If qsize And q<>_head
						t=q
						q=q._succ
						qsize-=1
					Else
						Exit
					Endif
					t._pred=tail
					tail._succ=t
					tail=t
				Forever
				p=q
			Wend
			tail._succ=_head
			_head._pred=tail

			If merges<=1 Return

			insize*=2
		Forever

	End Method

Private

	Field _head:Node<T>=New HeadNode<T>
	
End

Class Node<T>

	Method New( succ:Node,pred:Node,data:T )
		_succ=succ
		_pred=pred
		_succ._pred=Self
		_pred._succ=Self
		_data=data
	End
	
	Method Value:T()
		Return _data
	End

	Method Remove()
#If CONFIG="debug"
		If _succ._pred<>Self Error "Illegal operation on removed node"
#Endif
		_succ._pred=_pred
		_pred._succ=_succ
	End Method

	Method NextNode:Node()
#If CONFIG="debug"
		If _succ._pred<>Self Error "Illegal operation on removed node"
#Endif
		Return _succ.GetNode()
	End

	Method PrevNode:Node()
#If CONFIG="debug"
		If _succ._pred<>Self Error "Illegal operation on removed node"
#Endif
		Return _pred.GetNode()
	End

Private

	Field _succ:Node
	Field _pred:Node
	Field _data:T
	
	Method GetNode:Node<T>()
		Return Self
	End

End

Private

Class HeadNode<T> Extends Node<T>

	Method New()
		_succ=Self
		_pred=Self
	End

	Method GetNode:Node<T>()
		Return Null
	End
	
End

Public

Class Enumerator<T>

	Method New( list:List<T> )
		_list=list
		_curr=list._head._succ
	End Method

	Method HasNext:Bool()
		While _curr._succ._pred<>_curr
			_curr=_curr._succ
		Wend
		Return _curr<>_list._head
	End 

	Method NextObject:T()
		Local data:T=_curr._data
		_curr=_curr._succ
		Return data
	End

	 Method Reset:Void()
		_curr = _list._head._succ
	 End
 
Private
	
	Field _list:List<T>
	Field _curr:Node<T>

End

Class BackwardsList<T>

	Method New( list:List<T> )
		_list=list
	End

	Method ObjectEnumerator:BackwardsEnumerator<T>()
		Return New BackwardsEnumerator<T>( _list )
	End Method
	
Private

	Field _list:List<T>

End

Class BackwardsEnumerator<T>

	Method New( list:List<T> )
		_list=list
		_curr=list._head._pred
	End Method

	Method HasNext:Bool()
		While _curr._pred._succ<>_curr
			_curr=_curr._pred
		Wend
		Return _curr<>_list._head
	End 

	Method NextObject:T()
		Local data:T=_curr._data
		_curr=_curr._pred
		Return data
	End

Private
	
	Field _list:List<T>
	Field _curr:Node<T>

End

'Helper versions

Class IntList Extends List<Int>

	Method New( data:Int[] )
		Super.New( data )
	End

	Method Equals?( lhs,rhs )
		Return lhs=rhs
	End
	
	Method Compare( lhs,rhs )
		Return lhs-rhs
	End

End

Class FloatList Extends List<Float>

	Method New( data:Float[] )
		Super.New( data )
	End
	
	Method Equals?( lhs#,rhs# )
		Return lhs=rhs
	End
	
	Method Compare( lhs#,rhs# )
		If lhs<rhs Return -1
		Return lhs>rhs
	End
	
End

Class StringList Extends List<String>
	
	Method New( data:String[] )
		Super.New( data )
	End
	
	Method Join$( separator:String="" )
		Return separator.Join( ToArray() )
	End
	
	Method Equals?( lhs$,rhs$ )
		Return lhs=rhs
	End

	Method Compare( lhs$,rhs$ )
		Return lhs.Compare( rhs )
	End

End
