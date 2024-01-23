package utils;

import haxe.PosInfos;

var originalTrace(default, null) = haxe.Log.trace;

function getClassName(infos:PosInfos):String {
	var dotInd = infos.className.lastIndexOf('.');
	return infos.className.substring(dotInd + 1);
}

private function formatExtra(infos:PosInfos, separator = ', ') {
	return infos.customParams?.join(separator) ?? '';
}

function trace(v:Any, ?infos:PosInfos) {
	var extra = formatExtra(infos);
	var msg = '${getClassName(infos)}:${infos.lineNumber} ${Std.string(v)}${extra == '' ? '' : ', $extra'}';
	#if desktop
	Sys.println(msg);
	#elseif js
	js.html.Console.log(msg);
	#else
	throw 'not implemented'
	#end
}
