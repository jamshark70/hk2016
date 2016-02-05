// simple synth
s.boot;

Ndef(\sine, { |freq = 440, amp = 0.1|
	SinOsc.ar(freq, 0, amp).dup
});

Ndef(\sine).play;
Ndef(\sine).stop;


// using controls

Ndef(\sine).set(\freq, 220);

Ndef(\randF, {
	LFDNoise1.kr(10).exprange(200, 800)
});

Ndef(\sine).set(\freq, Ndef(\randF));


Ndef.clear;


// grain
f = SoundFile.openRead("/home/dlm/share/SC/sounds/vocal-samples/just-because-you-look-like-me.wav");
f.seek(24700);
f.readData(d = FloatArray.newClear(35700));
f.close;

d.plot;
d = d.as(Array);
e = Array.fill(d.size, 0);
w = Signal.hanningWindow(2048);
e = e.overWrite(d[10000 .. 10000 + 2047] * w, 10000);
e = e.overWrite(d[14000 .. 14000 + 2047] * w, 14000);
e = e.overWrite(d[23000 .. 23000 + 2047] * w, 23000);

[d.size, e.size]

[d, e].flop.flat.plot(numChannels: 2);



// buffers
b = Buffer.read(s, Platform.resourceDir +/+ "sounds/a11wlk01.wav");
b;


// first granular demo
Ndef(\g, { |tfreq = 15, overlap = 4, rate = 1, pos = 0.5|
	var trig = Impulse.ar(tfreq),
	dur = overlap / tfreq;
	GrainBuf.ar(2, trig, dur, b, rate, pos);
});
Ndef(\g).addSpec(
	\tfreq, [4, 50, \exp], \overlap, [1, 8, \exp],
	\rate, [0.125, 8, \exp], \pos, [0, 1]
);

Ndef(\g).gui;

Ndef(\pos, { SinOsc.kr(0.1).range(0, 1) });

Ndef(\pos, { Phasor.kr(0, ControlDur.ir / BufDur.kr(b), 0, 1) });
Ndef(\g).set(\pos, Ndef(\pos));

Ndef(\pos, { |scan = 1|
	Phasor.kr(0, scan * ControlDur.ir / BufDur.kr(b), 0, 1)
});
Ndef(\pos).addSpec(\scan, [0.25, 4, \exp]);
Ndef(\pos).gui;

Ndef.clear;


// impulses
{ [Impulse.ar(400), Dust.ar(1100)] }.plot;


// randomize
Ndef(\g, { |tfreq = 15, overlap = 4, rate = 1, pos = 0.5, rpos = 0, rrate = 1|
	var trig = Impulse.ar(tfreq),
	dur = overlap / tfreq,
	rateRand = TExpRand.ar(rrate.reciprocal, rrate, trig),
	posRand = TRand.ar(rpos.neg, rpos, trig);
	GrainBuf.ar(2, trig, dur, b, rate * rateRand, pos + posRand);
});
Ndef(\g).addSpec(\rpos, [0, 0.1], \rrate, [1, 2.midiratio, \exp]);
