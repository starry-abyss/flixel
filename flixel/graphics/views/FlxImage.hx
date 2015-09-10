package flixel.graphics.views;

import flixel.graphics.frames.FlxFrame;
import flixel.graphics.frames.FlxFramesCollection;
import flixel.math.FlxAngle;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.system.FlxAssets.FlxGraphicAsset;
import flixel.util.FlxBitmapDataUtil;
import flixel.util.FlxColor;
import flixel.util.FlxDestroyUtil;
import openfl.display.BitmapData;
import openfl.display.BlendMode;
import openfl.geom.ColorTransform;
import openfl.geom.Matrix;

/**
 * ...
 * @author Zaphod
 */
class FlxImage extends FlxGraphic
{
	/**
	 * The actual Flash BitmapData object representing the current display state of the sprite.
	 * WARNING: can be null in FLX_RENDER_TILE mode unless you call getFlxFrameBitmapData() beforehand.
	 */
	// TODO: maybe convert this var to property...
	public var framePixels:BitmapData;
	
	public var angle(default, set):Float = 1.0;
	
	/**
	 * Set alpha to a number between 0 and 1 to change the opacity of the sprite.
	 */
	public var alpha(default, set):Float = 1.0;
	/**
	 * Set facing using FlxObject.LEFT, RIGHT, UP, and DOWN to take advantage 
	 * of flipped sprites and/or just track player orientation more easily.
	 */
	public var facing(default, set):Int = FlxObject.RIGHT;
	/**
	 * Whether this sprite is flipped on the X axis
	 */
	public var flipX(default, set):Bool = false;
	/**
	 * Whether this sprite is flipped on the Y axis
	 */
	public var flipY(default, set):Bool = false;
	 
	/**
	 * WARNING: The origin of the sprite will default to its center. If you change this, 
	 * the visuals and the collisions will likely be pretty out-of-sync if you do any rotation.
	 */
	public var origin(default, null):FlxPoint;
	
	/**
	 * Change the size of your sprite's graphic. NOTE: The hitbox is not automatically adjusted, use updateHitbox for that
	 * (or setGraphicSize(). WARNING: When using blitting (flash), scaling sprites decreases rendering performance by a factor of about x10!
	 */
	public var scale(default, null):FlxPoint;
	/**
	 * Blending modes, just like Photoshop or whatever, e.g. "multiply", "screen", etc.
	 */
	public var blend(default, set):BlendMode;

	/**
	 * Tints the whole sprite to a color (0xRRGGBB format) - similar to OpenGL vertex colors. You can use
	 * 0xAARRGGBB colors, but the alpha value will simply be ignored. To change the opacity use alpha. 
	 */
	public var color(default, set):FlxColor = 0xffffff;
	
	public var colorTransform(default, null):ColorTransform;
	
	/**
	 * Whether or not to use a colorTransform set via setColorTransform.
	 */
	public var useColorTransform(default, null):Bool = false;
	
	/**
	 * Clipping rectangle for this sprite.
	 * Changing it's properties doesn't change graphic of the sprite, so you should reapply clipping rect on sprite again.
	 * Set clipRect to null to discard graphic frame clipping 
	 */
	public var clipRect(default, set):FlxRect;
	
	/**
	 * Tranformation matrix for this sprite.
	 * Used only when matrixExposed is set to true
	 */
	public var transformMatrix(default, null):Matrix;
	
	/**
	 * Bool flag showing whether transformMatrix is used for rendering or not.
	 * False by default, which means that transformMatrix isn't used for rendering
	 */
	public var matrixExposed:Bool = false;
	
	/**
	 * The actual frame used for sprite rendering
	 */
	private var _frame:FlxFrame;
	
	#if FLX_RENDER_TILE
	private var _facingHorizontalMult:Int = 1;
	private var _facingVerticalMult:Int = 1;
	#end
	
	/**
	 * Rendering helper variable
	 */
	private var _halfSize:FlxPoint;
	
	/**
	 * These vars are being used for rendering in some of FlxSprite subclasses (FlxTileblock, FlxBar, 
	 * and FlxBitmapText) and for checks if the sprite is in camera's view.
	 */
	private var _sinAngle:Float = 0;
	private var _cosAngle:Float = 1;
	private var _angleChanged:Bool = true;
	/**
	 * Maps FlxObject direction constants to axis flips
	 */
	private var _facingFlip:Map<Int, {x:Bool, y:Bool}> = new Map<Int, {x:Bool, y:Bool}>();
	
	public function new(?Parent:FlxBaseSprite, ?Graphic:FlxGraphicAsset) 
	{
		super(Parent, Graphic);
	}
	
	override private function initVars():Void 
	{
		super.initVars();
		origin = FlxPoint.get();
		scale = FlxPoint.get(1, 1);
		_halfSize = FlxPoint.get();
		transformMatrix = new Matrix();
		colorTransform = new ColorTransform();
	}
	
	override public function destroy():Void 
	{
		super.destroy();
		
		origin = FlxDestroyUtil.put(origin);
		scale = FlxDestroyUtil.put(scale);
		_halfSize = FlxDestroyUtil.put(_halfSize);
		
		colorTransform = null;
		blend = null;
		transformMatrix = null;
		_frame = FlxDestroyUtil.destroy(_frame);
	}
	
	/**
	 * Helper function to set the graphic's dimensions by using scale, allowing you to keep the current aspect ratio
	 * should one of the Integers be <= 0. It might make sense to call updateHitbox() afterwards!
	 * 
	 * @param   Width    How wide the graphic should be. If <= 0, and a Height is set, the aspect ratio will be kept.
	 * @param   Height   How high the graphic should be. If <= 0, and a Width is set, the aspect ratio will be kept.
	 */
	public function setGraphicSize(Width:Int = 0, Height:Int = 0):Void
	{
		if (Width <= 0 && Height <= 0)
		{
			return;
		}
		
		var newScaleX:Float = Width / frameWidth;
		var newScaleY:Float = Height / frameHeight;
		scale.set(newScaleX, newScaleY);
		
		if (Width <= 0)
		{
			scale.x = newScaleY;
		}
		else if (Height <= 0)
		{
			scale.y = newScaleX;
		}	
	}
	
	/**
	 * Resets some important variables for sprite optimization and rendering.
	 */
	override private function resetHelpers():Void
	{
		super.resetHelpers();
		
		centerOrigin();
	#if FLX_RENDER_BLIT
		dirty = true;
		getFlxFrameBitmapData();
	#end
	}
	
	override public function update(elapsed:Float):Void 
	{
		if (parent != null)
			angle = parent.angle;
	}
	
	override public function draw():Void
	{
		if (_frame == null)
		{
			#if !FLX_NO_DEBUG
			loadGraphic(FlxTexture.fromClass(FlxGraphic.GraphicDefault));
			#else
			return;
			#end
		}
		
		if (alpha == 0 || parent == null || _frame.type == FlxFrameType.EMPTY)
			return;
		
		if (dirty)	//rarely 
			calcFrame();
		
		for (camera in cameras)
		{
			if (!camera.visible || !camera.exists || !isOnScreen(camera))
			{
				continue;
			}
			
			getScreenPosition(_point, camera).subtractPoint(offset);
			
			var cr:Float = colorTransform.redMultiplier;
			var cg:Float = colorTransform.greenMultiplier;
			var cb:Float = colorTransform.blueMultiplier;
			
			var simple:Bool = isSimpleRender(camera);
			if (simple)
			{
				if (isPixelPerfectRender(camera))
					_point.floor();
				
				_point.copyToFlash(_flashPoint);
				camera.copyPixels(_frame, framePixels, _flashRect, _flashPoint, cr, cg, cb, alpha, blend, antialiasing);
			}
			else
			{
				_frame.prepareMatrix(_matrix, FlxFrameAngle.ANGLE_0, flipX, flipY);
				_matrix.translate( -origin.x, -origin.y);
				_matrix.scale(scale.x, scale.y);
				
				updateTrig();					
				if (angle != 0)
					_matrix.rotateWithTrig(_cosAngle, _sinAngle);
				
				if (matrixExposed)
					_matrix.concat(transformMatrix);
				
				_point.add(origin.x, origin.y);
				if (isPixelPerfectRender(camera))
					_point.floor();
				
				_matrix.translate(_point.x, _point.y);
				camera.drawPixels(_frame, framePixels, _matrix, cr, cg, cb, alpha, blend, antialiasing);
			}
		}
	}
	
	/**
	 * Stamps / draws another FlxSprite onto this FlxSprite. 
	 * This function is NOT intended to replace draw()!
	 * 
	 * @param	Brush	The sprite you want to use as a brush or stamp or pen or whatever.
	 * @param	X		The X coordinate of the brush's top left corner on this sprite.
	 * @param	Y		They Y coordinate of the brush's top left corner on this sprite.
	 */
	public function stamp(Brush:FlxImage, X:Int = 0, Y:Int = 0):Void
	{
		if (this.texture == null || Brush.texture == null)
			throw "Cannot stamp to or from a FlxSprite with no graphics.";
		
		var bitmapData:BitmapData = Brush.getFlxFrameBitmapData();
		
		if (isSimpleRenderBlit()) // simple render
		{
			_flashPoint.x = X + frame.frame.x;
			_flashPoint.y = Y + frame.frame.y;
			_flashRect2.width = bitmapData.width;
			_flashRect2.height = bitmapData.height;
			texture.bitmap.copyPixels(bitmapData, _flashRect2, _flashPoint, null, null, true);
			_flashRect2.width = texture.bitmap.width;
			_flashRect2.height = texture.bitmap.height;
			#if FLX_RENDER_BLIT
			dirty = true;
			calcFrame();
			#end
		}
		else // complex render
		{
			_matrix.identity();
			_matrix.translate(-Brush.origin.x, -Brush.origin.y);
			_matrix.scale(Brush.scale.x, Brush.scale.y);
			if (Brush.parent.angle != 0)
			{
				_matrix.rotate(Brush.parent.angle * FlxAngle.TO_RAD);
			}
			_matrix.translate(X + frame.frame.x + Brush.origin.x, Y + frame.frame.y + Brush.origin.y);
			var brushBlend:BlendMode = Brush.blend;
			texture.bitmap.draw(bitmapData, _matrix, null, brushBlend, null, Brush.antialiasing);
			#if FLX_RENDER_BLIT
			dirty = true;
			calcFrame();
			#end
		}
	}
	
	/**
	 * Request (or force) that the sprite update the frame before rendering.
	 * Useful if you are doing procedural generation or other weirdness!
	 * 
	 * @param	Force	Force the frame to redraw, even if its not flagged as necessary.
	 */
	public function drawFrame(Force:Bool = false):Void
	{
		#if FLX_RENDER_BLIT
		if (Force || dirty)
		{
			dirty = true;
			calcFrame();
		}
		#else
		dirty = true;
		calcFrame(true);
		#end
	}
	
	/**
	 * Helper function that adjusts the offset automatically to center the bounding box within the graphic.
	 * 
	 * @param	AdjustPosition		Adjusts the actual X and Y position just once to match the offset change. Default is false.
	 */
	public function centerOffsets(AdjustPosition:Bool = false):Void
	{
		if (parent == null)
			return;
		
		offset.x = (frameWidth - parent.width) * 0.5;
		offset.y = (frameHeight - parent.height) * 0.5;
		if (AdjustPosition)
		{
			parent.x += offset.x;
			parent.y += offset.y;
		}
	}
	
	override public function updateHitbox():Void
	{
		if (parent == null)
			return;
		
		parent.width = Math.abs(scale.x) * frameWidth;
		parent.height = Math.abs(scale.y) * frameHeight;
		offset.set( -0.5 * (parent.width - frameWidth), -0.5 * (parent.height - frameHeight));
		centerOrigin();
	}

	/**
	 * Sets the sprite's origin to its center - useful after adjusting 
	 * scale to make sure rotations work as expected.
	 */
	public inline function centerOrigin():Void
	{
		origin.set(frameWidth * 0.5, frameHeight * 0.5);
	}
	
	/**
	 * Set sprite's color transformation with control over color offsets.
	 * Offsets only work with FLX_RENDER_BLIT.
	 * 
	 * @param	redMultiplier		The value for the red multiplier, in the range from 0 to 1. 
	 * @param	greenMultiplier		The value for the green multiplier, in the range from 0 to 1. 
	 * @param	blueMultiplier		The value for the blue multiplier, in the range from 0 to 1. 
	 * @param	alphaMultiplier		The value for the alpha transparency multiplier, in the range from 0 to 1. 
	 * @param	redOffset			The offset value for the red color channel, in the range from -255 to 255.
	 * @param	greenOffset			The offset value for the green color channel, in the range from -255 to 255. 
	 * @param	blueOffset			The offset for the blue color channel value, in the range from -255 to 255. 
	 * @param	alphaOffset			The offset for alpha transparency channel value, in the range from -255 to 255. 
	 */
	public function setColorTransform(redMultiplier:Float = 1.0, greenMultiplier:Float = 1.0, blueMultiplier:Float = 1.0,
		alphaMultiplier:Float = 1.0, redOffset:Float = 0, greenOffset:Float = 0, blueOffset:Float = 0, alphaOffset:Float = 0):Void
	{
		color = FlxColor.fromRGBFloat(redMultiplier, greenMultiplier, blueMultiplier).to24Bit();
		alpha = alphaMultiplier;
		
		colorTransform.redMultiplier = redMultiplier;
		colorTransform.greenMultiplier = greenMultiplier;
		colorTransform.blueMultiplier = blueMultiplier;
		colorTransform.alphaMultiplier = alphaMultiplier;
		colorTransform.redOffset = redOffset;
		colorTransform.greenOffset = greenOffset;
		colorTransform.blueOffset = blueOffset;
		colorTransform.alphaOffset = alphaOffset;
		
		useColorTransform = ((alpha != 1) || (color != 0xffffff) || (redOffset != 0) || (greenOffset != 0) || (blueOffset != 0) || (alphaOffset != 0));
		dirty = true;
	}
	
	private function updateColorTransform():Void
	{
		if ((alpha != 1) || (color != 0xffffff))
		{
			colorTransform.redMultiplier = color.redFloat;
			colorTransform.greenMultiplier = color.greenFloat;
			colorTransform.blueMultiplier = color.blueFloat;
			colorTransform.alphaMultiplier = alpha;
			useColorTransform = true;
		}
		else
		{
			colorTransform.redMultiplier = 1;
			colorTransform.greenMultiplier = 1;
			colorTransform.blueMultiplier = 1;
			colorTransform.alphaMultiplier = 1;
			useColorTransform = false;
		}
		
		dirty = true;
	}
	
	override public function pixelsOverlapPoint(point:FlxPoint, Mask:Int = 0xFF, ?Camera:FlxCamera):Bool
	{
		// TODO: support rotations and scale...
		
		if (Camera == null)
		{
			Camera = FlxG.camera;
		}
		getScreenPosition(_point, Camera);
		_point.x = _point.x - offset.x;
		_point.y = _point.y - offset.y;
		_flashPoint.x = (point.x - Camera.scroll.x) - _point.x;
		_flashPoint.y = (point.y - Camera.scroll.y) - _point.y;
		
		point.putWeak();
		
		// 1. Check to see if the point is outside of framePixels rectangle
		if (_flashPoint.x < 0 || _flashPoint.x > frameWidth || _flashPoint.y < 0 || _flashPoint.y > frameHeight)
		{
			return false;
		}
		else // 2. Check pixel at (_flashPoint.x, _flashPoint.y)
		{
			var frameData:BitmapData = getFlxFrameBitmapData();
			var pixelColor:FlxColor = frameData.getPixel32(Std.int(_flashPoint.x), Std.int(_flashPoint.y));
			var pixelAlpha:Int = (pixelColor >> 24) & 0xFF;
			return (pixelAlpha * alpha >= Mask);
		}
	}
	
	/**
	 * Internal function to update the current animation frame.
	 * 
	 * @param	RunOnCpp	Whether the frame should also be recalculated if we're on a non-flash target
	 */
	private function calcFrame(RunOnCpp:Bool = false):Void
	{
		if (frame == null)	
			loadGraphic(FlxTexture.fromClass(FlxGraphic.GraphicDefault));
		
		#if FLX_RENDER_TILE
		if (!RunOnCpp)
			return;
		#end
		
		getFlxFrameBitmapData();
	}
	
	/**
	 * Retrieves BitmapData of current FlxFrame. Updates framePixels.
	 */
	public function getFlxFrameBitmapData():BitmapData
	{
		if (_frame != null && dirty)
		{
			var doFlipX = flipX != _frame.flipX;
			var doFlipY = flipY != _frame.flipY;
			if (!doFlipX && !doFlipY && _frame.type == FlxFrameType.REGULAR)
			{
				framePixels = _frame.paint(framePixels, _flashPointZero, false, true);
			}
			else
			{
				framePixels = _frame.paintRotatedAndFlipped(framePixels, _flashPointZero, FlxFrameAngle.ANGLE_0, flipX, flipY, false, true);
			}
			
			if (useColorTransform)
			{
				framePixels.colorTransform(_flashRect, colorTransform);
			}
			
			dirty = false;
		}
		
		return framePixels;
	}
	
	/**
	 * Check and see if this object is currently on screen. Differs from FlxObject's implementation
	 * in that it takes the actual graphic into account, not just the hitbox or bounding box or whatever.
	 * 
	 * @param	Camera		Specify which game camera you want.  If null getScreenPosition() will just grab the first global camera.
	 * @return	Whether the object is on screen or not.
	 */
	override public function isOnScreen(?Camera:FlxCamera):Bool
	{
		if (parent == null)
			return false;
		
		if (Camera == null)
			Camera = FlxG.camera;
		
		var minX:Float = parent.x - offset.x - Camera.scroll.x * scrollFactor.x;
		var minY:Float = parent.y - offset.y - Camera.scroll.y * scrollFactor.y;
		
		if (angle == 0 && scale.x == 1 && scale.y == 1)
		{
			if (minX > Camera.width || minX + frameWidth < 0)
				return false;
			
			if (minY > Camera.height || minY + frameHeight < 0)
				return false;
		}
		else
		{
			var radiusX:Float = _halfSize.x;
			var radiusY:Float = _halfSize.y;
			
			var ox:Float = origin.x;
			if (ox != radiusX)
			{
				var x1:Float = Math.abs(ox);
				var x2:Float = Math.abs(frameWidth - ox);
				radiusX = Math.max(x2, x1);
			}
			
			var oy:Float = origin.y;
			if (oy != radiusY)
			{
				var y1:Float = Math.abs(oy);
				var y2:Float = Math.abs(frameHeight - oy);
				radiusY = Math.max(y2, y1);
			}
			
			radiusX *= Math.abs(scale.x);
			radiusY *= Math.abs(scale.y);
			var radius:Float = Math.max(radiusX, radiusY);
			radius *= FlxMath.SQUARE_ROOT_OF_TWO;
			
			minX += ox;
			var maxX:Float = minX + radius;
			minX -= radius;
			
			if (maxX < 0 || minX > Camera.width)
				return false;
			
			minY += oy;
			var maxY:Float = minY + radius;
			minY -= radius;
			
			if (maxY < 0 || minY > Camera.height)
				return false;
		}
		
		return true;
	}
	
	override public function isSimpleRenderBlit(?camera:FlxCamera):Bool
	{
		var result:Bool = angle == 0 && scale.x == 1 && scale.y == 1 && blend == null && matrixExposed == false;
		result = result && (camera != null ? isPixelPerfectRender(camera) : pixelPerfectRender);
		return result;
	}
	
	/**
	 * Set how a sprite flips when facing in a particular direction.
	 * 
	 * @param	Direction Use constants from FlxObject: LEFT, RIGHT, UP, and DOWN.
	 * 			These may be combined with the bitwise OR operator.
	 * 			E.g. To make a sprite flip horizontally when it is facing both UP and LEFT,
	 * 			use setFacingFlip(FlxObject.LEFT | FlxObject.UP, true, false);
	 * @param	FlipX Whether to flip the sprite on the X axis
	 * @param	FlipY Whether to flip the sprite on the Y axis
	 */
	public inline function setFacingFlip(Direction:Int, FlipX:Bool, FlipY:Bool):Void
	{
		_facingFlip.set(Direction, {x: FlipX, y: FlipY});
	}
	
	override private function set_frame(Value:FlxFrame):FlxFrame
	{
		frame = super.set_frame(Value);
		
		if (frame != null && clipRect != null)
		{
			_frame = frame.clipTo(clipRect, _frame);
		}
		else if (frame != null)
		{
			_frame = frame.copyTo(_frame);
		}
		
		return frame;
	}
	
	private function set_facing(Direction:Int):Int
	{		
		var flip = _facingFlip.get(Direction);
		if (flip != null)
		{
			flipX = flip.x;
			flipY = flip.y;
		}
		
		return facing = Direction;
	}
	
	private function set_alpha(Alpha:Float):Float
	{
		alpha = FlxMath.bound(Alpha, 0, 1);
		updateColorTransform();
		return alpha;
	}
	
	private function set_color(Color:FlxColor):Int
	{
		if (color == Color)
		{
			return Color;
		}
		color = Color;
		updateColorTransform();
		return color;
	}
	
	private function set_angle(Value:Float):Float
	{
		_angleChanged = (angle != Value) || _angleChanged;
		return angle = Value;
	}
	
	private inline function updateTrig():Void
	{
		if (_angleChanged)
		{
			var radians:Float = angle * FlxAngle.TO_RAD;
			_sinAngle = Math.sin(radians);
			_cosAngle = Math.cos(radians);
			_angleChanged = false; 
		}
	}
	
	private function set_blend(Value:BlendMode):BlendMode 
	{
		return blend = Value;
	}
	
	private function set_clipRect(rect:FlxRect):FlxRect
	{
		if (rect != null)
		{
			clipRect = rect.round();
		}
		else
		{
			clipRect = null;
		}
		
		if (frames != null)
		{
			frame = frames.frames[frameIndex];
		}
		
		return rect;
	}
	
	/**
	 * Frames setter. Used by "loadGraphic" methods, but you can load generated frames yourself 
	 * (this should be even faster since engine doesn't need to do bunch of additional stuff).
	 * 
	 * @param	Frames	frames to load into this sprite.
	 * @return	loaded frames.
	 */
	override private function set_frames(Frames:FlxFramesCollection):FlxFramesCollection
	{
		frames = super.set_frames(Frames);
		clipRect = null;
		return Frames;
	}
	
	private function set_flipX(Value:Bool):Bool
	{
		#if FLX_RENDER_TILE
		_facingHorizontalMult = Value ? -1 : 1;
		#end
		dirty = (flipX != Value) || dirty;
		return flipX = Value;
	}
	
	private function set_flipY(Value:Bool):Bool
	{
		#if FLX_RENDER_TILE
		_facingVerticalMult = Value ? -1 : 1;
		#end
		dirty = (flipY != Value) || dirty;
		return flipY = Value;
	}
}