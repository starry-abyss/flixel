package flixel;
import flixel.util.FlxDestroyUtil.IFlxDestroyable;

/**
 * ...
 * @author Zaphod
 */
class FlxAtomic implements IFlxDestroyable
{
	/**
	 * IDs seem like they could be pretty useful, huh?
	 * They're not actually used for anything yet though.
	 */
	public var ID:Int = -1;
	/**
	 * Controls whether update() is automatically called by FlxState/FlxGroup.
	 */
	public var active(default, set):Bool = true;
	/**
	 * Controls whether draw() is automatically called by FlxState/FlxGroup.
	 */
	public var visible(default, set):Bool = true;
	
	public function new() {  }
	
	/**
	 * WARNING: This will remove this object entirely. Use kill() if you want to disable it temporarily only and revive() it later.
	 * Override this function to null out variables manually or call destroy() on class members if necessary. Don't forget to call super.destroy()!
	 */
	public function destroy():Void {  }
	
	/**
	 * Override this function to update your class's position and appearance.
	 * This is where most of your game rules and behavioral code will go.
	 */
	public function update(elapsed:Float):Void {  }
	
	/**
	 * Override this function to control how the object is drawn.
	 * Overriding draw() is rarely necessary, but can be very useful.
	 */
	public function draw():Void {  }
	
	private function set_visible(Value:Bool):Bool
	{
		return visible = Value;
	}
	
	private function set_active(Value:Bool):Bool
	{
		return active = Value;
	}
}