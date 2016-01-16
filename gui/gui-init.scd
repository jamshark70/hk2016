if(PR.exists(\abstractTouch).not) {
	(Quarks.at("ddwProtoLib").localPath +/+ "mobile-objects.scd").loadPath;
};

// color theme (dark):
Library.put(\workshopGuiTheme, (
	windowBG: nil, // Color.clear,
	containerBG: Color.gray(0.2),
));



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

		~layout = VLayout(
			~touchParent = View().fixedSize_(touchExtent + Point(-4, 4)),
			// other views
		);
		PR(\abstractTouchGUI).chuck(BP(~touchGuiName), nil, (
			model: BP(~touchName).v,
			parentView: ~touchParent
		));
		~parentView.layout = ~layout;

		currentEnvironment
	};
	~free = {
		BP(~touchGuiName).free;
		if(~iMadeTouch) { BP(~touchName).free };
		// remove other views?
	};
	~freeCleanup = { ~free.() };
} => PR(\touchManager);



/***** GUI: OSC mapping section *****/

// Proto {
//
// } => PR(\touchMapManager);



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
