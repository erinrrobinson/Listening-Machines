//SAD ROBOT

// CREATE BUFFER

(
s = Server.local;
b = Buffer.alloc(s, 44100 * 10.0, 1);

~startS = 0;
~stopS = 4.0;


SynthDef.new(\sadrobot, {
	arg atk = 1, sus = 1, rel = 1, wobbleamount = 10, wobblespeed = 100, amp = 1, pitch = 1000, shift = 0, lowpitch=3, strength=3, strength2=1, out=0;
	var freq, env, sig, sig1, sig2;
	freq = LFNoise1.kr(wobblespeed, wobbleamount, pitch);
	sig1 = SinOsc.ar(freq/lowpitch, mul:strength2).distort;
	sig2 = LFTri.ar((freq), mul:strength).distort;
	sig = Mix.ar([ sig1, sig2 ]);
	sig = FreqShift.ar(sig, shift);
	env = EnvGen.kr(Env.linen(atk, sus, rel), doneAction:2);
	sig = HPF.ar(sig, 500);
	sig = FreeVerb.ar(sig, 0.5, 0.5, 0.8);
	sig = sig * env;
	sig = sig * amp;
	Out.ar(out, sig);
}).add;

~pattsad = {arg repeat = ~repeatS;
~sad = Pdef(\sadrobots, Pbind(
	\instrument, \sadrobot,
	\dur, Pexprand((Pfunc{~durS}/3), (Pfunc{~durS} * 1.5), (repeat * [2, 3].choose)),
	\atk, Pexprand(0.05, 0.2),
	\sus, Pexprand((Pkey(\dur) * 0.3), (Pkey(\dur) * 0.8)),
	\rel, Pexprand(0.1, 0.3),
	\strength, Pexprand(1.0, 3.0),
	\strenth2, Pexprand(1.0, 4.0),
	\wobbleamount, Pexprand(40, 200),
	\wobblespeed, Pexprand((Pfunc{~wobbleS}/2), (Pfunc{~wobbleS} * 2)),
	\lowpitch, Pexprand(4.0, 5.0),
	\pitch, Pexprand(Pfunc{~freqsS} * 0.75, (Pfunc{~freqsS} * 1.5)),
	\shift, Pexprand(Pfunc{~shiftyS}, (Pfunc{~shiftyS} * 0.75)),
	\amp, Pexprand(0.2, 0.3),
);
);

	Ndef(\sadrobot1, ~sad);
};



SynthDef(\recbufS, { arg out = 0, bufnum = 0, run=1;
	RecordBuf.ar(SoundIn.ar(0), bufnum, run, loop:0, doneAction:2);
}).add;

SynthDef(\amplpfS, {var sig, amp, env;
	sig = PlayBuf.ar(1, b, doneAction:2, loop:0, startPos:2000);
	sig = DelayL.ar(sig, 0.05, 0.05);
	env = EnvGen.kr(Env.linen(0.01, (~stopS - ~startS), 0.01), doneAction:2);
	sig = sig * env;
	amp = Amplitude.kr(sig);
	amp = amp.lag(3);
	SendTrig.kr(Impulse.kr(10), 3, amp);
}).add;



OSCdef(\startstopS, { arg msg, time;
	if(msg[2] == 0,{
	"start rec".postln;
	a = Synth(\recbufS, [\bufnum, b]);});

	if(msg[2] == 1,{
	"stop rec".postln;
		Synth(\amplpfS);
	a.set(\run,0);
	});
},'/tr', s.addr);

OSCdef(\amplowS, { arg msg;
	if(msg[2] == 3, {
		~freqsS = msg[3].linlin(0.001, 0.01, 1000, 2500);
	});
}, '/tr', s.addr);

OSCdef(\ampshiftS, { arg msg;
	if(msg[2] == 3, {
		~shiftyS = msg[3].linlin(0.001, 0.01, 20, 1000);
	});
}, '/tr', s.addr);

OSCdef(\ampatkS, { arg msg;
	if(msg[2] == 3, {
		~wobbleS = msg[3].linlin(0.001, 0.01, 10, 30);
	});
}, '/tr', s.addr);

OSCdef(\ampampS, { arg msg;
	if(msg[2] == 3, {
		~durS = msg[3].linlin(0.001, 0.01, 1.0, 0.5);
	});
}, '/tr', s.addr);

OSCdef(\timenowS, { arg msg, time;
	if(msg[2] == 0,{
	"start clock".postln;
	SystemClock.sched(0.0,{ arg time;
	~startS = time;

});
	});
},'/tr', s.addr);

OSCdef(\timeS, { arg msg, time;
	if(msg[2] == 1,{
	"time".postln;
	SystemClock.sched(0.0,{ arg time;
    ~stopS = time;
	~repeatS = (~stopS - ~startS).round(1);
	~pattsad.(~repeatS;);
});
	});
},'/tr', s.addr);



Ndef(\startstopS, {
	arg thresh = 0;
	var in, chain, freq, hasFreq, sig, amp, trig, amp2, sig2, timetrig, start, stop;

	in = SoundIn.ar(2) * 4.0;
	in = LPF.ar(in, 1000);
	in = HPF.ar(in, 400);

	chain = FFT(LocalBuf(2048), in);
	chain = PV_MagAbove(chain, 20);
	sig = IFFT(chain);

	amp = Amplitude.kr(sig).lag(1);
	amp = amp.abs;
	//amp.poll;
	stop = amp < 0.001;
	start = amp > 0.001;

	SendTrig.kr(start, 0, 1);
	SendTrig.kr(stop, 1, 1);
	DelayL.kr(SendTrig.kr(stop, 2, 1), 1.0, 1.0);

});
)







