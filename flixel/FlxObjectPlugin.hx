package flixel;

/**
 * ...
 * @author Zaphod
 */
class FlxObjectPlugin extends FlxAtomic
{
	public var parent(default, set):FlxObject;
	
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
	
	private function set_parent(Value:FlxObject):FlxObject
	{
		return parent = Value;
	}
}