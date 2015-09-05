package flixel.graphics.views;

import flash.display.BitmapData;
import flixel.FlxBaseSprite;
import flixel.graphics.frames.FlxFrame;
import flixel.graphics.frames.FlxFramesCollection;
import flixel.graphics.frames.FlxTileFrames;
import flixel.math.FlxMatrix;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.system.FlxAssets.FlxGraphicAsset;
import flixel.util.FlxColor;
import flixel.util.FlxDestroyUtil;
import openfl.geom.Point;
import openfl.geom.Rectangle;

@:keep @:bitmap("assets/images/logo/default.png")
private class GraphicDefault extends BitmapData {}

/**
 * ...
 * @author Zaphod
 */
class FlxGraphic implements IFlxDestroyable
{
	/**
	 * If the graphic should update.
	 */
	public var active:Bool;

	/**
	 * If the graphic should render.
	 */
	public var visible:Bool;
	
	/**
	 * Controls whether the object is smoothed when rotated, affects performance.
	 */
	public var antialiasing(default, set):Bool = false;
	
	/**
	 * Set pixels to any BitmapData object.
	 * Automatically adjust graphic size and render helpers.
	 */
	public var pixels(get, set):BitmapData;
	
	/**
	 * Set this flag to true to force the sprite to update during the draw() call.
	 * NOTE: Rarely if ever necessary, most sprite operations will flip this flag automatically.
	 */
	public var dirty:Bool = true;
	
	public var parent:FlxBaseSprite<Dynamic> = null;
	
	/**
	 * Link to current FlxFrame from loaded atlas
	 */
	public var frame(default, set):FlxFrame;
	/**
	 * The width of the actual graphic or image being displayed (not necessarily the game object/bounding box).
	 */
	public var frameWidth(default, null):Int = 0;
	/**
	 * The height of the actual graphic or image being displayed (not necessarily the game object/bounding box).
	 */
	public var frameHeight(default, null):Int = 0;
	/**
	 * The total number of frames in this image.  WARNING: assumes each row in the sprite sheet is full!
	 */
	public var numFrames(default, null):Int = 0;
	
	public var frameIndex(get, set):Int;
	
	/**
	 * Rendering variables.
	 */
	public var frames(default, set):FlxFramesCollection;
	public var texture(default, set):FlxTexture;
	
	/**
	 * Controls the position of the sprite's hitbox. Likely needs to be adjusted after
	 * changing a sprite's width, height or scale.
	 */
	public var offset(default, null):FlxPoint;
	
	/**
	 * Controls how much this object is affected by camera scrolling. 0 = no movement (e.g. a background layer), 
	 * 1 = same movement speed as the foreground. Default value is (1,1), except for UI elements like FlxButton where it's (0,0).
	 */
	public var scrollFactor(default, null):FlxPoint;
	
	/**
	 * Gets ot sets the first camera of this object.
	 */
	public var camera(get, set):FlxCamera;
	/**
	 * This determines on which FlxCameras this object will be drawn. If it is null / has not been
	 * set, it uses FlxCamera.defaultCameras, which is a reference to FlxG.cameras.list (all cameras) by default.
	 */
	public var cameras(get, set):Array<FlxCamera>;
	
	/**
	 * Whether or not the coordinates should be rounded during rendering. 
	 * Does not affect copyPixels(), which can only render on whole pixels.
	 * Defaults to the camera's global pixelPerfectRender value,
	 * but overrides that value if not equal to null.
	 */
	public var pixelPerfectRender(default, set):Null<Bool>;
	
	/**
	 * Internal, reused frequently during drawing and animating.
	 */
	private var _flashPoint:Point;
	/**
	 * Internal, reused frequently during drawing and animating.
	 */
	private var _flashRect:Rectangle;
	/**
	 * Internal, reused frequently during drawing and animating.
	 */
	private var _flashRect2:Rectangle;
	/**
	 * Internal, reused frequently during drawing and animating. Always contains (0,0).
	 */
	private var _flashPointZero:Point;
	
	/**
	 * Internal, helps with animation, caching and drawing.
	 */
	private var _matrix:FlxMatrix;
	
	private var _cameras:Array<FlxCamera>;
	
	private var _point:FlxPoint;
	
	public function new(?Parent:FlxBaseSprite<Dynamic>, ?Graphic:FlxGraphicAsset)
	{
		parent = Parent;
		active = true;
		visible = true;
		
		_flashPoint = new Point();
		_flashRect = new Rectangle();
		_flashRect2 = new Rectangle();
		_flashPointZero = new Point();
		offset = FlxPoint.get();
		scrollFactor = FlxPoint.get();
		_matrix = new FlxMatrix();
		_point = FlxPoint.get();
		
		if (Graphic != null)
			loadGraphic(Graphic);
	}
	
	/**
	 * Load an image from an embedded graphic file.
	 *
 	 * HaxeFlixel's graphic caching system keeps track of loaded image data. 
 	 * When you load an identical copy of a previously used image, by default
 	 * HaxeFlixel copies the previous reference onto the pixels field instead
 	 * of creating another copy of the image data, to save memory.
	 * 
	 * @param	Graphic		The image you want to use.
	 * @param	Animated	Whether the Graphic parameter is a single sprite or a row of sprites.
	 * @param	Width		Optional, specify the width of your sprite (helps FlxSprite figure out what to do with non-square sprites or sprite sheets).
	 * @param	Height		Optional, specify the height of your sprite (helps FlxSprite figure out what to do with non-square sprites or sprite sheets).
	 * @param	Unique		Optional, whether the graphic should be a unique instance in the graphics cache.  Default is false.
	 *				Set this to true if you want to modify the pixels field without changing the pixels of other sprites with the same BitmapData.
	 * @param	Key		Optional, set this parameter if you're loading BitmapData.
	 * @return	This FlxSprite instance (nice for chaining stuff together, if you're into that).
	 */
	public function loadGraphic(Graphic:FlxGraphicAsset, Animated:Bool = false, Width:Int = 0, Height:Int = 0, Unique:Bool = false, ?Key:String):FlxGraphic
	{
		var texture:FlxTexture = FlxG.bitmap.add(Graphic, Unique, Key);
		
		if (texture == null)
			return this;
		
		if (Width == 0)
		{
			Width = (Animated == true) ? texture.height : texture.width;
			Width = (Width > texture.width) ? texture.width : Width;
		}
		
		if (Height == 0)
		{
			Height = (Animated == true) ? Width : texture.height;
			Height = (Height > texture.height) ? texture.height : Height;
		}
		
		if (Animated)
		{
			frames = FlxTileFrames.fromGraphic(texture, new FlxPoint(Width, Height));
		}
		else
		{
			frames = texture.imageFrame;
		}
		
		return this;
	}
	
	/**
	 * This function creates a flat colored rectangular image dynamically.
	 *
 	 * HaxeFlixel's graphic caching system keeps track of loaded image data. 
 	 * When you make an identical copy of a previously used image, by default
 	 * HaxeFlixel copies the previous reference onto the pixels field instead
 	 * of creating another copy of the image data, to save memory.
 	 * 
	 * @param	Width		The width of the sprite you want to generate.
	 * @param	Height		The height of the sprite you want to generate.
	 * @param	Color		Specifies the color of the generated block (ARGB format).
	 * @param	Unique		Whether the graphic should be a unique instance in the graphics cache.  Default is false.
	 *				Set this to true if you want to modify the pixels field without changing the pixels of other sprites with the same BitmapData.
	 * @param	Key		Optional parameter - specify a string key to identify this graphic in the cache.  Trumps Unique flag.
	 * @return	This FlxSprite instance (nice for chaining stuff together, if you're into that).
	 */
	public function makeGraphic(Width:Int, Height:Int, Color:FlxColor = FlxColor.WHITE, Unique:Bool = false, ?Key:String):FlxGraphic
	{
		var texture:FlxTexture = FlxG.bitmap.create(Width, Height, Color, Unique, Key);
		frames = texture.imageFrame;
		return this;
	}
	
	/**
	 * Updates the graphic.
	 */
	public function update(elapsed:Float):Void {  }
	
	/**
	 * Draws the graphic.
	 */
	public function draw():Void
	{ 
		if (frame == null)
		{
			#if !FLX_NO_DEBUG
			loadGraphic(FlxTexture.fromClass(GraphicDefault));
			#else
			return;
			#end
		}
		
		if (!visible || parent == null || frame.type == FlxFrameType.EMPTY)
			return;
		
		for (camera in cameras)
		{
			if (!camera.visible || !camera.exists || !isOnScreen(camera))
				continue;
			
			getScreenPosition(_point, camera).subtractPoint(offset);
			
			if (isPixelPerfectRender(camera))
				_point.floor();
			
			if (isSimpleRender(camera))
			{
				_point.copyToFlash(_flashPoint);
				camera.copyPixels(frame, null, _flashRect, _flashPoint, 1, 1, 1, 1, null, antialiasing);
			}
			else
			{
				frame.prepareMatrix(_matrix, FlxFrameAngle.ANGLE_0);
				_matrix.translate(_point.x, _point.y);
				camera.drawPixels(frame, null, _matrix, 1, 1, 1, 1, null, antialiasing);
			}
		}
	}
	
	/**
	 * Called whenever a new graphic is loaded for this sprite
	 * - after loadGraphic(), makeGraphic() etc.
	 */
	public function graphicLoaded():Void {  }
	
	/**
	 * Helps to clean the memory from this graphic object
	 */
	public function destroy():Void
	{ 
		_cameras = null;
		
		offset = FlxDestroyUtil.put(offset);
		scrollFactor = FlxDestroyUtil.put(scrollFactor);
		_point = FlxDestroyUtil.put(_point);
		
		_flashPoint = null;
		_flashRect = null;
		_flashRect2 = null;
		_flashPointZero = null;
		
		frame = null;
		
		frames = null;
		texture = null;
		parent = null;
		_matrix = null;
	}
	
	/**
	 * Resets _flashRect variable used for frame bitmapData calculation
	 */
	public inline function resetSize():Void
	{
		_flashRect.x = 0;
		_flashRect.y = 0;
		_flashRect.width = frameWidth;
		_flashRect.height = frameHeight;
	}
	
	/**
	 * Resets frame size to frame dimensions
	 */
	public inline function resetFrameSize():Void
	{
		if (frame != null) 
		{
			frameWidth = Std.int(frame.sourceSize.x);
			frameHeight = Std.int(frame.sourceSize.y);
		}
		resetSize();
	}
	
	/**
	 * Resets sprite's size back to frame size
	 */
	public inline function resetSizeFromFrame():Void
	{
		if (parent == null)	return;
		
		parent.width = frameWidth;
		parent.height = frameHeight;
	}
	
	/**
	 * Check and see if this object is currently on screen.
	 * 
	 * @param	Camera		Specify which game camera you want.  If null getScreenPosition() will just grab the first global camera.
	 * @return	Whether the object is on screen or not.
	 */
	public function isOnScreen(?Camera:FlxCamera):Bool
	{
		if (parent == null)	return false;
		
		if (Camera == null)
		{
			Camera = FlxG.camera;
		}
		getScreenPosition(_point, Camera);
		return (_point.x + parent.width > 0) && (_point.x < Camera.width) && (_point.y + parent.height > 0) && (_point.y < Camera.height);
	}
	
	/**
	 * Call this function to figure out the on-screen position of the object.
	 * 
	 * @param	Camera		Specify which game camera you want.  If null getScreenPosition() will just grab the first global camera.
	 * @param	Point		Takes a FlxPoint object and assigns the post-scrolled X and Y values of this object to it.
	 * @return	The Point you passed in, or a new Point if you didn't pass one, containing the screen X and Y position of this object.
	 */
	public function getScreenPosition(?point:FlxPoint, ?Camera:FlxCamera):FlxPoint
	{
		if (parent == null)	return point;
		
		if (point == null)
		{
			point = FlxPoint.get();
		}
		if (Camera == null)
		{
			Camera = FlxG.camera;
		}
		
		point.set(parent.x, parent.y);
		if (parent != null && parent.pixelPerfectPosition)
		{
			point.floor();
		}
		
		return point.subtract(Camera.scroll.x * scrollFactor.x, Camera.scroll.y * scrollFactor.y);
	}
	
	private function get_pixels():BitmapData
	{
		if (texture == null)
			return null;
		
		return texture.bitmap;
	}
	
	private function set_pixels(Pixels:BitmapData):BitmapData
	{
		var key:String = FlxG.bitmap.findKeyForBitmap(Pixels);
		
		if (key == null)
		{
			key = FlxG.bitmap.getUniqueKey();
			texture = FlxG.bitmap.add(Pixels, false, key);
		}
		else
		{
			texture = FlxG.bitmap.get(key);
		}
		
		frames = texture.imageFrame;
		return Pixels;
	}
	
	private function set_frame(Value:FlxFrame):FlxFrame
	{
		frame = Value;
		if (frame != null)
		{
			resetFrameSize();
			dirty = true;
		}
		else if (frames != null && frames.frames != null && numFrames > 0)
		{
			frame = frames.frames[0];
			dirty = true;
		}
		
		return frame;
	}
	
	/**
	 * Internal function for setting graphic property for this object. 
	 * It changes graphics' useCount also for better memory tracking.
	 */
	private function set_texture(Value:FlxTexture):FlxTexture
	{
		var oldGraphic:FlxTexture = texture;
		
		if ((texture != Value) && (Value != null))
		{
			Value.useCount++;
		}
		
		if ((oldGraphic != null) && (oldGraphic != Value))
		{
			oldGraphic.useCount--;
		}
		
		return texture = Value;
	}
	
	/**
	 * Frames setter. Used by "loadGraphic" methods, but you can load generated frames yourself 
	 * (this should be even faster since engine doesn't need to do bunch of additional stuff).
	 * 
	 * @param	Frames	frames to load into this sprite.
	 * @return	loaded frames.
	 */
	private function set_frames(Frames:FlxFramesCollection):FlxFramesCollection
	{
		if (Frames != null)
		{
			texture = Frames.parent;
			frames = Frames;
			frame = frames.getByIndex(0);
			numFrames = frames.numFrames;
			resetHelpers();
			graphicLoaded();
		}
		else
		{
			frames = null;
			frame = null;
			texture = null;
		}
		
		return Frames;
	}
	
	private function get_frameIndex():Int
	{
		if (frames != null)
			return frames.getFrameIndex(frame);
		
		return 0;
	}
	
	private function set_frameIndex(value:Int):Int
	{
		if (value >= 0 && value < numFrames)
		{
			frame = frames.getByIndex(value);
		}
		
		return value;
	}
	
	private function set_antialiasing(value:Bool):Bool
	{
		return antialiasing = value;
	}
	
	private function get_camera():FlxCamera
	{
		return (_cameras == null || _cameras.length == 0) ? FlxCamera.defaultCameras[0] : _cameras[0];
	}
	
	private function set_camera(Value:FlxCamera):FlxCamera
	{
		if (_cameras == null)
			_cameras = [Value];
		else
			_cameras[0] = Value;
		return Value;
	}
	
	private function get_cameras():Array<FlxCamera>
	{
		return (_cameras == null) ? FlxCamera.defaultCameras : _cameras;
	}
	
	private function set_cameras(Value:Array<FlxCamera>):Array<FlxCamera>
	{
		return _cameras = Value;
	}
	
	private function set_pixelPerfectRender(Value:Bool):Bool 
	{
		return pixelPerfectRender = Value;
	}
	
	/**
	 * Resets some important variables for sprite optimization and rendering.
	 */
	private function resetHelpers():Void
	{
		resetFrameSize();
		resetSizeFromFrame();
		_flashRect2.x = 0;
		_flashRect2.y = 0;
		
		if (texture != null)
		{
			_flashRect2.width = texture.width;
			_flashRect2.height = texture.height;
		}
		
	#if FLX_RENDER_BLIT
		dirty = true;
	#end
	}
	
	/**
	 * Returns the result of isSimpleRenderBlit() if FLX_RENDER_BLIT is 
	 * defined or false if FLX_RENDER_TILE is defined.
	 */
	public function isSimpleRender(?camera:FlxCamera):Bool
	{ 
		#if FLX_RENDER_BLIT
		return isSimpleRenderBlit(camera);
		#else
		return false;
		#end
	}
	
	/**
	 * Determines the function used for rendering in blitting: copyPixels() for simple sprites, draw() for complex ones. 
	 * Sprites are considered simple when they have an angle of 0, a scale of 1, don't use blend and pixelPerfectRender is true.
	 * 
	 * @param	camera	If a camera is passed its pixelPerfectRender flag is taken into account
	 */
	public function isSimpleRenderBlit(?camera:FlxCamera):Bool
	{
		return (camera != null ? isPixelPerfectRender(camera) : pixelPerfectRender);
	}
	
	/**
	 * Check if object is rendered pixel perfect on a specific camera.
	 */
	public function isPixelPerfectRender(?Camera:FlxCamera):Bool
	{
		if (Camera == null)
		{
			Camera = FlxG.camera;
		}
		
		return pixelPerfectRender == null ? Camera.pixelPerfectRender : pixelPerfectRender;
	}
}