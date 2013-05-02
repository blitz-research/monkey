
//***** monkeygame.h *****

class BBIosGame : public BBGame{
public:
	BBIosGame();

	static BBIosGame *IosGame(){ return _iosGame; }
	
	virtual void SetKeyboardEnabled( bool enabled );
	virtual void SetUpdateRate( int updateRate );
	virtual int Millisecs();
	virtual int SaveState( String state );
	virtual String LoadState();
	virtual void OpenUrl( String url );
	
	virtual NSURL *PathToNSURL( String path );
	virtual String PathToFilePath( String path );
	
	virtual unsigned char *LoadImageData( String path,int *width,int *height,int *format );
	virtual unsigned char *LoadAudioData( String path,int *length,int *channels,int *format,int *hertz );
	virtual AVAudioPlayer *OpenAudioPlayer( String path );
	
	virtual BBMonkeyAppDelegate *GetUIAppDelegate();
	
	//***** INTERNAL *****
	
	virtual void SuspendGame();
	virtual void ResumeGame();
	
	virtual void UpdateTimerFired();
	virtual void TouchesEvent( UIEvent *event );
	
protected:
	static BBIosGame *_iosGame;
	
	UIApplication *_app;
	BBMonkeyAppDelegate *_appDelegate;
	
	bool _displayLinkAvail;
	UIAccelerometer *_accelerometer;
	NSTimer *_updateTimer;
	id _displayLink;
	
	double _nextUpdate;
	double _updatePeriod;

	UITouch *_touches[32];

	uint64_t _startTime;
	mach_timebase_info_data_t _timeInfo;

	double GetTime();
	void ValidateUpdateTimer();
};

//***** iosgame.cpp *****

#include <AudioToolbox/ExtendedAudioFile.h>
#include <AVFoundation/AVAudioPlayer.h>

unsigned char *LoadWAV( FILE *f,int *length,int *channels,int *format,int *hertz );

BBIosGame *BBIosGame::_iosGame;

BBIosGame::BBIosGame():
_displayLinkAvail( false ),
_accelerometer( 0 ),
_updateTimer( 0 ),
_displayLink( 0 ){
	_iosGame=this;
	
	_app=[UIApplication sharedApplication];
	_appDelegate=(BBMonkeyAppDelegate*)[_app delegate];
	
	NSString *reqSysVer=@"3.1";
	NSString *currSysVer=[[UIDevice currentDevice] systemVersion];
	if( [currSysVer compare:reqSysVer options:NSNumericSearch]!=NSOrderedAscending ) _displayLinkAvail=true;

	memset( _touches,0,sizeof(_touches) );
	
	_startTime=mach_absolute_time();
	mach_timebase_info( &_timeInfo );
}

double BBIosGame::GetTime(){
	return (double)( (mach_absolute_time()-_startTime) * _timeInfo.numer / _timeInfo.denom ) / 1000000000.0;
}

void BBIosGame::ValidateUpdateTimer(){

	if( _updateTimer ){
		[_updateTimer invalidate];
		_updateTimer=0;
	}else if( _displayLink ){
		[_displayLink invalidate];
		_displayLink=0;
	}
	
	if( _updateRate && !_suspended ){
	
		if( !_accelerometer && CFG_IOS_ACCELEROMETER_ENABLED ){
			_accelerometer=[UIAccelerometer sharedAccelerometer];
			[_accelerometer setUpdateInterval:1.0/_updateRate];
			[_accelerometer setDelegate:_appDelegate];
			[_app setIdleTimerDisabled:YES];
		}
		
		_updatePeriod=1.0/_updateRate;
		_nextUpdate=GetTime()+_updatePeriod;
	
		if( CFG_IOS_DISPLAY_LINK_ENABLED ){
			if( _updateRate==60 && _displayLinkAvail ){
				_displayLink=[NSClassFromString(@"CADisplayLink") displayLinkWithTarget:_appDelegate selector:@selector(updateTimerFired)];
				[_displayLink setFrameInterval:1];
				[_displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
			}
		}
		if( !_displayLink ){
			NSTimeInterval interval=(NSTimeInterval)(1.0/_updateRate);
			_updateTimer=[NSTimer scheduledTimerWithTimeInterval:interval target:_appDelegate selector:@selector(updateTimerFired) userInfo:nil repeats:TRUE];
		}
	}else{
	
		if( _accelerometer ){
			[_accelerometer setUpdateInterval:0.0];
			[_accelerometer setDelegate:0];
			[_app setIdleTimerDisabled:NO];
			_accelerometer=0;
		}
	}
}

//***** BBGame *****

void BBIosGame::SetKeyboardEnabled( bool enabled ){
	BBGame::SetKeyboardEnabled( enabled );
	
	if( enabled ){
		_appDelegate->textFieldState=1;
		_appDelegate->textField.text=@" ";
		[_appDelegate->textField becomeFirstResponder];
	}else{
		_appDelegate->textFieldState=0;
		[_appDelegate->textField resignFirstResponder];
	}
}

void BBIosGame::SetUpdateRate( int hertz ){
	BBGame::SetUpdateRate( hertz );
	ValidateUpdateTimer();
}

int BBIosGame::Millisecs(){
	return (int)( (mach_absolute_time()-_startTime) * _timeInfo.numer / (_timeInfo.denom * 1000000L) );
}

int BBIosGame::SaveState( String state ){
	NSString *nsstr=state.ToNSString();
	NSUserDefaults *prefs=[NSUserDefaults standardUserDefaults];
	[prefs setObject:nsstr forKey:@".monkeystate"];
	[[NSUserDefaults standardUserDefaults] synchronize];
	return 0;
}

String BBIosGame::LoadState(){
	NSUserDefaults *prefs=[NSUserDefaults standardUserDefaults];
	NSString *nsstr=[prefs stringForKey:@".monkeystate"];
	if( nsstr ) return String( nsstr );
	return "";
}

void BBIosGame::OpenUrl( String url ){
	NSURL *nsurl=[NSURL URLWithString:url.ToNSString()];
	if( nsurl ) [[UIApplication sharedApplication] openURL:nsurl];
}

NSURL *BBIosGame::PathToNSURL( String path ){
	String fpath=PathToFilePath( path );
	if( fpath!="" ) return [NSURL fileURLWithPath:fpath.ToNSString()];
	return [NSURL URLWithString:path.ToNSString()];
}

String BBIosGame::PathToFilePath( String path ){
	if( path.StartsWith( "monkey://data/" ) ){
		path=path.Slice( 14 );
		NSString *nspath=path.ToNSString();
		NSString *ext=[nspath pathExtension];
		NSString *file=[[nspath lastPathComponent] stringByDeletingPathExtension];
		NSString *dir=[@"data/" stringByAppendingString:[nspath stringByDeletingLastPathComponent]];
		NSString *rpath=[[NSBundle mainBundle] pathForResource:file ofType:ext inDirectory:dir];
		return String( rpath );
	}else if( path.StartsWith( "monkey://internal/" ) ){
		NSString *docs=[@"~/Documents" stringByExpandingTildeInPath];
		return String( docs )+"/"+path.Slice( 18 );
	}
	return "";
}

unsigned char *BBIosGame::LoadImageData( String path,int *width,int *height,int *format ){

	//need this in case we're running on a thread...
	NSAutoreleasePool *pool=[[NSAutoreleasePool alloc] init];

	UIImage *image=0;
	
	if( path.StartsWith( "monkey://data/" ) ){

		path=String( "data/" )+path.Slice(14);
		image=[UIImage imageNamed:path.ToNSString()];

	}else{
	
		if( NSURL *url=PathToNSURL( path ) ){
			if( NSData *data=[NSData dataWithContentsOfURL:url] ){
				image=[UIImage imageWithData:data];
			}
		}
	}
	
	if( !image ){
		[pool release];
		return 0;
	}
	
	CGImageRef cgimage=image.CGImage;
	
	int iwidth=CGImageGetWidth( cgimage );
	int iheight=CGImageGetHeight( cgimage );
	
	unsigned char *data=(unsigned char*)calloc( iwidth*iheight,4 );
	
	CGContextRef context=CGBitmapContextCreate( data,iwidth,iheight,8,iwidth*4,CGImageGetColorSpace(cgimage),kCGImageAlphaPremultipliedLast );
	CGContextDrawImage( context,CGRectMake(0,0,iwidth,iheight),cgimage );
	CGContextRelease( context );
	
	*width=iwidth;
	*height=iheight;
	*format=4;
	
	[pool release];

	gc_force_sweep=true;
	
	return data;
}

unsigned char *BBIosGame::LoadAudioData( String path,int *length,int *channels,int *format,int *hertz ){

	NSAutoreleasePool *pool=[[NSAutoreleasePool alloc] init];

	if( path.ToLower().EndsWith( ".wav" ) ){
		unsigned char *data=0;
		if( FILE *f=OpenFile( path,"rb" ) ){
			data=LoadWAV( f,length,channels,format,hertz );
			fclose( f );
		}
		[pool release];

		gc_force_sweep=true;	

		return data;
	}
	
	NSURL *url=PathToNSURL( path );
	
    ExtAudioFileRef fileRef=0;
    
	if( url && !ExtAudioFileOpenURL( (CFURLRef)url,&fileRef ) ){

	    AudioStreamBasicDescription fileFormat;
		UInt32 propSize=sizeof( fileFormat );
		
		if( !ExtAudioFileGetProperty( fileRef,kExtAudioFileProperty_FileDataFormat,&propSize,&fileFormat ) ){

		    AudioStreamBasicDescription outputFormat;
		
			outputFormat.mSampleRate=fileFormat.mSampleRate;
			outputFormat.mChannelsPerFrame=fileFormat.mChannelsPerFrame;
			outputFormat.mFormatID=kAudioFormatLinearPCM;
			outputFormat.mBytesPerPacket=2*outputFormat.mChannelsPerFrame;
			outputFormat.mFramesPerPacket=1;
			outputFormat.mBytesPerFrame=2*outputFormat.mChannelsPerFrame;
			outputFormat.mBitsPerChannel=16;
			outputFormat.mFormatFlags=kAudioFormatFlagsNativeEndian|kAudioFormatFlagIsPacked|kAudioFormatFlagIsSignedInteger;
			
			if( !ExtAudioFileSetProperty( fileRef,kExtAudioFileProperty_ClientDataFormat,sizeof( outputFormat ),&outputFormat ) ){

				SInt64 fileLen=0;
				UInt32 propSize=sizeof( fileLen );
				
				if( !ExtAudioFileGetProperty( fileRef,kExtAudioFileProperty_FileLengthFrames,&propSize,&fileLen ) ){
				
					UInt32 dataSize=fileLen * outputFormat.mBytesPerFrame;

					//Why dataSize*2? Sample code does it, but it appears unecessary....
					//
					unsigned char *data=(unsigned char*)calloc( dataSize,2 );

					AudioBufferList buf;
					buf.mNumberBuffers=1;
					buf.mBuffers[0].mData=data;
					buf.mBuffers[0].mDataByteSize=dataSize*2;
					buf.mBuffers[0].mNumberChannels=outputFormat.mChannelsPerFrame;
					
					// Read the data into an AudioBufferList
					if( !ExtAudioFileRead( fileRef,(UInt32*)&fileLen,&buf ) ){
				
						*length=fileLen;
						*channels=outputFormat.mChannelsPerFrame;
						*format=2;
						*hertz=outputFormat.mSampleRate;
						
						ExtAudioFileDispose( fileRef );		
						[pool release];		
						
						gc_force_sweep=true;
		
						return data;
					}
					free( data );
				}
			}
		}
		ExtAudioFileDispose( fileRef );
	}
	[pool release];
	return 0;
}

AVAudioPlayer *BBIosGame::OpenAudioPlayer( String path ){

	NSURL *url=PathToNSURL( path );
	if( !url) return 0;
	
	AVAudioPlayer *player=[[AVAudioPlayer alloc] initWithContentsOfURL:url error:0];
	
	return player;
}

BBMonkeyAppDelegate *BBIosGame::GetUIAppDelegate(){
	return _appDelegate;
}

//***** INTERNAL *****

void BBIosGame::SuspendGame(){
	BBGame::SuspendGame();
	ValidateUpdateTimer();
	
}

void BBIosGame::ResumeGame(){
	BBGame::ResumeGame();
	ValidateUpdateTimer();
}

void BBIosGame::UpdateTimerFired(){
	if( !_updateRate || _suspended ) return;

	int updates=0;
	for( updates=0;updates<4;++updates ){
		_nextUpdate+=_updatePeriod;
		
		UpdateGame();
		if( !_updateRate || _suspended ) return;
		
		if( _nextUpdate-GetTime()>0 ) break;
	}
	
	RenderGame();
	if( !_updateRate || _suspended ) return;
	
	if( updates==4 ) _nextUpdate=GetTime();
}

void BBIosGame::TouchesEvent( UIEvent *event ){
	if( [event type]==UIEventTypeTouches ){
	
		UIView *view=_appDelegate->view;

		float scaleFactor=1.0f;
		if( [view respondsToSelector:@selector(contentScaleFactor)] ){
			scaleFactor=[view contentScaleFactor];
		}
		
		for( int pid=0;pid<32;++pid ){
			if( _touches[pid] && _touches[pid].view!=view ) _touches[pid]=0;
		}
		
		for( UITouch *touch in [event touchesForView:view] ){
		
			int pid;
			for( pid=0;pid<32 && _touches[pid]!=touch;++pid ) {}

			int ev=BBGameEvent::None;

			switch( [touch phase] ){
			case UITouchPhaseBegan:
				if( pid!=32 ) break;
				for( pid=0;pid<32 && _touches[pid];++pid ){}
				if( pid==32 ) break;
				_touches[pid]=touch;
				ev=BBGameEvent::TouchDown;
				break;
			case UITouchPhaseEnded:
			case UITouchPhaseCancelled:
				if( pid==32 ) break;
				_touches[pid]=0;
				ev=BBGameEvent::TouchUp;
				break;
			case UITouchPhaseMoved:
			case UITouchPhaseStationary:
				ev=BBGameEvent::TouchMove;
				break;
			}
			
			if( ev==BBGameEvent::None ) continue;

			CGPoint p=[touch locationInView:view];
			p.x*=scaleFactor;
			p.y*=scaleFactor;
			
			TouchEvent( ev,pid,p.x,p.y );
		}
	}
}

//***** BBMonkeyView implementation *****

@implementation BBMonkeyView

+(Class)layerClass{
	return [CAEAGLLayer class];
}

-(id)initWithCoder:(NSCoder*)coder{

	backingWidth=0;
	backingHeight=0;
	defaultFramebuffer=0;
	colorRenderbuffer=0;
	depthRenderbuffer=0;

	if( self=[super initWithCoder:coder] ){
	
		// Enable retina display
		if( CFG_IOS_RETINA_ENABLED ){
			if( [self respondsToSelector:@selector(contentScaleFactor)] ){
				float scaleFactor=[[UIScreen mainScreen] scale];
				[self setContentScaleFactor:scaleFactor];
			}
		}
    
		// Get the layer
		CAEAGLLayer *eaglLayer=(CAEAGLLayer*)self.layer;
		      
		eaglLayer.opaque=TRUE;
		eaglLayer.drawableProperties=[NSDictionary dictionaryWithObjectsAndKeys:
        [NSNumber numberWithBool:FALSE],kEAGLDrawablePropertyRetainedBacking,kEAGLColorFormatRGBA8,kEAGLDrawablePropertyColorFormat,nil];
		
		if( CFG_OPENGL_GLES20_ENABLED ){
			context=[[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
			if( !context || ![EAGLContext setCurrentContext:context] ) exit(-1);
			
			glGenFramebuffers( 1,&defaultFramebuffer );
			glBindFramebuffer( GL_FRAMEBUFFER,defaultFramebuffer );
			glGenRenderbuffers( 1,&colorRenderbuffer );
			glBindRenderbuffer( GL_RENDERBUFFER,colorRenderbuffer );
			glFramebufferRenderbuffer( GL_FRAMEBUFFER,GL_COLOR_ATTACHMENT0,GL_RENDERBUFFER,colorRenderbuffer );
			if( CFG_OPENGL_DEPTH_BUFFER_ENABLED ){
				glGenRenderbuffers( 1,&depthRenderbuffer );
				glBindRenderbuffer( GL_RENDERBUFFER,depthRenderbuffer );
				glFramebufferRenderbuffer( GL_FRAMEBUFFER,GL_DEPTH_ATTACHMENT,GL_RENDERBUFFER,depthRenderbuffer );
				glBindRenderbuffer( GL_RENDERBUFFER,colorRenderbuffer );
			}
		}else{
			context=[[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES1];
			if( !context || ![EAGLContext setCurrentContext:context] ) exit(-1);

			glGenFramebuffersOES( 1,&defaultFramebuffer );
			glBindFramebufferOES( GL_FRAMEBUFFER_OES,defaultFramebuffer );
			glGenRenderbuffersOES( 1,&colorRenderbuffer );
			glBindRenderbufferOES( GL_RENDERBUFFER_OES,colorRenderbuffer );
			glFramebufferRenderbufferOES( GL_FRAMEBUFFER_OES,GL_COLOR_ATTACHMENT0_OES,GL_RENDERBUFFER_OES,colorRenderbuffer );
			if( CFG_OPENGL_DEPTH_BUFFER_ENABLED ){
				glGenRenderbuffersOES( 1,&depthRenderbuffer );
				glBindRenderbufferOES( GL_RENDERBUFFER_OES,depthRenderbuffer );
				glFramebufferRenderbufferOES( GL_FRAMEBUFFER_OES,GL_DEPTH_ATTACHMENT_OES,GL_RENDERBUFFER_OES,depthRenderbuffer );
				glBindRenderbufferOES( GL_RENDERBUFFER_OES,colorRenderbuffer );
			}
		}
	}
	return self;
}

-(void)drawView:(id)sender{
	printf( "drawView\n" );fflush( stdout );
	if( BBIosGame *game=BBIosGame::IosGame() ){
		game->StartGame();	//NOP if game already started
		game->RenderGame();
	}
}

-(void)presentRenderbuffer{
	if( CFG_OPENGL_GLES20_ENABLED ){
		[context presentRenderbuffer:GL_RENDERBUFFER];
	}else{
		[context presentRenderbuffer:GL_RENDERBUFFER_OES];
	}
}

-(BOOL)resizeFromLayer:(CAEAGLLayer *)layer{
	// Allocate color buffer backing based on the current layer size
	if( CFG_OPENGL_GLES20_ENABLED ){
	
		glBindRenderbuffer( GL_RENDERBUFFER,colorRenderbuffer );
		[context renderbufferStorage:GL_RENDERBUFFER fromDrawable:layer];
		glGetRenderbufferParameteriv( GL_RENDERBUFFER,GL_RENDERBUFFER_WIDTH,&backingWidth );
		glGetRenderbufferParameteriv( GL_RENDERBUFFER,GL_RENDERBUFFER_HEIGHT,&backingHeight );
		if( CFG_OPENGL_DEPTH_BUFFER_ENABLED ){
			glBindRenderbuffer( GL_RENDERBUFFER,depthRenderbuffer );
			glRenderbufferStorage( GL_RENDERBUFFER,GL_DEPTH_COMPONENT16,backingWidth,backingHeight );
			glBindRenderbuffer( GL_RENDERBUFFER,colorRenderbuffer );
		}
		if( glCheckFramebufferStatus( GL_FRAMEBUFFER )!=GL_FRAMEBUFFER_COMPLETE ) exit(-1);
		
	}else{
	
		glBindRenderbufferOES( GL_RENDERBUFFER_OES,colorRenderbuffer );
		[context renderbufferStorage:GL_RENDERBUFFER_OES fromDrawable:layer];
		glGetRenderbufferParameterivOES( GL_RENDERBUFFER_OES,GL_RENDERBUFFER_WIDTH_OES,&backingWidth );
		glGetRenderbufferParameterivOES( GL_RENDERBUFFER_OES,GL_RENDERBUFFER_HEIGHT_OES,&backingHeight );
		if( CFG_OPENGL_DEPTH_BUFFER_ENABLED ){
			glBindRenderbufferOES( GL_RENDERBUFFER_OES,depthRenderbuffer );
			glRenderbufferStorageOES( GL_RENDERBUFFER_OES,GL_DEPTH_COMPONENT16_OES,backingWidth,backingHeight );
			glBindRenderbufferOES( GL_RENDERBUFFER_OES,colorRenderbuffer );
		}
		if( glCheckFramebufferStatusOES( GL_FRAMEBUFFER_OES )!=GL_FRAMEBUFFER_COMPLETE_OES ) exit(-1);
		
	}
	
	return YES;
}

-(void)layoutSubviews{
	[self resizeFromLayer:(CAEAGLLayer*)self.layer];
	[self drawView:nil];
}

-(void)dealloc{
	if( CFG_OPENGL_GLES20_ENABLED ){
		glDeleteFramebuffers( 1,&defaultFramebuffer );
		glDeleteRenderbuffers( 1,&colorRenderbuffer );
		if( depthRenderbuffer ) glDeleteRenderbuffers( 1,&depthRenderbuffer );
		if( [EAGLContext currentContext]==context ) [EAGLContext setCurrentContext:nil];
		[context release];
	}else{
		glDeleteFramebuffersOES( 1,&defaultFramebuffer );
		glDeleteRenderbuffersOES( 1,&colorRenderbuffer );
		if( depthRenderbuffer ) glDeleteRenderbuffersOES( 1,&depthRenderbuffer );
		if( [EAGLContext currentContext]==context ) [EAGLContext setCurrentContext:nil];
		[context release];
	}
	[super dealloc];
}

@end

//***** BBMonkeyWindow implementation *****

@implementation BBMonkeyWindow

-(void)touchesBegan:(NSSet*)touches withEvent:(UIEvent*)event{
	BBIosGame::IosGame()->TouchesEvent( event );
}

-(void)touchesMoved:(NSSet*)touches withEvent:(UIEvent*)event{
	BBIosGame::IosGame()->TouchesEvent( event );
}

-(void)touchesEnded:(NSSet*)touches withEvent:(UIEvent*)event{
	BBIosGame::IosGame()->TouchesEvent( event );
}

-(void)touchesCancelled:(NSSet*)touches withEvent:(UIEvent*)event{
	BBIosGame::IosGame()->TouchesEvent( event );
}

@end

//***** BBMonkeyViewController implementation *****

@implementation BBMonkeyViewController

-(BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation{

	CFArrayRef array=(CFArrayRef)CFBundleGetValueForInfoDictionaryKey( CFBundleGetMainBundle(),CFSTR("UISupportedInterfaceOrientations") );
	if( !array ) return NO;
	
	CFRange range={ 0,CFArrayGetCount( array ) };

	switch( interfaceOrientation ){
	case UIInterfaceOrientationPortrait:
		return CFArrayContainsValue( array,range,CFSTR("UIInterfaceOrientationPortrait") );
	case UIInterfaceOrientationPortraitUpsideDown:
		return CFArrayContainsValue( array,range,CFSTR("UIInterfaceOrientationPortraitUpsideDown") );
	case UIInterfaceOrientationLandscapeLeft:
		return CFArrayContainsValue( array,range,CFSTR("UIInterfaceOrientationLandscapeLeft") );
	case UIInterfaceOrientationLandscapeRight:
		return CFArrayContainsValue( array,range,CFSTR("UIInterfaceOrientationLandscapeRight") );
	}
	return NO;
}

-(NSUInteger)supportedInterfaceOrientations{
    
	CFArrayRef array=(CFArrayRef)CFBundleGetValueForInfoDictionaryKey( CFBundleGetMainBundle(),CFSTR("UISupportedInterfaceOrientations") );
	if( !array ) return 0;
    
	CFRange range={ 0,CFArrayGetCount( array ) };
    
    NSUInteger mask=0;
    
    if( CFArrayContainsValue( array,range,CFSTR("UIInterfaceOrientationPortrait") ) ) mask|=UIInterfaceOrientationMaskPortrait;
    if( CFArrayContainsValue( array,range,CFSTR("UIInterfaceOrientationPortraitUpsideDown") ) ) mask|=UIInterfaceOrientationMaskPortraitUpsideDown;
    if( CFArrayContainsValue( array,range,CFSTR("UIInterfaceOrientationLandscapeLeft") ) ) mask|=UIInterfaceOrientationMaskLandscapeLeft;
    if( CFArrayContainsValue( array,range,CFSTR("UIInterfaceOrientationLandscapeRight") ) ) mask|=UIInterfaceOrientationMaskLandscapeRight;
    
    return mask;
}

@end

//***** BBMonkeyAppDelegate implementation *****

@implementation BBMonkeyAppDelegate

@synthesize _window;
@synthesize view;
@synthesize viewController;
@synthesize textField;

-(void)applicationWillResignActive:(UIApplication*)application{

	game->SuspendGame();
}

-(void)applicationDidBecomeActive:(UIApplication*)application{

	game->ResumeGame();
}

-(BOOL)textFieldShouldEndEditing:(UITextField*)textField{

	if( textFieldState ){	//still active?
		game->KeyEvent( BBGameEvent::KeyChar,27 );	//generate ESC
		return NO;
	}
	
	return YES;
}

-(BOOL)textField:(UITextField*)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString*)str{
	
	int n=[str length];
	
	if( n==0 && range.length==1 ){
		game->KeyEvent( BBGameEvent::KeyChar,8 );	//generate BACKSPC
	}else if( n==1 && range.length==0 ){
		int chr=[str characterAtIndex:0];
		game->KeyEvent( BBGameEvent::KeyChar,chr==10 ? 13 : chr );
	}
	return NO;
}

-(void)accelerometer:(UIAccelerometer*)accelerometer didAccelerate:(UIAcceleration*)accel{

	float accelX,accelY,accelZ;
	
	switch( viewController.interfaceOrientation ){
	case UIDeviceOrientationPortrait:
		accelX=+accel.x;
		accelY=-accel.y;
		break;
	case UIDeviceOrientationPortraitUpsideDown:
		accelX=-accel.x;
		accelY=+accel.y;
		break;
	case UIDeviceOrientationLandscapeLeft:
		accelX=-accel.y;
		accelY=-accel.x;
		break;
	case UIDeviceOrientationLandscapeRight:
		accelX=+accel.y;
		accelY=+accel.x;
		break;
	default:
		return;
	}
	accelZ=-accel.z;
	
	game->MotionEvent( BBGameEvent::MotionAccel,0,accelX,accelY,accelZ );
}

-(void)updateTimerFired{

	game->UpdateTimerFired();
}

-(void)dealloc{
	[_window release];
	[view release];
	[super dealloc];
}

@end
