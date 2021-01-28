//HAPPY BOT
(

~bh = Buffer.alloc(s, 44100 * 10.0, 1);
~startH = 0;
~stopH = 4.0;


SynthDef(\happybot, {
	arg sfreq, slevel, mratio, mindex, amp, freq, out=0, mratio2, sus=3, pvwipe=0;
	var sig, env, chain;
	freq = LFNoise1.kr(1).range(1, 9);
	sfreq = LFNoise0.kr(freq, 1000, 200);
	sig = LFTri.ar(sfreq * mratio2) * slevel;
	sig = sig + SinOsc.ar(sfreq  * mratio2) * mindex;
	sig = cos( sig * 2pi) * 3 * 0.4;
	env = EnvGen.kr(Env.linen(0.01, sus, 0.01), doneAction:2);
	sig = sig * env;
	chain = FFT(LocalBuf(2048), sig);
    chain = PV_BinScramble(chain, pvwipe , 0.1);
    Out.ar(out, 0.1 * IFFT(chain).dup);
},1!5).add;


~patthappy = {arg repeath=(~repeathappy * 6);
	~happybots = Pdef(\happy, Pbind(
	\instrument, \happybot,
	\dur,Pexprand(Pfunc{~durH}, (Pfunc{~durH} / 4), repeath),
	\mratio, Pexprand(Pfunc{~mratioH}, (Pfunc{~mratioH} / 2)),
	\mratio2, Pexprand(Pfunc{~mratioH}, (Pfunc{~mratioH} / 2)),
	\mindex, Pexprand(Pfunc{~mindexH}, (Pfunc{~mindexH} / 2)),
	\slevel, Pexprand(0.1, 10, 2),
	\pvwipe, Pexprand(0.0, 1, 2),
	\sus, Pkey(\dur),
);
);
	Ndef(\happybot2, ~happybots);
};



SynthDef(\recbufH, { arg out = 0, bufnumh = 0, run=1;
	RecordBuf.ar(SoundIn.ar(0), bufnumh, run, loop:0, doneAction:2);
}).add;

SynthDef(\amplpfH, {var sig, amp, env;
	sig = PlayBuf.ar(1, ~bh, doneAction:2, loop:0);
	sig = DelayL.ar(sig, 0.05, 0.05);
	env = EnvGen.kr(Env.linen(0.01, (~stopH - ~startH), 0.01), doneAction:2);
	sig = sig * env;
	amp = Amplitude.kr(sig);
	amp = amp.lag(2);
	SendTrig.kr(Impulse.kr(10), 11, amp);
}).add;


OSCdef(\startstopH, { arg msg, time;
	if(msg[2] == 8,{
	"start rec".postln;
	a = Synth(\recbufH, [\bufnum, ~bh]);});

	if(msg[2] == 9,{
	"stop rec".postln;
		Synth(\amplpfH);
	a.set(\run,0);
	});
},'/tr', s.addr);

OSCdef(\amplowH, { arg msg;
	if(msg[2] == 11, {
		~durH = msg[3].linlin(0.01, 0.01, 1, 0.5);
	});
}, '/tr', s.addr);

OSCdef(\ampatkH, { arg msg;
	if(msg[2] == 11, {
		~mratioH = msg[3].linlin(0.01, 0.01, 2.0, 0.1);
	});
}, '/tr', s.addr);

OSCdef(\ampampH, { arg msg;
	if(msg[2] == 11, {
		~mindexH = msg[3].linlin(0.01, 0.01, 1, 10);
	});
}, '/tr', s.addr);

OSCdef(\timenowH, { arg msg, time;
	if(msg[2] == 8,{
	"start clock".postln;
	SystemClock.sched(0.0,{ arg time;
	~startH = time;

});
	});
},'/tr', s.addr);



OSCdef(\timeH, { arg msg, time;
	if(msg[2] == 9,{
	"time".postln;
	SystemClock.sched(0.0,{ arg time;
    ~stopH = time;
	~repeathappy = (~stopH - ~startH).round(1);
	~patthappy.(~repeathappy;);
});
	});
},'/tr', s.addr);



Ndef(\startstopH, {
	arg thresh = 0;
	var in, chain, freq, hasFreq, sig, amp, trig, amp2, sig2, timetrig, start, stop;

	in = SoundIn.ar(0) * 5;
	in = HPF.ar(in, 500);

	chain = FFT(LocalBuf(2048), in);
	chain = PV_MagAbove(chain, 20);
	sig = IFFT(chain);

	amp = Amplitude.kr(sig).lag(2);
	amp = amp.abs;

	stop = amp < 0.001;
	start = amp > 0.001;

	SendTrig.kr(start, 8, 1);
	SendTrig.kr(stop, 9, 1);

});
)





