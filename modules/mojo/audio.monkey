
' Module mojo.audio
'
' Copyright 2011 Mark Sibly, all rights reserved.
' No warranty implied; use at your own risk.

Private

Import audiodevice

Import data

Global device:AudioDevice

Public

Function SetAudioDevice( dev:AudioDevice )
	device=dev
End

Function GetAudioDevice:AudioDevice()
	Return device
End

Class Sound

	Method New( sample:Sample )
		Self.sample=sample
	End
	
	Method Discard()
		If sample
			sample.Discard
			sample=Null
		Endif
	End
	
Private
	Field sample:Sample
End

Function LoadSound:Sound( path$ )
	Local sample:Sample=device.LoadSample( FixDataPath(path) )
	If sample Return New Sound( sample )
	Return Null
End

Function PlaySound( sound:Sound,channel=0,flags=0 )
	If sound And sound.sample device.PlaySample sound.sample,channel,flags
End

Function StopChannel( channel )
	device.StopChannel channel
End

Function PauseChannel( channel )
	device.PauseChannel channel
End

Function ResumeChannel( channel )
	device.ResumeChannel channel
End

Function ChannelState( channel )
	Return device.ChannelState( channel )
End

Function SetChannelVolume( channel,volume# )
	device.SetVolume channel,volume
End

Function SetChannelPan( channel,pan# )
	device.SetPan channel,pan
End

Function SetChannelRate( channel,rate# )
	device.SetRate channel,rate
End

Function PlayMusic( path$,flags=1 )
	Return device.PlayMusic( FixDataPath(path),flags )
End

Function StopMusic()
	device.StopMusic
End

Function PauseMusic()
	device.PauseMusic
End

Function ResumeMusic()
	device.ResumeMusic
End

Function MusicState()
	Return device.MusicState()
End

Function SetMusicVolume( volume# )
	device.SetMusicVolume volume
End
