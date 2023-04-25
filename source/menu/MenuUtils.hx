package menu;

import djFlixel.ui.FlxMenu;

function setDefaultMenuStyle(menu:FlxMenu) {
	// disabling menu items tweening
	menu.STP.focus_anim = null;
	menu.STP.vt_IN = menu.STP.vt_OUT = '0:0|0:0';
	menu.STP.vt_in_ease = null;
	// setting up menu items text
	menu.STP.align = 'center';
	menu.STP.item.text = {
		s: 30,
		a: 'center'
	};
}

/**
	Wraps menu page with header label and 'go back' action.
	@param headerLabel header label
	@param pageData string page data
**/
function wrapMenuPage(headerLabel:String, pageData:String) {
	return '
		-| $headerLabel | label | 1 | U
		-| __________ | label | 2 | U
		$pageData
		-| __________ | label | 3 | U
		-| go back | link | @back
		';
}
