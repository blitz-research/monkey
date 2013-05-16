
#Rem

@about

>>Markdown syntax

>>>span tags:

\`...` code
\*...* bold
\%...% italic

>>>prefix tags:

\@ local sym, eg: discussion of param

>>>start of line tags:

\> H1
\>> H2
\>>> H3
\* UL
\+ OL

>>>links:

\[[Target]]
\[[Target|Label]]

>>>misc

escape any leading char with \

>>>table:

| cell | cell | cell


By default, first row is a header row. Start a table with a single | for a 'headerless' table.

#End

Interface ILinkResolver

	Method ResolveLink:String( link:String,text:String )

End

Interface IPrettifier

	Method BeginPrettyBlock:String()
	
	Method EndPrettyBlock:String()

	Method PrettifyLine:String( text:String )
	
End


Class Markdown

	Method New( resolver:ILinkResolver,prettifier:IPrettifier )
		_resolver=resolver
		_prettifier=prettifier
	End

	Method ToHtml:String( src:String )
		Local html:=""
		If src.Contains( "~n" )
			Local buf:=New StringStack
			For Local line:=Eachin src.Split( "~n" )
				buf.Push LineToHtml( line )
			Next
			
			html=buf.Join( "~n" )
		Else
			html=LineToHtml( src )
		Endif
		
		If _blk Return html+SetBlock( "" )
		Return html
	End
	
	Private
	
	Field _blk:String
	Field _resolver:ILinkResolver
	Field _prettifier:IPrettifier
	
	Method Find:Int( src:String,text:String,start:Int )
		Local i:=src.Find( text,start )
		If i=-1 Return -1
		Local j:=i
		While j>0 And src[j-1]=92
			j-=1
		Wend
		If j<>i And ((i-j)&1)=1 Return -1
		Return i
	End
	
	Method ReplaceSpanTags:String( src:String,tag:String,html:String )
		'		
		'tag...tag -> <html>...</html>
		'
		Local i:=0,l:=tag.Length
		Repeat
			Local i0:=Find(src,tag,i)
			If i0=-1 Exit
			Local i1:=Find(src,tag,i0+l)
			If i1=-1 Or i1=i0+l Exit
			Local r:="<"+html+">"+src[i0+l..i1]+"</"+html+">"
			src=src[..i0]+r+src[i1+l..]
			i=i0+r.Length
		Forever
		Return src
	End
	
	Method ReplacePrefixTags:String( src:String,tag:String,html:String )
		'
		'tag ident...-> <html>ident</html>
		'
		Local i:=0,l:=tag.Length
		Repeat
			Local i0:=Find(src,tag,i)
			If i0=-1 Exit
			Local i1:=i0+l
			While i1<src.Length
				Local c:=src[i1]
				If (c=95) Or (c>=65 And c<=90) Or (c>=97 And c<=122) Or (i1>i0+l And c>=48 And c<=57) 
					i1+=1
					Continue
				Endif
				Exit
			Wend
			'find
			If i1=i0+l
				i+=l
				Continue
			Endif
			Local r:="<"+html+">"+src[i0+l..i1]+"</"+html+">"
			src=src[..i0]+r+src[i1..]
			i=i0+r.Length
		Forever
		Return src		
	End
	
	Method ReplaceLinks:String( src:String )
		'
		'[[link]]  [[link|text]]
		'
		Local i:=0
		Repeat

			Local i0:=Find(src,"[[",i)
			If i0=-1 Exit
			Local i1:=Find(src,"]]",i0+2)
			If i1=-1 Exit
			
			Local p:=src[i0+2..i1],t:=""
			Local j:=p.Find("|")
			If j<>-1
				t=p[j+1..]
				p=p[..j]
			Endif
	
			Local r:=_resolver.ResolveLink(p,t)
			
			src=src[..i0]+r+src[i1+2..]
			i=i0+r.Length
		Forever
		'
		'[text](link)
		'
		i=0
		Repeat
			Local i0:=Find(src,"[",i)
			If i0=-1 Exit
			Local i1:=Find(src,"](",i0+1)
			If i1=-1 Or i1=i0+1 Exit
			Local i2:=Find(src,")",i1+2)
			If i2=-1 Or i2=i1+2 Exit
			'
			Local t:=src[i0+1..i1]
			Local p:=src[i1+2..i2]
			'
			Local r:=_resolver.ResolveLink(p,t)
			src=src[..i0]+r+src[i2+1..]
			i=i0+r.Length
		Forever
		'
		Return src
	End
	
	Method ReplaceEscs:String( src:String )
		'
		'\char -> char
		'
		Local i:=0
		Repeat
			Local i0:=src.Find("\",i)
			If i0=-1 Exit
			Local r:=src[i0+1..i0+2]
			Select r
			Case "<" r="&lt;"
			Case ">" r="&gt;"
			Case "&" r="&amp;"
			End
			src=src[..i0]+r+src[i0+2..]
			i=i0+r.Length
		Forever
		Return src
	End
	
	Method Prettify:String( text:String )
		If _prettifier Return _prettifier.PrettifyLine( text )
		Return text
	end
	
	Method SetBlock:String( blk:String )
		Local t:=""
		If _blk<>blk
			If _blk="pre" And _prettifier
				t=_prettifier.EndPrettyBlock()
			Else If _blk
				t="</"+_blk+">"
			Endif
			_blk=blk
			If _blk="pre" And _prettifier
				t+=_prettifier.BeginPrettyBlock()
			Else If _blk
				t+="<"+_blk+">"
			Endif
		Endif
		Return t
	End
	
	Method SpanToHtml:String( src:String )
	
		src=ReplaceSpanTags( src,"`","code" )
		
		src=ReplaceSpanTags( src,"*","b" )
		
		src=ReplaceSpanTags( src,"%","i" )
		
		src=ReplacePrefixTags( src,"@","b" )
		
		src=ReplaceLinks( src )
		
		src=ReplaceEscs( src )

		Return src
	End
	
	Method TrimStart:String( str:String )
		Local i:=0
		While i<str.Length And str[i]<=32
			i+=1
		Wend
		If i Return str[i..]
		Return str
	End
	
	Method TrimEnd:String( str:String )
		Local i:=str.Length
		While i>0 And str[i-1]<=32
			i-=1
		Wend
		If i<str.Length Return str[..i]
		Return str
	End

	Method LineToHtml:String( src:String )
	
		'Handle <pre> first...
		If _blk="pre"
			Local i:=src.Find( "</pre>" )
			If i=-1 Return Prettify( src )
			If src[..i].Trim() Return Prettify( src[..i] )+SetBlock( "" )
			Return SetBlock( "" )
		Endif
		
		If Not src
			If _blk="table" Return SetBlock( "" )+"<p>"
			Return "<p>"
		Endif
		
		If src="-" Or src="--" Or src="---"
			Return SetBlock( "" )+"<hr>"
		End
		
		If src.StartsWith( "<pre>" )
			Local t:=SetBlock( "pre" )
			If src[5..].Trim() Return t+Prettify( src[5..] )
			Return t
		End
		
		If src.StartsWith( "| " )
			src=SpanToHtml( src )
			Local bits:=New StringStack
			Local i:=1
			Repeat
				Local i0:=Find( src,"|",i )
				If i0=-1 Exit
				bits.Push src[i..i0].Trim()	'SpanToHtml( src[i..i0].Trim() )
				i=i0+1
			Forever
			bits.Push src[i..].Trim()	'bits.Push SpanToHtml( src[i..].Trim() )
			Local tag:="td"
			If _blk<>"table" tag="th"
			Return SetBlock( "table" )+"<tr><"+tag+">"+bits.Join( "</"+tag+"><"+tag+">" )+"</"+tag+"></tr>"
		Endif
		
		If src.StartsWith( ">" )
			Local i:=1
			While i<src.Length And src[i]=62	'>
				i+=1
			Wend
			If i<src.Length And src[i]<=32
				Local t:=SetBlock( "" )
				src=SpanToHtml( src[i+1..] )
				Return t+"<h"+i+">"+src+"</h"+i+">"
			Endif
		Endif
		
		If src.StartsWith( "* " )
			Local t:=SetBlock( "ul" )
			Return t+"<li>"+SpanToHtml( src[2..] )+"</li>"
		Endif
		
		If src.StartsWith( "+ " )
			Local t:=SetBlock( "ol" )
			Return t+"<li>"+SpanToHtml( src[2..] )+"</li>"
		Endif
		
		Local t:=SetBlock( "" )
		
		Local i:=Find( src,"~~n",src.Length-2 )
		If i<>-1 src=src[..-2]+"<br>"
		
		src=SpanToHtml( src )
		
		Return t+src
	End

End
