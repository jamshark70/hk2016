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



// testing wrapper
BP(\mw).free;
PR(\mobileWorkshopGUI) => BP(\mw);
BP(\mw).window.close
BP.exists(\mw)
1+1

BP.keys
BP.exists(\mwtouch)
BP(\mwtouch).listVars

PR(\touchManager).v[\freeCleanup].def.dumpByteCodes
BP(\mw).listVars
BP(\mw).oscMgr.listVars
BP(\mw).oscMgr.dump
NotificationCenter.registrations // removed all dependencies