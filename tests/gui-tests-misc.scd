// testing wrapper
BP(\mw).free;
PR(\mobileWorkshopGUI) => BP(\mw);

Ndef(\buf, { |bufnum, amp = 0.1| (PlayBuf.ar(1, bufnum, loop: 1) * amp).dup });


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

Ndef(\a).set(\freq, 200);
Ndef(\a).nodeMap[\trigRate]

// accxyz
NotificationCenter.register(BP(\mwtouch).v, '/accxyz', \tester, { |... args| args.postln });
NotificationCenter.unregister(BP(\mwtouch).v, '/accxyz', \tester);

BP(\xyz).free;
PR(\accxyzSmoother).chuck(BP(\xyz), nil, (sourceBP: \mwtouch));

BP(\xyz).listVars

NotificationCenter.register(BP(\mwxyz).v, '/accxyz', \tester, { |... args| args.postln });
NotificationCenter.unregister(BP(\mwxyz).v, '/accxyz', \tester);


// funcs
NotificationCenter.registrations
BP(\mw).oscMapMgr.maps[0].map.listVars
BP(\mw).oscMapMgr.maps[0].map.listMethods
NotificationCenter.registrationsFor(BP(\mwtouch).v, '/1/toggle1');
NotificationCenter.registrations.at(BP(\mwtouch).v)


// enter
t = TextView(nil, Rect(800, 200, 300, 200)).front;
t.keyDownAction = { |view, char, modifiers, unicode|
	[modifiers, modifiers.isCtrl, unicode].postln;
};
t.enterInterpretsSelection

// doc error?
w = Window("test", Rect(800, 200, 300, 200)).front;
w.view.layout = VLayout(
	t = TextView()
);
t.keyDownAction = { false };
w.view.keyDownAction = { "propagated".postln };

// nope, defaultKeyDownAction doesn't call the C++ end
t.keyDownAction = { |view ... args|
	view.defaultKeyDownAction(*args);
	false
};


Ndef(\pan, { |pan| Pan2.ar(SinOsc.ar(440, 0, 0.1), pan) });
Ndef(\pan).play;
Ndef(\pan).stop;
Ndef(\pan).clear;


// programmating state setting
BP(\mw).oscMapMgr.maps[0].map.listMethods

BP(\mw).oscMapMgr.maps[0].map.restoreState('/1/fader1', \pan, \pan);

BP(\mw).oscMapMgr.maps[1].map.restoreState('/1/toggle1', "{ |value| if(value > 0) { Ndef(\\pan).play } { Ndef(\\pan).stop } }");

BP(\mw).oscMapMgr.maps[0].map.saveState
BP(\mw).oscMapMgr.maps[1].map.saveState

BP(\mw).oscMapMgr.maps.do { |map| map.map.saveState.postln }; ""

{ Ndef(\pan).play }.asCompileString.asCompileString


// buffers
// what if you read a buffer independently?
(
var readCmds = IdentitySet['/b_allocRead', '/b_allocReadChannel', '/b_read', '/b_readChannel'];

OSCdef(\bufWatcher, { |msg, time, addr|
	var server, buf;
	case
	{ readCmds.includes(msg[1]) } {
		server = Server.all.detect { |item| item.addr == addr };
		if(server.notNil) {
			buf = Buffer.cachedBufferAt(server, msg[2]);
			if(buf.notNil) {
				// .copy insulates from the fact that .free clears instance vars
				buf.debug("read completed");
			} { "Buffer number % not found in server %".format(msg[2], server).warn };
		} {
			"/done % received but no Server object found for %".format(msg[1], addr).warn;
		}
	}
	{ msg[1] == '/b_free' } {
		// buffer object is not available here, but OK, don't need it
		[msg[2], Buffer.cachedBufferAt(s, msg[2])].debug("freed");
	};
}, '/done', s.addr);
)

b = Buffer.read(s, Platform.resourceDir +/+ "sounds/a11wlk01.wav");

// test corner case: free+read quickly
// response order is OK
b.free; b = Buffer.read(s, Platform.resourceDir +/+ "sounds/a11wlk01.wav");

OSCdef(\bufWatcher).free;


p = PR(\bufferManager).copy.prep;
p.listVars;

b = Buffer.readAndQuery(s, Platform.resourceDir +/+ "sounds/a11wlk01.wav");
p.listVars;

b.free;
p.listVars;

p.free;


p = PR(\bufferManager).copy.prep;
w = Window("test", Rect(800, 200, 500, 400)).front;
w.view.layout = l = VLayout();
q = PR(\bufferManagerGui).copy.prep(p, l);

b = Buffer.readAndQuery(s, Platform.resourceDir +/+ "sounds/a11wlk01.wav");
b.free;

q.free;
p.free;

s.bufferAllocator.debug

p.dependants
q.bufList.value
p.listVars


// buffers
OSCFunc.allEnabled
Object.dependantsDictionary.keysValuesDo { |key, value|
	if(key.isKindOf(Proto)) { [key, value].postln; key.listVars };
}; ""

b = Buffer.read(s, Platform.resourceDir +/+ "sounds/a11wlk01.wav");

Ndef(\buf, { |bufnum, amp = 0.1| (PlayBuf.ar(1, bufnum, loop: 1) * amp).dup });

Ndef(\buf).play;
Ndef(\buf).stop;

Ndef(\buf).trace;

Ndef(\buf).nodeMap
Ndef(\buf).getKeysValues

Ndef(\buf).clear;

Ndef.all[\localhost].envir.keys
Ndef.all[\localhost][\buf].rate.asCompileString

Ndef(\buf, { |bufnum = 1, amp = 0.1, rate = 1| (PlayBuf.ar(1, bufnum, rate: rate, loop: 1) * amp).dup });
Ndef(\buf).addSpec(\rate, [0.2, 5, \exp]);

Ndef(\buf, { |bufnum, amp = 0.1, rate = 1, scanRate = 1|
	var tRate = 20,
	trig = Impulse.ar(tRate),
	bufdur = max(BufDur.kr(bufnum), 0.01),
	phasor = Phasor.kr(0, scanRate * ControlDur.ir / bufdur, 0, 1) /** bufdur*/,
	dur = 4 / tRate;
	TGrains.ar(2, trig, bufnum, rate, phasor, dur, 0, amp);
	// GrainBuf.ar(2, trig, dur, bufnum, rate, phasor, mul: amp);
});
Ndef(\buf).addSpec(\scanRate, [0.2, 5, \exp]);
Ndef(\buf).trace;

Ndef(\buf).set(\bufnum, 0);
Ndef(\buf).set(\bufnum, 1);

BP(\mw).bufMgr.listVars


PR(\bufferManager).listMethods
PR(\bufferManager).v[\update].postcs

x = Point(0, 0);
x.addHalo(\ann, "annotation");
x.getHalo
Halo.lib
x.clearHalo;
Halo.lib
Halo.lib.keysValuesDo { |k, v| [k, v].postln }; ""
Library.browse
Halo.lib.do { |... args| args.postln }; ""

Halo.lib.dictionary.keysValuesDo { |k, v| [k, v].postln }; ""

BP(\mw).bufMgr.bufs

s.cachedBufferAt(0).free;

// save/load
BP(\mw).bufMgr.maps[0].listVars


// clear all
BP(\mw).bufMgr.bufs
