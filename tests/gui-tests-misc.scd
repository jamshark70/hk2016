w.view.children

// layout + FlowLayout?
w = Window("layouts", Rect(800, 200, 500, 400)).front;
w.layout = VLayout(
	HLayout(
		StaticText().background_(Color.rand(0.1, 0.3)),
		StaticText().background_(Color.rand(0.1, 0.3))
	),
	v = View().background_(Color.rand(0.1, 0.3))
);

f = v.addFlowLayout;
t = StaticText(v, 150@20).string_("xiao gou").background_(Color.rand(0.1, 0.3));
u = StaticText(v, 150@20).string_("lao hu").background_(Color.rand(0.1, 0.3));
x = StaticText(v, 150@20).string_("kaixin").background_(Color.rand(0.1, 0.3));
y = StaticText(v, 150@20).string_("xi zao").background_(Color.rand(0.1, 0.3));

// seems OK. FlowLayout-placed objects stay frozen

// composite views with layouts inside? yes
b = { |view| view.background_(Color.rand(0.1, 0.3)) };

w = Window("layouts", Rect(800, 200, 500, 400)).front;
w.layout = VLayout(
	HLayout(
		b.(StaticText()),
		b.(StaticText())
	),
	v = b.(View())
);

v.layout = HLayout(
	b.(StaticText()),
	b.(StaticText()),
	b.(StaticText())
);

w.background = Color.clear;
w.background = Color.gray(0.2);


// scrollview with layout? YEP
w = Window("scroll layout", Rect(800, 200, 500, 400)).front;
v = \randBg.eval(ScrollView(w, w.view.bounds.insetBy(2, 2)));
v.canvas = View();
v.canvas.layout = l = VLayout(View());

{
	30.do { |i|
		var view = \randBg.eval(View())
		.fixedHeight_(22)
		.layout_(HLayout(
			StaticText().string_(i.asString).fixedWidth_(30),
			Button().states_([["click me"]])
			.action_({ |view| "% was clicked\n".postf(i) });
		).margins_(1));
		l.insert(view, v.children.size - 1);
		0.5.wait;
	};
}.fork(AppClock);

v.children.choose.remove;



// testing wrapper
BP(\mw).free;
PR(\mobileWorkshopGUI) => BP(\mw);

NotificationCenter.registrations // removed all dependencies

// test mapping
Ndef(\a).clear;
Ndef(\a, { |freq = 440, fmul = 1.5| SinOsc.ar(freq * [1, fmul], 0, 0.1) });
Ndef(\a).addSpec(\fmul, [1, 2, \exp]);
Ndef(\a).play;
Ndef(\a).stop;

Ndef.all[\localhost].envir.keys
ProxySpace

m = PR(\npMapping).copy.prep;
m.listVars;

m.setTouchIndex(2);
m.setProxyIndex(0);
m.setParamIndex(1);

m.setParamIndex(nil);

m.free;
m.dependants

z = Window("test map", Rect(800, 100, 350, 100)).front;
z.layout = VLayout();

g = PR(\npMappingGui).copy.prep(m, z.layout);

g.listVars
g.view.children

z.refresh
z.view.children

m.free;

g.free;