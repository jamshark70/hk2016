(Quarks.at("ddwProtoLib").localPath +/+ "mobile-objects.scd").loadPath;
(Quarks.at("ddwProtoLib").localPath +/+ "mobile-objects.scd").openDocument;

PR(\mix16Touch).chuck(BP(\touch), nil, (pingDebug: false));
PR(\abstractTouchGUI).chuck(BP(\touchGui), nil, (model: BP(\touch).v));

NetAddr.langPort;

q = ();
p = ProxySpace.new.push;

Dialog.openPanel { |path| q.buf = Buffer.readAndQuery(s, path) };

~out = { \in.ar(0!2) }; ~out.play(vol: 0.25);

p.gui;

~grain.clear;
~grain.set(\bufnum, q.buf);
~grain.addSpec(\tfreq, #[1, 50, \exp], \overlap, #[0.5, 10, \exp], \rate, [0.25, 4, \exp], \pos, [0, 1]);
~grain = { |bufnum, tfreq = 15, overlap = 4, rate = 1, pos = 0.5, pan = 0, amp = 0.1|
	var trig = Impulse.ar(tfreq),
	dur = overlap / tfreq,
	center = pos * BufDur.kr(bufnum);
	TGrains.ar(2, trig, bufnum, rate, center, dur, pan, amp)
};
~grain <>> ~out;

// PR(\abstractTouch): Need one instance per mobile device
// Also, make it easier to access the instance
NotificationCenter.register(BP(\touch).v, '/1/xy', \me, e { |args|
	~grain.set(\pos, args[1], \rate, args[2].linexp(0, 1, 4, 0.25))
});

NotificationCenter.unregister(BP(\touch).v, '/1/xy', \me);

NotificationCenter.register(BP(\touch).v, '/1/toggle1', \me, e { |args|
	if(args[1] == 0) { ~out.stop } { ~out.play };
});

NotificationCenter.unregister(BP(\touch).v, '/1/xy', \me);
NotificationCenter.unregister(BP(\touch).v, '/1/toggle1', \me);

~grain.trace
q.buf.duration


// proxy introspection
Ndef(\a, { |freq = 440| Silent.ar(1) });
Ndef(\a)
Ndef.browse
NdefParamGui
Ndef(\a).getKeysValues
Ndef(\a).clear;