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

}
