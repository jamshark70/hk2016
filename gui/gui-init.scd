if(PR.exists(\abstractTouch).not) {
	(Quarks.at("ddwProtoLib").localPath +/+ "mobile-objects.scd").loadPath;
};

// color theme (dark):
Library.put(\workshopGuiTheme, (
	windowBG: nil, // Color.clear,
	containerBG: Color.gray(0.2),
));

{ |view| view.background_(Color.rand(0.1, 0.6)) } => Func(\randBg);


/***** GUI: OSC section *****/

/*
		touchExtent = PR(\abstractTouchGUI).calcExtent(BP(\touch).v);
		w = Window("control panel",
			Rect(sBounds.width - touchExtent.x, 0, touchExtent.x, sBounds.height)
		);
		lay = VLayout(
			touchParent = View().fixedSize_(touchExtent + Point(-4, 4)),

		PR(\abstractTouchGUI).chuck(BP(\touchGui), nil, (
			model: BP(\touch).v,
			parentView: touchParent
		));

*/

Proto {
	~iMadeTouch = false;

	~prep = { |parentView, name|
		var touchExtent;

		~touchName = (name ++ "touch").asSymbol;
		~touchGuiName = (name ++ "touchGui").asSymbol;
		if(BP.exists(~touchGuiName)) { BP(~touchGuiName).free };

		if(BP.exists(~touchName).not) {
			PR(\mix16Touch).chuck(BP(~touchName), nil, (pingDebug: false));
			~iMadeTouch = true;
		};

		touchExtent = PR(\abstractTouchGUI).calcExtent(BP(~touchName).v);
		~parentView = parentView ?? { View() };

		~wrappedLayout = HLayout(
			\randBg.eval(View()),  // padding, to center the whole VLayout horizontally
			~layout = VLayout(
				HLayout(
					StaticText().string_("Local:").align_(\right).fixedSize_(Size(70, 20)),
					~localIpView = StaticText().fixedHeight_(20),
				),
				HLayout(
					StaticText().string_("Remote:").align_(\right).fixedSize_(Size(70, 20)),
					~remoteIpView = StaticText().fixedHeight_(20)
				),
				~touchParent = View().fixedSize_(touchExtent + Point(-4, 4)),
				// other views?
			),
			\randBg.eval(View()),
		);
		PR(\abstractTouchGUI).chuck(BP(~touchGuiName), nil, (
			model: BP(~touchName).v,
			parentView: ~touchParent
		));
		~parentView.layout = ~wrappedLayout;

		~getLocalIP.();  // async, assumes unixy
		~setRemoteIPResp.();

		currentEnvironment
	};
	~free = {
		~freeRemoteIPResp.();
		BP(~touchGuiName).free;
		if(~iMadeTouch) { BP(~touchName).free };
		// remove other views?
	};
	~freeCleanup = { ~free.() };

	// async, assumes unixy
	~getLocalIP = {
		if(thisProcess.platform.name != \windows) {
			~getStdOutAsync.("ifconfig", e { |stdout|
				var line = stdout.split($\n).detect { |line|
					line.contains("192.168");
				}, match;
				if(line.notNil and: {
					match = line.findRegexp("[0-9]+\\.[0-9]+\\.[0-9]+\\.[0-9]+");
					match.notEmpty
				}) {
					defer(e { ~localIpView.string = match[0][1] ++ ":" ++ NetAddr.langPort });
				} {
					"Failed to get local IP".warn;
				};
			});
		} {
			"getLocalIP not supported in Windows yet.".warn;
		};
	};

	~setRemoteIPResp = {
		NotificationCenter.register(BP(~touchName).v, '/ping', ~touchName, e { |msg, time, replyAddr|
			defer(e {
				~remoteIpView.string = replyAddr.ip ++ ":" ++ BP(~touchName).sendPort;
			});
		});
	};
	~freeRemoteIPResp = {
		NotificationCenter.unregister(BP(~touchName).v, '/ping', ~touchName);
	};

	~getStdOutAsync = { |cmd, func|
		var temp = PathName.tmp +/+ Date.getDate.stamp,
		file, output;
		(cmd ++ " >" ++ temp).unixCmd({ |exitCode|
			file = File(temp, "r");
			if(file.isOpen) {
				protect {
					output = file.readAllString;
				} { file.close };
				func.value(output, exitCode);
			} {
				func.("", 0x7FFFFFFF);
			};
			File.delete(temp);
		}, postOutput: false);
	};
} => PR(\touchManager);



/***** GUI: OSC mapping section *****/

// mapping objects
// Proto {
// } => PR(\abstractMapping);

Proto {
	~height = 22;
	~margins = [4, 1];
	~spacing = 4;

	~prep = { |model, layout, addToLayout(true)|
		~model = model;
		~addResponder.();
		~makeContainer.(layout);
		~makeViews.(~layout);
		if(addToLayout) { layout.add(~view) };
		~view.onClose = e { ~free.() };
		currentEnvironment
	};
	~free = {
		~view.onClose = nil;  // avoid recursion
		~view.remove;
		~removeResponder.();
	};
	~addResponder = {
		~model.addDependant(currentEnvironment);
	};
	~removeResponder = {
		~model.removeDependant(currentEnvironment);
	};
	// concrete subclasses should implement their own ~update method

	~makeContainer = {
		~view = ~setSize.(View());
		~layout = ~makeLayout.(~view);
		~view
	};
	~setSize = { |view|
		view.fixedHeight_(~height);
		view
	};
	~makeLayout = { |view|
		view.layout = HLayout().margins_(~margins).spacing_(~spacing);
		view.layout
	};
} => PR(\abstractMappingGui);

// NP parameter
Proto {
	~touch = \mwtouch;  // replace
	// ~space = Ndef.all[\localhost];
	~spec = #[0, 1].asSpec;

	~prep = { |touchKey, proxySpace|
		if(touchKey.notNil) { ~touch = touchKey };
		if(proxySpace.notNil) {
			~space = proxySpace
		} {
			if(~space.isNil) { ~space = Ndef.all[\localhost] ?? { ProxySpace.new } };
		};
		~getIDs.();
		currentEnvironment
	};
	~free = {
		~clearDependant.();
		~unregister.();
		currentEnvironment.changed(\didFree);
	};

	~unregister = {
		~resp.remove;  // osc responses
		BP(~touch).setValue(~touchKey, 0);
		currentEnvironment
	};

	~register = {
		var proxy, value;
		~resp.remove;
		if(~touchKey.notNil and: { ~proxyKey.notNil and: { ~paramKey.notNil } }) {
			proxy = ~space[~proxyKey];
			if(proxy.notNil) {
				~resp = NotificationCenter.register(BP(~touch).v, ~touchKey, UniqueID.next, e { |args|
					proxy.set(~paramKey, ~spec.map(args[1]));
				});
				value = ~getParamValue.(proxy);
				if(value.notNil) {
					BP(~touch).setValue(~touchKey, ~spec.unmap(value));
				} {
					BP(~touch).setValue(~touchKey, 0);
				};
			};
		};
		currentEnvironment
	};
	~setDependant = {
		if(~proxyKey.notNil and: { ~space[~proxyKey].notNil }) {
			~space[~proxyKey].addDependant(currentEnvironment)
		};
		currentEnvironment
	};
	~clearDependant = {
		if(~proxyKey.notNil and: { ~space[~proxyKey].notNil }) {
			~space[~proxyKey].removeDependant(currentEnvironment)
		};
		currentEnvironment
	};


	~getParamValue = {
		var proxy, pairs;
		proxy = ~space[~proxyKey];
		if(proxy.notNil) {
			if(proxy.nodeMap[~paramKey].notNil) {
				proxy.nodeMap[~paramKey]
			} {
				pairs = proxy.getKeysValues;
				pairs = pairs.detect { |pair| pair[0] == ~paramKey };
				if(pairs.notNil) { pairs[1] } { nil }
			}
		};
	};
	~getProxy = {
		if(~proxyKey.notNil) {
			~space[~proxyKey]
		};  // else nil
	};

	~getIDs = {
		">> getIDs".debug;
		~touchKeys = BP(~touch).saveKeys.as(Array).sort;
		~setProxyKeys.(~space.envir.keys.as(Array).sort);
		~getParams.();
		"<< getIDs".debug;
		// ~setProxyIndex.(0);
		// ~setTouchIndex.(0);
	};
	~setProxyKeys = { |keys|
		~proxyKeys = keys;
		currentEnvironment.changed(\proxyKeys, keys.debug("proxyKeys notification"));
	};

	~setTouchIndex = { |i|
		if(i.notNil) {
			if(~touchKeys[i].notNil) {
				~unregister.();
				~touchKey = ~touchKeys[i];
				~register.();
				currentEnvironment.changed(\touchKey, i);
			} {
				"No touchKey for %".format(i).warn;
			};
		} {
			~unregister.();
			~touchKey = nil;
			currentEnvironment.changed(\touchKey, nil);
		};
		currentEnvironment
	};

	~setProxyIndex = { |i|
		var oldKey = ~proxyKey;
		if(i.notNil) {
			if(~proxyKeys[i].notNil) {
				~clearDependant.();
				~proxyKey = ~proxyKeys[i];
				currentEnvironment.changed(\proxyKey, i);
				if(oldKey != ~proxyKey) {
					~setDependant.();
					~getParams.();
					~setParamIndex.(nil);
				} /*{
				??? -- maybe nothing?
				}*/;
			} {
				"No proxy for %".format(i).warn;
			};
		} {
			~clearDependant.();
			~unregister.();
			~proxyKey = nil;
			currentEnvironment.changed(\proxyKey, nil);
		};
		currentEnvironment
	};

	~getParams = {
		var proxy;
		if(~proxyKey.notNil) {
			proxy = ~space[~proxyKey];
			if(proxy.notNil) {
				~paramKeys = proxy.getKeysValues.collect(_[0]);
			} {
				~paramKeys = [];
			};
			currentEnvironment.changed(\paramKeys, ~paramKeys);
		} {
			currentEnvironment.changed(\paramKeys, []);
		};
		~params
	};

	~setParamIndex = { |i|
		var oldKey = ~paramKey;
		if(i.notNil) {
			if(~paramKeys[i].notNil) {
				~paramKey = ~paramKeys[i];
				currentEnvironment.changed(\paramKey, i);
				if(oldKey != ~paramKey) {
					~spec = ~space[~proxyKey].getSpec(~paramKey);
					~register.();  // update GUI value
				} /*{
				??? -- maybe nothing?
				}*/;
			} {
				if(~paramKeys.size > 0) { "No param for %".format(i).warn };
			}
		} {
			~unregister.();
			~paramKey = nil;
			currentEnvironment.changed(\paramKey, nil);
		};
		currentEnvironment
	};

	// respond to Ndef updates
	~update = { |obj, what, args|  // NodeProxy .changed sends arrays of args
		[obj, what, args].debug(">> npMapping update");
		case
		{ what == \source } {
			// [obj, index, channelOffset, extraArgs, now]
			~getParams.();  // this could add new parameters
		};
		[obj, what, args].debug("<< npMapping update");
		currentEnvironment
	};
} => PR(\npMapping);

PR(\abstractMappingGui).clone {
	~makeViews = { |layout|
		layout.add(~touchMenu = PopUpMenu());
		layout.add(~proxyMenu = PopUpMenu());
		layout.add(~paramMenu = PopUpMenu());
		layout.add(~deleteButton = Button());

		~touchKeys = ~model.touchKeys ++ ["none"];
		~touchMenu.items_(~touchKeys)
		.action_(e { |view|
			if(view.value == (~touchKeys.size - 1)) {
				~model.setTouchIndex(nil)
			} {
				~model.setTouchIndex(view.value)
			};
		})
		.value_(~indexForItem.(~touchKeys, ~model.touchKey));

		~proxyKeys = ["none"];
		~proxyMenu.items_(~proxyKeys)
		.action_(e { |view|
			if(view.value == (~proxyKeys.size - 1)) {
				~model.setProxyIndex(nil)
			} {
				~model.setProxyIndex(view.value)
			};
		});

		~paramKeys = ["none"];
		~paramMenu.items_(~paramKeys)
		.action_(e { |view|
			if(view.value == (~paramKeys.size - 1)) {
				~model.setParamIndex(nil)
			} {
				~model.setParamIndex(view.value)
			};
		});

		~model.getIDs;
		~proxyMenu.value_(~indexForItem.(~proxyKeys, ~model.proxyKey));
		~paramMenu.value_(~indexForItem.(~paramKeys, ~model.paramKey));

		~deleteButton.fixedSize_(Size(20, 20))
		.states_([["X", Color.black, Color.red(0.6)]])
		.action_(e { ~model.free });
	};

	~indexForItem = { |items, value|
		value = value.asString;
		items.detectIndex { |item| item.asString == value }
		?? { items.size - 1 }
	};

	~update = { |obj, what ... args|
		var oldItem;
		[obj, what, args].debug(">> update");
		switch(what)
		{ \didFree } {
			~removeResponder.();
			defer(e { ~view.remove });
		}
		{ \touchKey } {
			defer(e { ~touchMenu.value = args[0] ?? { ~touchKeys.size - 1 } });
		}
		{ \proxyKeys } {
			defer(e {
				oldItem = ~proxyMenu.items[~proxyMenu.value];
				~proxyKeys = args[0] ++ ["none"];
				~proxyMenu.items = ~proxyKeys;
				~proxyMenu.value = ~indexForItem.(~proxyKeys, oldItem);
			})
		}
		{ \proxyKey } {
			defer(e { ~proxyMenu.value = args[0] ?? { ~proxyKeys.size - 1 } });
		}
		{ \paramKeys } {
			defer(e {
				oldItem = ~paramMenu.items[~paramMenu.value];
				~paramKeys = args[0] ++ ["none"];
				~paramMenu.items = ~paramKeys;
				~paramMenu.value = ~indexForItem.(~paramKeys, oldItem);
			})
		}
		{ \paramKey } {
			defer(e { ~paramMenu.value = args[0] ?? { ~paramKeys.size - 1 } });
		};
		[obj, what, args].debug("<< update");
	};
} => PR(\npMappingGui);



// mapping editor
Proto {
	~prep = { |parent, layout, bounds|
		~parentView = parent;
		if(layout.notNil) {
			layout.add(~scrollView = ScrollView());
		} {
			~scrollView = ScrollView(parent, bounds);
		};
		\randBg.eval(~scrollView);
		~view = View();
		\randBg.eval(~view);
		~scrollView.canvas = ~view;
		~layout = ~makeLayout.(~view);
		if(~layout.isKindOf(LineLayout)) {
			~layout.add(View());  // stretchable spacer
			~hasSpacer = true;
		} {
			~hasSpacer = false;
		};
		~makeViews.();
		~userprep.();
		currentEnvironment
	};

	~makeLayout = { |view|
		view.layout = VLayout();
		view.layout
	};

	~addView = { |view, stretch(0), align|
		if(~hasSpacer) {
			~layout.insert(view, ~view.children.size - 1, stretch, align);
		} {
			~layout.add(view, stretch, align);
		};
		currentEnvironment
	};

	~insertView = { |view, index, stretch(0), align|
		~layout.insert(view, index, stretch, align);
	};

	~removeView = { |view|
		// don't remove another parent's view
		if(~parentView.children.includes(view)) { view.remove };
	};
} => PR(\abstractScrollParent);

PR(\abstractScrollParent).clone {
	~userprep = {
		// each item is [model, gui]
		~maps = Array.new;
	};

	~makeViews = {
		~addView.(~addButton = PopUpMenu());

		~addButton.fixedSize_(Size(150, 20))
		.items_(["Add OSC mapping", "-- to Ndef param", "-- to Pdefn", "-- function"])
		.action_(e { |view|
			var map, gui;
			switch(view.value)
			{ 1 } {
				map = PR(\npMapping).copy.prep;
				gui = PR(\npMappingGui).copy.prep(map, ~layout, false);  // don't add to layout!
				~addView.(gui.view);
				~maps = ~maps.add((map: map, gui: gui, spec: nil.asSpec));
				map.addDependant(currentEnvironment);
				view.value = 0;
			}
			{ "Not yet implemented".warn };
		});
	};

	~update = { |obj, what|
		var i;
		if(what == \didFree) {
			i = ~maps.detectIndex { |pair| pair[\map] === obj };
			if(i.notNil) {
				obj.removeDependant(currentEnvironment);
				~maps.removeAt(i);
			};
		};
	};

	// ~checkNewProxies = {
	// 	~maps.do { |map, i|
	// 		var proxy, spec;
	// 		map[\map].getIDs;  // brute force -- maybe optimize later
	// 		if()
	// 		if(proxy.notNil and: { map[\map].paramKey.notNil }) {
	// 			spec = proxy.getSpec(map[\map].paramKey);
	// 			if(map[\spec] != spec) {
	// 				map[\spec] = spec;
	// 				map[\map].register;  // also fixes display -- optimize this later
	// 			};
	// 		};
	// 	};
	// };

	// ~updatePeriod = 1.0;
	// ~startAliveThread = {
	// 	if(~aliveThread.isNil) {
	// 		~aliveThread = Task {
	// 			loop {
	// 				~checkProxies.();
	// 				~updatePeriod.wait;
	// 			}
	// 		}.play(AppClock);
	// 	};
	// 	if(~restartFunc.isNil or: { CmdPeriod.objects.includes(~restartFunc).not }) {
	// 		~restartFunc = e {
	// 			if(~aliveThread.wasStopped) {
	// 				~aliveThread = nil;
	// 				~startAliveThread.();
	// 			};
	// 		};
	// 		CmdPeriod.add(~restartFunc);
	// 	};
	// 	currentEnvironment
	// };
	//
	// ~stopAliveThread = {
	// 	~aliveThread.stop;
	// 	~aliveThread = nil;
	// 	CmdPeriod.remove(~restartFunc);
	// 	~restartFunc = nil;
	// 	currentEnvironment
	// };
} => PR(\touchMapManager);



/***** GUI: Buffer section *****/

// Proto {
//
// } => PR(\bufferManager);



/***** GUI: Pattern section *****/

// Proto {
//
// } => PR(\patternManager);



/***** GUI: Composite *****/

Proto {
	~bounds = { Rect.aboutPoint(Window.screenBounds.center, 400, 300) };

	// init:
	~prep = { |name(~collIndex)|
		if(~window.notNil) { ~window.onClose_(nil).close };
		~bnds = ~bounds.();
		~window = Window(name, ~bnds).background_(Library.at(\workshopGuiTheme, \windowBG));
		~layout = VLayout(*(
			~rows = HLayout(*(
				~oscMgrView = View().background_(Library.at(\workshopGuiTheme, \containerBG));
			))
		));
		~window.layout = ~layout;
		~oscMgr = PR(\touchManager).copy.prep(~oscMgrView, name);
		~oscMapMgr = PR(\touchMapManager).copy.prep(~oscMgrView, ~oscMgr.layout);
		~window.onClose_(e { ~free.() }).front;
		currentEnvironment
	};
	~free = {
		~oscMgr.free; ~oscMgr = nil;
		// free others
		if(~window.isClosed.not) {
			~window.onClose_(nil).close;
		};
		if((~didFreeCleanup ?? { false }).not and: { ~collIndex.notNil }) { BP(~collIndex).free };
	};
	~freeCleanup = {
		~didFreeCleanup = true;
		~free.()
	};

} => PR(\mobileWorkshopGUI);
