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


// fader4's spec is wrong??
BP(\mwtouch).listVars
BP(\mwtouch).tabSpecs[1].indexOf('/1/fader4')
BP(\mwtouch).tabSpecs[1][23]
BP.keys

BP(\mwtouchGui).listVars
BP(\mwtouchGui).views['/1/fader4']


// testing wrapper
BP(\mw).free;
PR(\mobileWorkshopGUI) => BP(\mw);

BP(\mw).listVars;
BP(\mw).oscMapMgr.listVars
BP(\mw).oscMapMgr.view.children
BP(\mw).oscMapMgr.view.canvas.children

p = BP(\mw);
p.window.view.children;
p.window.view.children[0].children;
p.window.view.children[0].children.last.children;
p.window.view.children[0].children.last

p.window.view.children[0].children.last.canvas.children;

a = p.window.view.children[0].children.last.children;
a.collect(_.bounds)

p.window.view.children[0].children.last.canvas.children;
p.window.view.children[0].children.last.canvas.children[0].children;
p.window.view.children[0].children.last.canvas.children.last.children;


p.window.view.children[0].children.last.children[0].children;
p.window.view.children[0].children.last.children[2].children;


NotificationCenter.registrations // removed all dependencies

// test mapping
Ndef(\a).clear;
Ndef(\a, { |freq = 440, fmul = 1.5| SinOsc.ar(freq * [1, fmul], 0, 0.1) });
Ndef(\a).addSpec(\fmul, [1, 2, \exp]);
Ndef(\a).play;
Ndef(\a).stop;

Ndef(\a).addSpec(\freq, #[100, 800, \exp]);
Ndef(\a).getSpec(\freq)

Ndef(\a).getSpec(\fmul)

Halo.at(Ndef(\a))

Ndef.all[\localhost].envir.keys
BP(\mw).oscMapMgr.space.envir.keys == BP(\mw).oscMapMgr.prevProxyKeys

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

g.deleteButton.states_([["X", Color.black, Color.red(0.6)]]);

g.listVars
g.view.children

z.refresh
z.view.children

m.free;

g.free;


// can't believe this... a lower view is displaying above a higher view...?
// but I can't reproduce it in a simple case...
w = Window("scroll layout", Rect(800, 200, 500, 400)).front;
v = ScrollView(w, w.view.bounds);
v.canvas = View();
v.canvas.layout = l = VLayout();
l.add(PopUpMenu().items_(["no matter"]));
w.front;

l.insert(m = View().layout_(HLayout()), v.children.size - 1);

m.layout.add(StaticText().string_("hi, I'm here"));


PR(\abstractScrollParent).listMethods;

w = Window("scroll layout", Rect(800, 200, 500, 400)).front;
p = PR(\abstractScrollParent).copy.prep(w, nil, w.view.bounds.insetBy(2, 2));
w.view.children;
p.view.children;  // a View = spacer
p.addView(Button().states_([["oh hai"]]));
p.view.children;
p.addView(Button().states_([["from da udder side"]]));

w = Window("scroll layout", Rect(800, 200, 500, 400)).front;
p = PR(\abstractScrollParent).copy.prep(w, nil, w.view.bounds.insetBy(2, 2));
w.view.children;
p.view.children;  // a View = spacer
p.insertView(
	Button().states_([["oh hai"]]).action_({
		p.addView(Button().states_([["from da udder side"]]));
	}),
	0
);
p.view.children;
p.insertView(Button().states_([["from da udder side"]]), 0);

VLayout.browse;
p.layout.children

w = Window("layout", Rect(800, 200, 500, 400)).front;
w.view.layout = l = VLayout(StaticText().string_("first"));
l.insert(StaticText().string_("second"), 0);
l.insert(StaticText().string_("third"), 1);
l.insert(StaticText().string_("fourth"), 1);
w.view.children.collect(_.string);



p = ProxySpace.new.push;
~a = { Silent.ar(1) };
p.envir.keys

~a.clear;
p.envir.keys


// structural changes of NP on clear, end, free
// end and free do not destroy the structure; so, keep them in the GUI
Ndef(\a, { |abc = 1| Silent.ar(1) });
[Ndef(\a).isPlaying, Ndef(\a).rate, Ndef(\a).numChannels, Ndef(\a).nodeMap]

Ndef(\a).clear;
[Ndef(\a).isPlaying, Ndef(\a).rate, Ndef(\a).numChannels, Ndef(\a).nodeMap]  // scalar, nil, empty node map

Ndef(\a).end;
[Ndef(\a).isPlaying, Ndef(\a).rate, Ndef(\a).numChannels, Ndef(\a).nodeMap]  // audio, 1, full map

Ndef(\a).free;
[Ndef(\a).isPlaying, Ndef(\a).rate, Ndef(\a).numChannels, Ndef(\a).nodeMap]  // audio, 1, full map

Ndef(\a).set(\abc, 2);


// not freeing on window close?
w = Window(\test, Rect(800, 200, 200, 150)).front;
w.view.layout = VLayout(
	View().background_(Color.gray(0.5)).onClose_({ "closed".postln })
);



// check dependencies
BP(\mw).oscMapMgr.maps[0].map.listVars
Object.dependantsDictionary.detect { |obj| obj.debug === BP(\mw).oscMapMgr.maps[0].map };
Ndef(\a).dependants.select(_.isKindOf(Proto)).do(_.listVars)

p = Ndef(\a).proxyspace;
Ndef(\a).free;
p
Ndef(\a).clear;

Ndef(\a, { |freq = 440, fmul = 1.5, amp = 0.1| SinOsc.ar(freq * [1, fmul], 0, amp) });
Ndef(\a).addSpec(\fmul, [1, 2, \exp]);

Ndef(\a).proxyspace.clear;


// keys not found?
BP(\mw).oscMapMgr.listVars


// xy
NotificationCenter.register(BP(\mwtouch).v, '/1/xy', \tester, { |... args| args.postln });
NotificationCenter.unregister(BP(\mwtouch).v, '/1/xy', \tester);

BP(\mw).oscMapMgr.listVars
BP(\mw).oscMapMgr.maps[0].map.listVars

BP(\mw).oscMapMgr.maps[0][\gui].listVars
BP(\mw).oscMapMgr.maps[0][\gui].paramMenu.value

NotificationCenter.registrations

Ndef(\a, { |freq = 440, trigRate = 5, amp = 0.1|
	var eg = EnvGen.kr(
		Env.perc(0.01, trigRate.reciprocal),
		Impulse.kr(trigRate)
	),
	sig = SinOsc.ar(freq) * eg * amp;
	sig.dup
});
Ndef(\a).addSpec(\trigRate, [2, 18, \exp]);
Ndef(\a).play;
Ndef(\a).stop;


// accxyz
NotificationCenter.register(BP(\mwtouch).v, '/accxyz', \tester, { |... args| args.postln });
NotificationCenter.unregister(BP(\mwtouch).v, '/accxyz', \tester);

BP(\xyz).free;
PR(\accxyzSmoother).chuck(BP(\xyz), nil, (sourceBP: \mwtouch));

BP(\xyz).listVars

NotificationCenter.register(BP(\xyz).v, '/accxyz', \tester, { |... args| args.postln });
NotificationCenter.unregister(BP(\xyz).v, '/accxyz', \tester);
