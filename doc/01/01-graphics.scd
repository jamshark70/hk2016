// exponential vs. linear
(
var showSpec = { |spec|
	var view = View(),
	diff, ratio, semitones, rangeSl, graph,
	range = [0.45, 0.55],
	plotY = 1.0 - normalize(spec.map((0 .. 99) / 99), 0, 1);

	view.layout = VLayout(
		HLayout(
			StaticText().string_("Diff:").fixedWidth_(60),
			diff = StaticText().fixedHeight_(20),
			StaticText().string_("Ratio:").fixedWidth_(60),
			ratio = StaticText().fixedHeight_(20),
			StaticText().string_("Semitones:").fixedWidth_(80),
			semitones = StaticText().fixedHeight_(20)
		).margins_(2).spacing_(2),
		rangeSl = RangeSlider().orientation_(\horizontal).fixedHeight_(20),
		graph = UserView()
	).margins_(2).spacing_(2);

	graph.drawFunc_({ |view|
		var extent = view.bounds.extent,
		xScale = extent.x / plotY.size,
		yScale = extent.y,
		size = plotY.size;
		Pen.moveTo(Point(0, plotY[0] * yScale));
		(1 .. plotY.size-1).do { |i|
			Pen.lineTo(Point(i * xScale, plotY[i] * yScale))
		};
		Pen.stroke;
		range.do { |x|
			Pen.moveTo(Point(x * size * xScale, extent.y))
			.lineTo(Point(x * size * xScale, plotY.blendAt(x * size) * extent.y))
			.stroke;
			Pen.fillOval(
				Rect.aboutPoint(
					Point(x * size * xScale, plotY.blendAt(x * size) * extent.y),
					2, 2
				)
			)
		};
	});

	rangeSl.action_({ |view|
		var y;
		range = [view.lo, view.hi];
		y = spec.map(range);
		diff.string = (y[1] - y[0]).round(0.001);
		ratio.string = (y[1] / y[0]).round(0.001);
		semitones.string = (y[1] / y[0]).ratiomidi.round(0.001);
		graph.refresh;
	})
	.setSpan(*range);

	view
},
w = Window("Specs", Rect.aboutPoint(Window.screenBounds.center, Window.screenBounds.width * 0.5, 300)),
l;

w.view.layout = l = HLayout();
[[20, 20000, \lin], [20, 20000, \exp]].do { |spec|
	var view = showSpec.(spec.asSpec);
	l.add(view);
};

w.front;
)


// curve warp
(
var w = Window("Curve", Rect.aboutPoint(Window.screenBounds.center, 400, 300)),
curveSl, curveText, plot, curve = 0, x = (0 .. 99) / 99;

w.view.layout = VLayout(
	HLayout(
		StaticText().string_("Curve:").fixedWidth_(80),
		curveText = StaticText().string_("0").fixedWidth_(80),
		curveSl = Slider().orientation_(\horizontal)
	),
	plot = MultiSliderView()
);

curveSl.action_({ |view|
	var curve = view.value * 16 - 8;
	plot.value = ControlSpec(0, 1, curve).map(x);
	curveText.string = curve.round(0.001).asString;
}).value_(0.5);

plot.drawRects_(false).drawLines_(true).size_(x.size).elasticMode_(true);
plot.value = x;

w.front;
)


// audio trigger demo
// watch peak levels

PeakMonitor(Bus(\audio, 2, 1, s));

// -20.dbamp == 0.1

Ndef(\trig, { |thresh = 0.1|
	var sig = SoundIn.ar(0),
	amp = Amplitude.kr(sig, 0.01, 0.1),
	trig = amp > thresh;
	amp.poll(amp > thresh);
	trig
});

g = GenericGlobalControl(\thresh, nil, 0.1, [0, 0.5]);
g.gui;
Ndef(\trig).set(\thresh, g.asMap);

g.free;
Ndef(\trig).clear;



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
