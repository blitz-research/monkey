
Import asyncevent

#If Not BRL_MONKEYSTORE_IMPLEMENTED
#If TARGET="ios" Or TARGET="android" Or TARGET="winrt"
#BRL_MONKEYSTORE_IMPLEMENTED=True
#If TARGET="ios"
#LIBS+="StoreKit.framework"
Import "native/monkeystore.ios.cpp"
#Elseif TARGET="android"
#SRCS+="${CD}/native/android_iab/src/com/android/vending/billing/IInAppBillingService.aidl"
#ANDROID_MANIFEST_MAIN+="<uses-permission android:name=~qcom.android.vending.BILLING~q />"
Import "native/monkeystore.android.java"
#Else If TARGET="winrt"
Import "native/monkeystore.winrt.cpp"
#Endif
#Endif
#Endif

#If Not BRL_MONKEYSTORE_IMPLEMENTED
#Error "Native MonkeyStore class not implemented"
#Endif

Extern Private

Class BBProduct
Private
	Field valid:Bool
	Field title:String
	Field description:String
	Field price:String
	Field identifier:String
	Field type:Int				'1=consumable, 2=non-consumable
	Field owned:Bool
	Field interrupted:Bool
End

Class BBMonkeyStore
Private
	Method OpenStoreAsync:Void( products:BBProduct[] )
	Method BuyProductAsync:Void( product:BBProduct )
	Method GetOwnedProductsAsync:Void()
	
	Method IsRunning:Bool()
	Method GetResult:Int()
End

Public

Interface IOnOpenStoreComplete
	Method OnOpenStoreComplete:Void( result:Int,interrupted:Product[] )
End

Interface IOnBuyProductComplete
	Method OnBuyProductComplete:Void( result:Int,product:Product )
End

Interface IOnGetOwnedProductsComplete
	Method OnGetOwnedProductsComplete:Void( result:Int,products:Product[] )
End

Class Product Extends BBProduct

	Method Title:String() Property
		Return title
	End
	
	Method Description:String() Property
		Return description
	End
	
	Method Price:String() Property
		Return price
	End
	
	Method Identifier:String() Property
		Return identifier
	End
	
	Method Type:Int() Property
		Return type
	End
	
	Method ToString:String() Property
		Return title+","+", "+description+", "+price
	End
	
End

Class MonkeyStore Implements IAsyncEventSource

	Method New()
		_store=New BBMonkeyStore
	End

	Method AddProducts:Void( ids:String[],type:Int )
	
		If _state<0 Error "Store unavailable"
		If _state<>0 Error "Store already open"
	
		If type<>1 And type<>2 Error "Invalid product type"

		For Local id:=Eachin ids
			Local p:=New Product
			p.identifier=id
			p.type=type
			_products.Push p
		Next
	End
	
	Method OpenStoreAsync:Void( onComplete:IOnOpenStoreComplete )
	
		If _state<0 Error "Store unavailable"
		If _state<>0 Error "Store already open"
		
		_bbproducts=New BBProduct[_products.Length]
		For Local i:=0 Until _products.Length
			_bbproducts[i]=_products.Get( i )
		Next

		_onOpen=onComplete
		_state=2
		
		AddAsyncEventSource Self

		_store.OpenStoreAsync( _bbproducts )
	End
	
	Method BuyProductAsync:Void( product:Product,onComplete:IOnBuyProductComplete )
	
		If _state<0 Error "Store unavailable"
		If _state=0 Error "Store not open"
		If _state<>1 Error "Store currently busy"
		
		_buying=product
		_onBuy=onComplete
		_state=3
		
		AddAsyncEventSource Self
		
		_store.BuyProductAsync( product )
	End
	
	Method GetOwnedProductsAsync:Void( onComplete:IOnGetOwnedProductsComplete )
	
		If _state<0 Error "Store unavailable"
		If _state=0 Error "Store not open"
		If _state<>1 Error "Store currently busy"
		
		_onGetOwned=onComplete
		_state=4
		
		AddAsyncEventSource Self
		
		_store.GetOwnedProductsAsync()
	End
	
	Method GetProduct:Product( id:String )
		Return _prods.Get( id )
	End
	
	Method GetProducts:Product[]()
		Return _all
	End
	
	Method GetProducts:Product[]( type:Int )
	
		If type<>1 And type<>2 Error "Invalid product type"
	
		If type=1 Return _cons
		Return _ncons
	End
	
	Method IsOpen:Bool() Property
		Return _state>0 And _state<>2
	End
	
	Method IsBusy:Bool() Property
		Return _state>1
	End
	
	Private
	
	Field _state:Int				'0=INIT, 1=IDLE, 2=OPENING, 3=BUYING, 4=GETOWNED
	Field _store:BBMonkeyStore
	
	Field _onOpen:IOnOpenStoreComplete
	
	Field _buying:Product
	Field _onBuy:IOnBuyProductComplete
	
	Field _onGetOwned:IOnGetOwnedProductsComplete
	
	Field _products:=New Stack<Product>
	Field _bbproducts:BBProduct[]
	
	Field _all:Product[]
	Field _cons:Product[]
	Field _ncons:Product[]
	Field _prods:=New StringMap<Product>
	
	Method UpdateAsyncEvents:Void()
		If _store.IsRunning() Return
		
		RemoveAsyncEventSource Self
		
		Local result:=_store.GetResult()
		
		Select _state
		Case 2
		
			Local all:=New Stack<Product>
			Local cons:=New Stack<Product>
			Local ncons:=New Stack<Product>
			Local inter:=New Stack<Product>
			
			If result=0
				For Local p:=Eachin _products
					If Not p.valid Continue
					all.Push p
					_prods.Set p.identifier,p
					If p.type=1 cons.Push p
					If p.type=2 ncons.Push p
					If p.interrupted inter.Push p
				Next
				_state=1
			Else
				For Local p:=Eachin _products
					If Not p.valid Continue
					If p.interrupted inter.Push p
				Next
				_state=0
			End
			
			_all=all.ToArray()
			_cons=cons.ToArray()
			_ncons=ncons.ToArray()
			
			Local onOpen:=_onOpen
			_onOpen=Null
			onOpen.OnOpenStoreComplete( result,inter.ToArray() )
			
		Case 3
		
			If result=0 And _buying.type=2 _buying.owned=True
		
			_state=1
			
			Local onBuy:=_onBuy
			_onBuy=Null
			onBuy.OnBuyProductComplete( result,_buying )
			
		Case 4
		
			Local owned:=New Stack<Product>
			
			If result=0
				For Local p:=Eachin _ncons
					If p.owned owned.Push p
				Next
			Endif
			
			_state=1
			
			Local onGetOwned:=_onGetOwned
			_onGetOwned=Null
			onGetOwned.OnGetOwnedProductsComplete( result,owned.ToArray() )
			
		Default
		
			Error "INTERNAL ERROR"
			
		End
		
	End
	
End
