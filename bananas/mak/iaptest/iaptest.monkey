
#rem

IMPORTANT!

This wont work 'as is'! You'll need to set up a bunch of stuff on GooglePlay/iTunes Connect/Ouya developer portal such as app/products etc.

Quick Ouya notes:

Besides creating an account and products etc in Ouya developer console (very easy) you will need to:

* Install Android 4.1.2 (API16) SDK via SDK manager. 

* Set ANDROID_OUYA_DEVELOPER_UUID to your developer UUID. This can be found on the developer portal home page.

* Download/copy your app's 'key.der' file into the iaptest.data dir. This can be found on the developer portal 'My Games' page under 'signing key'.

#end

Import mojo
Import brl.json
Import brl.filestream
Import brl.monkeystore

'For OUYA!
Const USE_JOYSTICK:=False

'For Windows 8! make sure to also set ProductId on Winphone8...
#WINRT_PRINT_ENABLED=True
#WINRT_TEST_IAP=True

'For android!
#ANDROID_VERSION_CODE="2"
#ANDROID_APP_TITLE="Bouncy Aliens"
#ANDROID_APP_PACKAGE="com.monkeycoder.bouncyaliens"
#ANDROID_KEY_STORE="../../release-key.keystore"
#ANDROID_KEY_ALIAS="release-key-alias"
#ANDROID_KEY_STORE_PASSWORD="password"
#ANDROID_KEY_ALIAS_PASSWORD="password"
#ANDROID_SIGN_APP=True

'For Ouya!
#ANDROID_OUYA_DEVELOPER_UUID="xxxxxxxx-yyyy-zzzz-yyyy-xxxxxxxxxxxx"	'from the main developer portal page

Global CONSUMABLES:=["bulletboost","speedboost"]

Global NON_CONSUMABLES:=["shipupgrade2"]

Class MyApp Extends App Implements IOnOpenStoreComplete,IOnBuyProductComplete,IOnGetOwnedProductsComplete

	Field store:MonkeyStore
	Field purchases:=New JsonObject
	
	Method LoadPurchases:Void()
		Local f:=FileStream.Open( "monkey://internal/.purchases","r" )
		If Not f Return
		Local json:=f.ReadString()
		Print "LoadPurchases: Json="+json
		purchases=New JsonObject( json )
		f.Close()
	End
	
	Method SavePurchases:Void()
		Local f:=FileStream.Open( "monkey://internal/.purchases","w" )
		If Not f Error "Unable to save purchases"
		Local json:=purchases.ToJson()
		Print "SavePurchases: Json="+json
		f.WriteString( json )
		f.Close()
	End
	
	Method MakePurchase:Void( product:Product )
		Select product.Type
		Case 1 purchases.SetInt product.Identifier,purchases.GetInt( product.Identifier )+1
		Case 2 purchases.SetBool product.Identifier,True
		End
		SavePurchases
	end
	
	Method OnOpenStoreComplete:Void( result:Int,interrupted:Product[] )
		Print "OpenStoreComplete, result="+result
		If result<>0 
			Print "Failed to open Monkey Store"
			store=Null
		Endif
		If interrupted.Length
			Print "Interrupted purchases:"
			For Local p:=Eachin interrupted
				Print p.Identifier
				MakePurchase p
			Next
		Else
			Print "No interrupted purchases."
		Endif
	End
	
	Method OnBuyProductComplete:Void( result:Int,product:Product )
		Print "BuyProductComplete, result="+result
		If result<>0 Return
		MakePurchase product
	End
	
	Method OnGetOwnedProductsComplete:Void( result:Int,products:Product[] )
		Print "GetOwnedProductsComplete, result="+result
		If result<>0 Return
		If Not products Return
		For Local p:=Eachin products
			purchases.SetBool p.Identifier,True
		Next
		SavePurchases
	End
	
	Method OnCreate()
	
		LoadPurchases
	
		store=New MonkeyStore
		
		store.AddProducts( CONSUMABLES,1 )
		store.AddProducts( NON_CONSUMABLES,2 )
		
		store.OpenStoreAsync( Self )
		
		SetUpdateRate 60
	End
	
	Field mousex:Float
	Field mousey:Float
	
	Method OnUpdate()
	
		UpdateAsyncEvents
		
		If Not store Return
		
		Local hit:=0
		
		If USE_JOYSTICK
			mousex=Clamp( mousex+JoyX(0)*10,0.0,Float( DeviceWidth ) )
			mousey=Clamp( mousey+JoyY(0)*10,0.0,Float( DeviceHeight ) )
			hit=JoyHit( 0 )
		Else
			mousex=MouseX
			mousey=MouseY
			hit=MouseHit( 0 )
		Endif		
		
		If store.IsOpen() And Not store.IsBusy() And hit
			Local my:=mousey*(480.0/DeviceHeight)
			
			If my>=440-6 And my<440+6
				store.GetOwnedProductsAsync( Self )
			Else
				Local y:=40
				For Local p:=Eachin store.GetProducts()
					If my>=y-6 And my<y+6
						store.BuyProductAsync p,Self
						Exit
					Endif
					y+=24
				Next
			Endif
			
		Endif

	End
	
	Method OnRender()

		Cls

		PushMatrix
		
		Scale DeviceWidth/320.0,DeviceHeight/480.0
		
		DrawText Millisecs,0,0
		
		If Not store
			DrawText "Store unavailable",160,40,.5,.5
		Else If store.IsOpen()
			SetColor 255,255,255
			If store.IsBusy() SetColor 128,128,128
			
			DrawText "Restore Owned Products",160,440,.5,.5
			
			Local y:=40
			For Local p:=Eachin store.GetProducts()
				Local t:="Buy "+p.Title
				Select p.Type
				Case 1 t+=" ("+purchases.GetInt( p.Identifier )+")"
				Case 2 If purchases.GetBool( p.Identifier ) t+=" (owned)"
				End
				DrawText t,160,y,.5,.5
				y+=24
			Next
		Else
			DrawText "Opening store...",160,40,.5,.5
		Endif
		
		PopMatrix
		
		SetColor 255,255,255
		DrawCircle mousex-8,mousey-8,16
	End

End

Function Main()
	New MyApp
End
