package flixel;

/**
 * ...
 * @author Zaphod
 */
class FlxObjectPlugin extends FlxAtomic
{
	public var parent:FlxObject;
	
	public function new(Parent:FlxObject) 
	{
		super();
		parent = Parent;
	}
	
	override public function destroy():Void 
	{
		super.destroy();
		parent = null;
	}
}