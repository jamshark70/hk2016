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


// tracing OSC
OSCFunc.trace(true);
OSCFunc.trace(false);


// OSC -> freq
Ndef(\oscil, { |freq = 440|
	VarSaw.ar(freq, 0, 0.3, 0.1).dup
});
Ndef(\oscil).play;

OSCdef(\sl1, { |msg|
	Ndef(\oscil).set(\freq, \freq.asSpec.map(msg[1]))
}, '/1/fader1', NetAddr("192.168.1.100", nil));

Ndef(\oscil, { |freq = 440|
	freq = Lag.kr(freq, 0.1);
	VarSaw.ar(freq, 0, 0.3, 0.1).dup
});

// When you're finished with mobile control:
OSCdef(\sl1).free;
Ndef(\oscil).clear;


// open GUI
PR(\mobileWorkshopGUI) => BP(\mw);

// granular synth
(
Ndef(\drone, { |bufnum, amp = 0.1, tfreq = 20, overlap = 8, pos = 0.5, rate = 1|
	var trig = Impulse.ar(tfreq),
	dur = overlap / tfreq,
	pan = 0;
	GrainBuf.ar(2, trig, dur, bufnum, rate, pos, pan: pan, mul: amp)
});
)

Ndef(\drone).play;
Ndef(\drone).stop;

Ndef(\drone).addSpec(\pos, [0, 1]);

Ndef(\drone).nodeMap;
