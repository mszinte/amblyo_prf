function sound=soundDefine(duration,freq,sampleRate)
%just define and build a sound ready to be played
%to play it: %play(sound.sound1)

if ~exist('sampleRate','var');sampleRate=44100;end

%define the sound
sound.duration=duration; %in sec
sound.sampleRate=sampleRate;
sound.f=freq; %in Hz
sound.F=sound.duration*sound.sampleRate;

%make an ojbect with
sound.obj=audioplayer(sineWave(duration,freq,sampleRate),sound.sampleRate);


