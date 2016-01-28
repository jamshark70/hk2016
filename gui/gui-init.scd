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
	~iMadeXyz = false;

	~prep = { |parentView, name|
		var touchExtent;

		~touchName = (name ++ "touch").asSymbol;
		~touchGuiName = (name ++ "touchGui").asSymbol;
		~xyzName = (name ++ "xyz").asSymbol;
		if(BP.exists(~touchGuiName)) { BP(~touchGuiName).free };

		if(BP.exists(~touchName).not) {
			PR(\mix16Touch).chuck(BP(~touchName), nil, (
				tabSpecs: PR(\mix16Touch).v[\tabSpecs].keep(4),
				pingDebug: false
			));
			~iMadeTouch = true;
		};
		if(BP.exists(~xyzName).not) {
			PR(\accxyzSmoother).chuck(BP(~xyzName), nil, (sourceBP: ~touchName));
			~iMadeXyz = true;
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
		if(~iMadeXyz) { BP(~xyzName).free };
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
		~model.free;
		currentEnvironment
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
	~makeViews = { |layout|
		layout.add(~touchMenu = PopUpMenu());
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

		~userMakeViews.(layout);

		layout.add(~deleteButton = Button());
		~deleteButton.fixedSize_(Size(20, 20))
		.states_([["X", Color.black, Color.red(0.6)]])
		.action_(e { ~model.free });

		currentEnvironment
	};

	~setSize = { |view|
		view.fixedHeight_(~height);
		view
	};
	~makeLayout = { |view|
		view.layout = HLayout().margins_(~margins).spacing_(~spacing);
		view.layout
	};

	~indexForItem = { |items, value|
		value = value.asString;
		items.detectIndex { |item| item.asString == value }
		?? { items.size - 1 }
	};

	~update = { |obj, what ... args|
		var oldItem;
		switch(what)
		{ \didFree } {
			~removeResponder.();
			defer(e { ~view.remove });
		}
		{ \touchKey } {
			defer(e { ~touchMenu.value = args[0] ?? { ~touchKeys.size - 1 } });
		};
		~userUpdate.(obj, what, *args);  // always pass down
	};
} => PR(\abstractMappingGui);

// NP parameter
Proto {
	~touch = \mwtouch;  // replace
	~xyzSmoother = \mwxyz;
	~spec = #[0, 1].asSpec;

	~prep = {
		// if(touchKey.notNil) { ~touch = touchKey };
		~multiCache = ~multiCache.deepCopy;
		~getTouchIDs.();
		~userprep.();
		currentEnvironment
	};

	~getTouchIDs = {
		if(~touchKeys.isNil) {
			~touchThings = BP(~touch).saveKeys.as(Array);
			// HACK
			~touchThings.remove('/1/xy');
			~touchThings = ~touchThings
			.add('/1/xy' -> '/1/xy X')
			.add('/1/xy' -> '/1/xy Y')
			.add('/accxyz' -> '/accxyz X')
			.add('/accxyz' -> '/accxyz Y')
			.add('/accxyz' -> '/accxyz Z')
			.sort { |a, b| a.value < b.value };
			~touchKeys = ~touchThings.collect(_.value);
		};
		~touchKeys
	};

	~free = {
		~userfree.();
		~unregister.();
		currentEnvironment.changed(\didFree);
	};

	~unregister = {
		~userUnregister.();
		~resp.remove;  // osc responses
		// this may be invoked during window close, in which case the touch object is already gone
		if(BP.exists(~touch)) {
			~setTouchValue.(0);
		};
		currentEnvironment
	};

	~register = {
		var proxy, value;
		~resp.remove;
		if(~touchKey.notNil and: { ~userCanRegister.() }) {
			if(~touchThing.isKindOf(Association)) {
				~resp = NotificationCenter.register(
					BP(~sourceForPath.(~touchKey)).v, ~touchThing.key, UniqueID.next, e { |args|
						~action.(~unpackers[~touchKey].value(args[1..]));
					}
				);
			} {
				~resp = NotificationCenter.register(
					BP(~touch).v, ~touchKey, UniqueID.next, e { |args|
						~action.(args[1]);
					}
				);
			};
			~userRegister.();
		};
		currentEnvironment
	};
	~userCanRegister = true;

	~setTouchIndex = { |i|
		if(i.notNil) {
			if(~touchKeys[i].notNil) {
				~unregister.();
				~touchThing = ~touchThings[i];
				~touchKey = ~touchKeys[i];
				~register.();
				currentEnvironment.changed(\touchKey, i);
			} {
				"No touchKey for %".format(i).warn;
			};
		} {
			~unregister.();
			~touchThing = nil;
			~touchKey = nil;
			currentEnvironment.changed(\touchKey, nil);
		};
		currentEnvironment
	};

	// data massage for multi-value parms
	~multiCache = ('/1/xy': [0, 0], '/accxyz': [0, 0, 0]);
	~unpackers = (
		'/1/xy X': { |value| ~multiCache['/1/xy'] = value; value[0] },
		'/1/xy Y': { |value| ~multiCache['/1/xy'] = value; value[1] },
		'/accxyz X': { |value| ~multiCache['/accxyz'] = value; value[0] },
		'/accxyz Y': { |value| ~multiCache['/accxyz'] = value; value[1] },
		'/accxyz Z': { |value| ~multiCache['/accxyz'] = value; value[2] }
	);
	~packers = (
		'/1/xy X': { |value|
			var new = ~multiCache['/1/xy'].copy.put(0, value);
			~multiCache['/1/xy'] = new;
			new
		},
		'/1/xy Y': { |value|
			var new = ~multiCache['/1/xy'].copy.put(1, value);
			~multiCache['/1/xy'] = new;
			new
		},
		'/accxyz X': { |value|
			var new = ~multiCache['/accxyz'].copy.put(0, value);
			~multiCache['/accxyz'] = new;
			new
		},
		'/accxyz Y': { |value|
			var new = ~multiCache['/accxyz'].copy.put(1, value);
			~multiCache['/accxyz'] = new;
			new
		},
		'/accxyz Z': { |value|
			var new = ~multiCache['/accxyz'].copy.put(2, value);
			~multiCache['/accxyz'] = new;
			new
		}
	);
	~setTouchValue = { |value|
		var key;
		value = ~spec.unmap(value);
		if(~touchThing.isKindOf(Association)) {
			key = ~touchThing.key;  // OSC key
			value = ~packers[~touchKey].value(value);
		} {
			key = ~touchKey;
		};
		if(value.notNil) {
			BP(~touch).viewChanged(key, value);
		} {
			BP(~touch).viewChanged(key, 0);
		};
	};

	~sourceForPath = { |path|
		if(path.asString.contains("acc")) {
			~xyzSmoother
		} {
			~touch
		};
	};

	~restoreState = { |touchKey ... args|
		var i = ~touchKeys.detectIndex { |item| item == touchKey };
		if(i.isNil) {
			"touchKey % not found".format(touchKey).warn;
		};
		~setTouchIndex.(i);
		~userRestore.(*args);
		currentEnvironment
	};
	~saveState = {
		([~mapType, ~touchKey] ++ ~userSaveParams.()).asCompileString;
	};
} => PR(\abstractOSCMapping);

PR(\abstractOSCMapping).clone {
	~mapType = \npMapping;
	// ~space = Ndef.all[\localhost];
	~userprep = {
		if(~space.isNil) { ~space = Ndef.all[\localhost] ?? { ProxySpace.new } };
		~getIDs.();
		currentEnvironment
	};
	~userfree = {
		~clearDependant.();
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

	~action = { |value|
		var proxy = ~getProxy.();
		if(proxy.notNil) {
			proxy.set(~paramKey, ~spec.map(value));
		};
	};

	~userCanRegister = {
		~proxyKey.notNil and: {
			~paramKey.notNil and: {
				~space[~proxyKey].notNil
			}
		}
	};
	~userRegister = {
		var proxy = ~getProxy.(), value;
		if(proxy.notNil) {
			value = ~getParamValue.(proxy);
			~setTouchValue.(value);
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
		~setProxyKeys.(~space.envir.keys.as(Array).sort);
		~getParams.();
	};
	~setProxyKeys = { |keys|
		~proxyKeys = keys;
		currentEnvironment.changed(\proxyKeys, keys);
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
	~update = { |obj, what ... args|  // NodeProxy .changed sends arrays of args
		switch(what)
		{ \source } {
			// [obj, index, channelOffset, extraArgs, now]
			~getParams.();  // this could add new parameters
		}
		{ \spec } {
			if(args[0] == ~paramKey) {
				~spec = args[1].asSpec;
				~register.();  // update touchGUI
			};
		}
		{ \clear } {
			// my "owner" proxy is dead. clear proxy and param keys
			~getIDs.();  // brute force, just rebuild all the keys -- this doesn't happen often
			~setProxyIndex.(nil);
			~setParamIndex.(nil);
		};
		currentEnvironment
	};

	~userRestore = { |proxyKey, paramKey|
		var i = ~proxyKeys.detectIndex { |item| item == proxyKey };
		if(i.isNil) {
			"Proxy % not found".format(proxyKey).warn;
		};
		~setProxyIndex.(i);
		i = ~paramKeys.detectIndex { |item| item == paramKey };
		if(i.isNil) {
			"Parameter % not found in proxy %".format(paramKey, proxyKey).warn;
		};
		~setParamIndex.(i);
	};
	~userSaveParams = { [~proxyKey, ~paramKey] };
} => PR(\npMapping);

PR(\abstractMappingGui).clone {
	~userMakeViews = { |layout|
		layout.add(~proxyMenu = PopUpMenu());
		layout.add(~paramMenu = PopUpMenu());

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
	};

	~userUpdate = { |obj, what ... args|
		var oldItem;
		switch(what)
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
	};
} => PR(\npMappingGui);



// function mapping
PR(\abstractOSCMapping).clone {
	~mapType = \funcMapping;
	~initString = "{ |value| ... }";
	~userprep = {
		~oldString = ~initString;
		~string = ~initString;
	};

	~string_ = { |str|
		~function = str.interpret;
		if(~function.isNil) {
			currentEnvironment.changed(\compileError, str);
		} {
			~oldString = ~string;
			~string = str;
			currentEnvironment.changed(\string, str);
		};
		currentEnvironment
	};

	~action = { |value|
		try { ~function.value(value) } { |error|
			~function = nil;  // just one error, thanks
			currentEnvironment.changed(\execError, error);
		};
	};

	~getIDs = 0;  // not used

	~userRestore = { |string|
		~string_.(string.replace("##newline##", "\n"));
	};
	~userSaveParams = { [~string.replace("\n", "##newline##")] };
} => PR(\funcMapping);


PR(\abstractMappingGui).clone {
	~highlighted = false;
	~execErrBackground = Color(1, 0.6, 0.6);
	~syntaxErrBackground = Color(1, 0.8, 0.8);
	~background = Color.white;
	~stringColor = Color.black;
	~font = Font(Font.defaultMonoFace, 10);

	~userMakeViews = { |layout|
		layout.add(~stringView = TextField());
		layout.add(~popOutButton = Button());

		~touchMenu.maxWidth = 120;
		layout.setStretch(~stringView, 3);
		~stringView.font_(~font)
		.stringColor_(~stringColor)
		.background_(~background)
		.string_(~model.string)
		.action_(e { |view|
			~model.string = view.string;
		})
		.keyDownAction_(e { |view|
			if(~highlighted) {
				view.background = ~background;
				~highlighted = false;
				nil
			};
		});

		~popOutButton.fixedSize_(Size(20, 20))
		.states_([["^"]])
		.action_(e { |view|
			~popOutEditor.();
		});
	};

	~userUpdate = { |obj, what ... args|
		var name;
		switch(what)
		{ \string } {
			defer(e { ~stringView.string = args[0] })
		}
		{ \compileError } {
			defer(e {
				~highlighted = true;
				~stringView.background = ~syntaxErrBackground;
				if(~popOutView.notNil) {
					~popOutView.background = ~syntaxErrBackground;
				};
				// compile error is already posted IIRC
			});
		}
		{ \execError } {
			defer(e {
				~highlighted = true;
				~stringView.background = ~execErrBackground;
				if(~popOutView.notNil) {
					~popOutView.background = ~execErrBackground;
				};
				~showError.(args[0]);
			});
		}
		{ \touchKey } {
			if(~popOutWindow.notNil) {
				defer(e { ~popOutWindow.name = ~popOutTitle.() });
			};
		}
		{ \didFree } {
			[~errorWindow, ~popOutWindow].do { |window|
				if(window.notNil and: { window.isClosed.not }) {
					window.onClose_(nil).close;
				};
			};
		};
	};

	~popOutEditor = {
		if(~popOutWindow.isNil or: { ~popOutWindow.isClosed }) {
			~popOutWindow = Window(~popOutTitle.(),
				Rect.aboutPoint(Window.screenBounds.center, 400, 300)
			).onClose_(e {
				~popOutWindow = nil;
				~popOutView = nil;
				~model.string = ~popOutCache;
			});
			~popOutWindow.view.layout = VLayout(
				~popOutView = TextView()
			);
		};
		~popOutView.string_(~model.string)
		.background_(~background)
		.stringColor_(~stringColor)
		.font_(~font)
		.enterInterpretsSelection_(false)
		.keyDownAction_(e { |view, char, modifiers, unicode|
			if(~highlighted) {
				view.background = ~background;
				~stringView.background = ~background;
				~highlighted = false;
			};
			if(unicode == 13) {
				if(
					if(thisProcess.platform.name == \osx) { modifiers.isCmd } { modifiers.isCtrl }
				) {
					~model.string = view.string;
				};
			};
			nil
		})
		.keyUpAction_(e { |view|
			~popOutCache = view.string;  // work around TextView close bug
		});
		~popOutWindow.front;
	};
	~popOutTitle = {
		if(~model.touchKey.notNil) {
			"Function for " ++ ~model.touchKey
		} {
			"Unassigned function"
		}
	};

	~showError = { |exception|
		var backtrace;
		if(~errorWindow.isNil or: { ~errorWindow.isClosed }) {
			~errorWindow = Window("Error",
				Rect.aboutPoint(Window.screenBounds.center, 400, 300)
			).onClose_(e { ~errorWindow = nil });
			~errorWindow.view.layout = VLayout(
				~errorView = TextView()
			);
			~errorView.font_(~font);
		};
		backtrace = ~streamBacktrace.(exception);
		~errorView.string = exception.errorString ++ "\n\n" ++ backtrace.collection;
		~errorWindow.front;
	};

	// mostly copied-and-pasted from Exception.sc
	// because it provides no interface to use the string, only post it
	~streamBacktrace = { |exception, out(CollStream.new)|
		var currentFrame, def, ownerClass, methodName, pos, tempStr;
		currentFrame = exception.protectedBacktrace;
		while({currentFrame.notNil}, {
			def = currentFrame.functionDef;
			if(def.isKindOf(Method), {
				ownerClass = def.ownerClass;
				methodName = def.name;
				if(ownerClass == Function && { #['protect', 'try'].includes(methodName) }, {
					pos = out.pos;
				});
				out << "\t%:%\t%\n".format(ownerClass, methodName, currentFrame.address);
			}, {
				out << "\ta FunctionDef\t%\n".format(currentFrame.address);
				// sourceCode may be ridiculously huge,
				// so steal the technique from Object:asString to reduce the printed size
				tempStr = String.streamContentsLimit({ |stream|
					stream << "\t\tsourceCode = " <<< (def.sourceCode ? "<an open Function>");
				}, 512);
				out << tempStr;
				if(tempStr.size >= 512) { out << "...etc..." << $" };
				out << Char.nl;
			});
			def.argNames.do({|name, i|
				out << "\t\targ % = %\n".format(name, currentFrame.args[i]);
			});
			def.varNames.do({|name, i|
				out << "\t\tvar % = %\n".format(name, currentFrame.vars[i]);
			});
			currentFrame = currentFrame.caller;
		});
		// lose everything after the last Function:protect
		// it just duplicates the normal stack with less info
		// but, an Error in a routine in a Scheduler
		// may not have a try/protect in the protectedBacktrace
		// then, pos is nil and we should print everything
		if(pos.notNil) {
			out.collection = out.collection.copyFromStart(pos)
		};
		out
	};
} => PR(\funcMappingGui);



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
	~free = { ~userfree.() };

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
		~maps = Array.new;
		if(~space.isNil) {
			~space = Ndef.all[\localhost] ?? {
				Ndef.dictFor(Server.local)
				// ProxySpace.new
			}
		};
		~startAliveThread.();
	};
	~userfree = {
		~stopAliveThread.();
		// 'copy' because \didFree below modifies the collection
		~maps.copy.do { |map| map.map.free };
	};

	~margins = #[4, 1];
	~spacing = 4;
	~makeViews = {
		var layout;
		~addView.(~menuRow = View().fixedHeight_(22));
		~menuRow.layout = layout = HLayout(
			~addButton = PopUpMenu(),
			~saveButton = Button(),
			~loadButton = Button(),
			nil  // spacer
		).margins_(~margins).spacing_(~spacing);

		~addButton.maxWidth_(150) // .fixedSize_(Size(150, 20))
		.items_(["Add OSC mapping", "-- to Ndef param", "-- to Pdefn", "-- function"])
		.action_(e { |view|
			var map, gui;
			switch(view.value)
			{ 1 } {
				~newMap.(\npMapping, \npMappingGui);
			}
			{ 3 } {
				~newMap.(\funcMapping, \funcMappingGui);
			}
			{ "Not yet implemented".warn };
			view.value = 0;
		});

		~saveButton.maxWidth_(150)
		.states_([["Save maps"]])
		.action_(e { ~saveDialog.() });

		~loadButton.maxWidth_(150)
		.states_([["Load maps"]])
		.action_(e { ~loadDialog.() });
	};

	~newMap = { |mapKey, guiKey|
		var map, gui;
		if(guiKey.isNil) { guiKey = (mapKey ++ "Gui").asSymbol };
		map = PR(mapKey).copy.prep;
		gui = PR(guiKey).copy.prep(map, ~layout, false);  // don't add to layout!
		if(map.notNil) {
			~addView.(gui.view);
			~maps = ~maps.add((map: map, gui: gui, spec: nil.asSpec));
			map.addDependant(currentEnvironment);
			~maps.last;
		} { nil }
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

	~checkProxies = {
		if(~prevProxyKeys != ~space.envir.keys) {
			~prevProxyKeys = ~space.envir.keys;
			~maps.do { |item| item[\map].getIDs };
		};
	};

	~updatePeriod = 1.0;
	~startAliveThread = {
		if(~aliveThread.isNil) {
			~aliveThread = Task {
				loop {
					~checkProxies.();
					~updatePeriod.wait;
				}
			}.play(AppClock);
		};
		if(~restartFunc.isNil or: { CmdPeriod.objects.includes(~restartFunc).not }) {
			~restartFunc = e {
				if(~aliveThread.wasStopped) {
					~aliveThread = nil;
					~startAliveThread.();
				};
			};
			CmdPeriod.add(~restartFunc);
		};
		currentEnvironment
	};

	~stopAliveThread = {
		~aliveThread.stop;
		~aliveThread = nil;
		CmdPeriod.remove(~restartFunc);
		~restartFunc = nil;
		currentEnvironment
	};

	~saveDialog = {
		Dialog.savePanel(e { |path| ~saveToFile.(path) });
	};
	~loadDialog = {
		Dialog.openPanel(e { |path| ~loadFromFile.(path) });
	};

	~saveToFile = { |path, errAction|
		var file = File(path, "w"), errCode = \ok;
		if(file.isOpen) {
			protect {
				~maps.do { |map|
					file << map.map.saveState << "\n";
				};
			} { |error|
				file.close;
				if(error.notNil) { errAction.(\saveError) };
			};
		} {
			"Could not open '%' for writing".format(path).warn;
			errCode = \fileOpenError;
		};
		errAction.(errCode);
		errCode
	};
	~loadFromFile = { |path, errAction|
		var file, line, states, errCode = \pending;
		file = File(path, "r");
		if(file.isOpen) {
			protect {
				states = Array.new;
				while { (line = file.getLine(2048)).notNil } {
					states = states.add(line.interpret);
				};
			} { |error|
				file.close;
				if(error.notNil) { errAction.(\readError) };
			};
			~maps.copy.do { |map| map.map.free };
			~maps = Array.new;
			{
				0.1.wait;
				states.do { |state| ~newMap.(state[0]) };
				0.1.wait;
				states.do { |state, i|
					~maps[i].map.restoreState(*state[1..]);
				};
				errAction.(\ok);
			}.fork(AppClock);
		} {
			"Could not open '%' for writing".format(path).warn;
			errCode = \fileOpenError;
		};
		errAction.(errCode);
		errCode
	};
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
	~space = nil;

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
		~oscMapMgr = PR(\touchMapManager).copy
		.put(\space, ~space)
		.prep(~oscMgrView, ~oscMgr.layout);
		~window.onClose_(e { ~free.() }).front;
		currentEnvironment
	};
	~free = {
		~oscMapMgr.free; ~oscMapMgr = nil;
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
