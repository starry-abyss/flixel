package flixel;
import flixel.graphics.FlxTexture;
import flixel.graphics.frames.FlxFramesCollection;
import flixel.graphics.views.FlxGraphic;
import flixel.math.FlxPoint;
import flixel.system.FlxAssets.FlxGraphicAsset;
import flixel.util.FlxColor;
import flixel.util.FlxDestroyUtil;

/**
 * ...
 * @author Zaphod
 */
class FlxBaseSprite extends FlxObject
{
	public var graphic(default, set):FlxGraphic;
	
	/**
	 * Controls how much this object is affected by camera scrolling. 0 = no movement (e.g. a background layer), 
	 * 1 = same movement speed as the foreground. Default value is (1,1), except for UI elements like FlxButton where it's (0,0).
	 */
	public var scrollFactor(get, null):FlxPoint;
	/**
	 * The width of the actual graphic or image being displayed (not necessarily the game object/bounding box).
	 */
	public var frameWidth(get, set):Int;
	/**
	 * The height of the actual graphic or image being displayed (not necessarily the game object/bounding box).
	 */
	public var frameHeight(get, set):Int;
	
	public var texture(get, set):FlxTexture;
	
	/**
	 * The total number of frames in this image.  WARNING: assumes each row in the sprite sheet is full!
	 */
	public var numFrames(get, null):Int = 0;
	/**
	 * Rendering variables.
	 */
	public var frames(get, set):FlxFramesCollection;
	
	/**
	 * Set this flag to true to force the sprite to update during the draw() call.
	 * NOTE: Rarely if ever necessary, most sprite operations will flip this flag automatically.
	 */
	public var dirty(get, set):Bool;
	
	/**
	 * Called whenever a new graphic is loaded for this sprite
	 * - after loadGraphic(), makeGraphic() etc.
	 */
	public var graphicLoadedCallback(get, set):Void->Void;
	
	public function new(?X:Float = 0, ?Y:Float = 0, ?Graphic:FlxGraphic) 
	{
		super(X, Y);
		graphic = Graphic;
	}
	
	override public function destroy():Void 
	{
		super.destroy();
		graphic = FlxDestroyUtil.destroy(graphic);
	}
	
	override public function draw():Void 
	{
		if (graphic != null && graphic.visible)
			graphic.draw();
		
		#if !FLX_NO_DEBUG
		super.draw();
		if (FlxG.debugger.drawDebug)
			drawDebug();
		#end
	}
	
	override public function update(elapsed:Float):Void 
	{
		super.update(elapsed);
		
		if (graphic != null && graphic.active)
			graphic.update(elapsed);
	}
	
	/**
	 * Call this function to figure out the on-screen position of the object.
	 * 
	 * @param	Camera		Specify which game camera you want.  If null getScreenPosition() will just grab the first global camera.
	 * @param	Point		Takes a FlxPoint object and assigns the post-scrolled X and Y values of this object to it.
	 * @return	The Point you passed in, or a new Point if you didn't pass one, containing the screen X and Y position of this object.
	 */
	override public function getScreenPosition(?point:FlxPoint, ?Camera:FlxCamera):FlxPoint
	{
		if (graphic != null)
			return graphic.getScreenPosition(point, Camera);
		
		return super.getScreenPosition(point, Camera);
	}
	
	private function resetHelpers():Void
	{
		if (graphic != null)
			graphic.resetHelpers();
	}
	
	/**
	 * Check and see if this object is currently on screen.
	 * 
	 * @param	Camera		Specify which game camera you want.  If null getScreenPosition() will just grab the first global camera.
	 * @return	Whether the object is on screen or not.
	 */
	override public function isOnScreen(?Camera:FlxCamera):Bool
	{
		if (graphic != null)
			return graphic.isOnScreen(Camera);
		
		return super.isOnScreen(Camera);
	}
	
	/**
	 * Retrieve the midpoint of this sprite's graphic in world coordinates.
	 * 
	 * @param	point	Allows you to pass in an existing FlxPoint object if you're so inclined. Otherwise a new one is created.
	 * @return	A FlxPoint object containing the midpoint of this sprite's graphic in world coordinates.
	 */
	public function getGraphicMidpoint(?point:FlxPoint):FlxPoint
	{
		return graphic.getGraphicMidpoint(point);
	}
	
	/**
	 * Checks to see if a point in 2D world space overlaps this FlxSprite object's current displayed pixels.
	 * This check is ALWAYS made in screen space, and always takes scroll factors into account.
	 * 
	 * @param	Point		The point in world space you want to check.
	 * @param	Mask		Used in the pixel hit test to determine what counts as solid.
	 * @param	Camera		Specify which game camera you want.  If null getScreenPosition() will just grab the first global camera.
	 * @return	Whether or not the point overlaps this object.
	 */
	public function pixelsOverlapPoint(point:FlxPoint, Mask:Int = 0xFF, ?Camera:FlxCamera):Bool
	{
		return graphic.pixelsOverlapPoint(point, Mask, Camera);
	}
	
	/**
	 * Replaces all pixels with specified Color with NewColor pixels. 
	 * WARNING: very expensive (especially on big graphics) as it iterates over every single pixel.
	 * 
	 * @param	Color				Color to replace
	 * @param	NewColor			New color
	 * @param	FetchPositions		Whether we need to store positions of pixels which colors were replaced
	 * @return	Array replaced pixels positions
	 */
	public function replaceColor(Color:FlxColor, NewColor:FlxColor, FetchPositions:Bool = false):Array<FlxPoint>
	{
		return graphic.replaceColor(Color, NewColor, FetchPositions);
	}
	
	/**
	 * Updates the sprite's hitbox (width, height, offset) according to the current scale. 
	 * Also calls setOriginToCenter(). Called by setGraphicSize().
	 */
	public function updateHitbox():Void
	{
		graphic.updateHitbox();
	}
	
	/**
	 * Resets _flashRect variable used for frame bitmapData calculation
	 */
	public inline function resetSize():Void
	{
		graphic.resetSize();
	}
	
	/**
	 * Resets frame size to frame dimensions
	 */
	public inline function resetFrameSize():Void
	{
		graphic.resetFrameSize();
	}
	
	/**
	 * Resets sprite's size back to frame size
	 */
	public inline function resetSizeFromFrame():Void
	{
		graphic.resetSizeFromFrame();
	}
	
	// TODO: transform it into properties...
	public function setTop(Y:Float):Float
	{
		// TODO: implement these methods after changes in origin handling...
		return y = Y;
	}
	
	public function setLeft(X:Float):Float
	{
		// TODO: implement these methods after changes in origin handling...
		return x = X;
	}
	
	// TODO: add props such as bottom and right as well
	
	private function get_frameWidth():Int
	{
		return graphic.frameWidth;
	}
	
	private function set_frameWidth(Value:Int):Int
	{
		return graphic.frameWidth = Value;
	}
	
	private function get_frameHeight():Int
	{
		return graphic.frameHeight;
	}
	
	private function set_frameHeight(Value:Int):Int
	{
		return graphic.frameHeight = Value;
	}
	
	private function get_texture():FlxTexture
	{
		return graphic.texture;
	}
	
	private function set_texture(Value:FlxTexture):FlxTexture
	{
		return graphic.texture = Value;
	}
	
	private function get_numFrames():Int
	{
		return graphic.numFrames;
	}
	
	private function get_frames():FlxFramesCollection
	{
		return graphic.frames;
	}
	
	private function set_frames(Value:FlxFramesCollection):FlxFramesCollection
	{
		return graphic.frames = Value;
	}
	
	private function set_graphic(Value:FlxGraphic):FlxGraphic
	{
		graphic = Value;
		
		if (graphic != null)
		{
			graphic.parent = this;
			width = graphic.frameWidth;
			height = graphic.frameHeight;
		}
		
		return graphic;
	}
	
	private function get_scrollFactor():FlxPoint 
	{
		if (graphic != null)
			return graphic.scrollFactor;
			
		return null;
	}
	
	private function get_graphicLoadedCallback():Void->Void
	{
		return graphic.graphicLoadedCallback;
	}
	
	private function set_graphicLoadedCallback(Value:Void->Void):Void->Void
	{
		return graphic.graphicLoadedCallback = Value;
	}
	
	private function get_dirty():Bool
	{
		return graphic.dirty;
	}
	
	private function set_dirty(Value:Bool):Bool
	{
		return graphic.dirty = Value;
	}
}