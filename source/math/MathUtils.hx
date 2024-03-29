package math;

#if flixel
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
#end

#if flixel
/**
	Makes given FlxPoint `weak`.
	Weak points automatically destroyed when passed to flixel methods.
	@param p 
**/
overload extern inline function wp(p:FlxPoint):FlxPoint {
	@:privateAccess p._weak = true;
	return p;
}

/**
	Retrives a new weak point from the pool.
	@param x 
	@param y 
	@return FlxPoint
**/
overload extern inline function wp(x:Float = 0, y:Float = 0):FlxPoint {
	return FlxPoint.weak(x, y);
}

/**
	Retrives a new point from the pool.
	@param x = 0.0 
	@param y = 0.0 
	@return FlxPoint
**/
inline function p(x = 0.0, y = 0.0):FlxPoint {
	return FlxPoint.get(x, y);
}

/**
	Retrives a new point from the pool.
	@param x = 0.0 
	@param y = 0.0 
	@return FlxPoint
**/
inline function point(x = 0.0, y = 0.0):FlxPoint {
	return FlxPoint.get(x, y);
}

overload extern inline function lerp(a:FlxPoint, b:FlxPoint, r:Float = 0.5, ?p:FlxPoint):FlxPoint {
	return (p ?? point(0, 0)).set(FlxMath.lerp(a.x, b.x, r), FlxMath.lerp(a.y, b.y, r));
}

/**
	Rounds a decimal value with given precission
	@param val 
	@param precision 
	@return Float
**/
inline function round(val:Float, precision:Int = 2):Float {
	return FlxMath.roundDecimal(val, precision);
}
#end

function xor(a:Bool, b:Bool) {
	return (a && !b) || (!a && b);
}

inline function invLerp(a:Float, b:Float, v:Float):Float {
	return (v - a) / (b - a);
}
