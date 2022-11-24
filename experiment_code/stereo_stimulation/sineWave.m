function sineWaveSignal=sineWave(duration,freq,sampleRate)

if ~exist('sampleRate','var');sampleRate=100;end

F=duration*sampleRate;
sineWaveSignal=sin(freq*duration*2*pi*(0:F)/F);