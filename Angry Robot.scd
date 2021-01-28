//ANGRY BOT

// CREATE BUFFER

(
~ba = Buffer.alloc(s, 44100 * 10.0, 1);
~startA = 0;
~stopA = 4.0;

SynthDef.new(\angryrobot, {
	arg amp = 0.5, freq=50, atk=0.05, sus=1, rel=0.05, lpf=400, rq=0.5, detune=0.01, amps=1, out=1;
	var sig, oscfreq, env, sig1, sig2, oscfreq2;
	oscfreq = {freq * LFNoise2.kr(0.5).range((0.99 - detune), (1.01 + detune))}!3;
	oscfreq2 = {(freq.midicps - 12) * LFNoise2.kr(0.5).range((0.99 - detune), (1.01 + detune))}!3;
	sig1 = Splay.ar(LFSaw.ar(oscfreq, mul: amp));
	sig2 = Splay.ar(LFSaw.ar(oscfreq, mul: amp));
	sig = Mix.ar([sig1, sig2]);
	//sig = FreeVerb.ar(sig, 0.5, 0.8, 0.6);
	sig = RLPF.ar(sig, lpf, rq);
	env = EnvGen.kr(Env.linen(atk, sus, rel), doneAction:2);
	sig = FreeVerb.ar(sig);
	sig = sig * env;
	sig = sig * amps;
	Out.ar(out, sig);
}).add;

~pattA = {arg repeat=~repeatA.asInteger;
~angry = Pdef(\robot, (Pbind(
	\instrument, \angryrobot,
	\dur, Pexprand(Pfunc{~durA}, (Pfunc{~durA} * 0.25), (repeat * [2.0, 3.0, 4.0, 5.0].choose)),
	\detune, Pexprand(0.01, 0.05),
	\atk, Pexprand((Pfunc{~atkA} /2), Pfunc{~atkA}),
	\rel, 0.01,
	\sus, ((Pkey(\dur) * 0.5)),
	\freq, Pexprand(40.0, 42.0),
	\lpf, Pfunc{~lpfA},
	\rq, Pexprand(0.1, 0.8),
	\amp, 0.3,
	\amps, 1,
);
);
);
	Ndef(\angrybot, ~angry);
};

SynthDef(\recbuf, { arg out = 0, bufnum = 0, run=1;
	RecordBuf.ar(SoundIn.ar(1), bufnum, run, loop:0, doneAction:2);
}).add;

SynthDef(\amplpf, {var sig, amp, env;
	sig = PlayBuf.ar(1, ~ba, doneAction:2, loop:0, startPos:1000);
	sig = DelayL.ar(sig, 0.2, 0.2);
	env = EnvGen.kr(Env.linen(0.01, (~stopA - ~startA), 0.01));
	sig = sig * env;
	amp = Amplitude.kr(sig);
	SendTrig.kr(Impulse.kr(10), 7, amp);
}).add;


OSCdef(\startstop, { arg msg, time;
	if(msg[2] == 4,{
	"start rec".postln;
	a = Synth(\recbuf, [\bufnum, ~ba]);});

	if(msg[2] == 5,{
	"stop rec".postln;
		Synth(\amplpf);
	a.set(\run,0);
	});
},'/tr', s.addr);

OSCdef(\amplow, { arg msg;
	if(msg[2] == 7, {
		~lpfA = msg[3].linlin(0.001, 0.02, 400, 1500);
	});
}, '/tr', s.addr);

OSCdef(\ampatk, { arg msg;
	if(msg[2] == 7, {
		~durA = msg[3].linlin(0.001, 0.01, 0.4, 0.1);
	});
}, '/tr', s.addr);

OSCdef(\ampamp, { arg msg;
	if(msg[2] == 7, {
		~atkA = msg[3].linlin(0.001, 0.01, 0.2, 0.01);
	});
}, '/tr', s.addr);

OSCdef(\timenow, { arg msg, time;
	if(msg[2] == 4,{
	"start clock".postln;
	SystemClock.sched(0.0,{ arg time;
	~startA = time;

});
	});
},'/tr', s.addr);

OSCdef(\time, { arg msg, time;
	if(msg[2] == 5,{
	"time".postln;
	SystemClock.sched(0.0,{ arg time;
    ~stopA = time;
	~repeatA = (~stopA - ~startA).round(1);
	~pattA.(~repeatA;);
});
	});
},'/tr', s.addr);

Ndef(\startstop, {
	arg thresh = 0;
	var in, chain, freq, hasFreq, sig, amp, trig, amp2, sig2, timetrig, start, stop;

	in = SoundIn.ar(1) * 3;
	in = HPF.ar(in, 300);
	chain = FFT(LocalBuf(2048), in);
	chain = PV_MagAbove(chain, 20);
	sig = IFFT(chain);

	amp = Amplitude.kr(sig).lag(1.8);
	amp = amp.abs;

	stop = amp < 0.001;
	start = amp > 0.001;

	SendTrig.kr(start, 4, 1);
	SendTrig.kr(stop, 5, 1);

});
)

