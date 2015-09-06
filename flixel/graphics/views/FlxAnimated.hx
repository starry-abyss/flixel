package flixel.graphics.views;

import flixel.animation.FlxAnimationController;
import flixel.graphics.frames.FlxFramesCollection;
import flixel.math.FlxRect;
import flixel.system.FlxAssets.FlxGraphicAsset;
import flixel.util.FlxDestroyUtil;

/**
 * ...
 * @author Zaphod
 */
class FlxAnimated extends FlxImage
{
	/**
	 * Class that handles adding and playing animations on this sprite.
	 */
	public var animation:FlxAnimationController;
	
	public function new(?Parent:FlxBaseSprite<Dynamic>, ?Graphic:FlxGraphicAsset) 
	{
		super(Parent, Graphic);
	}
	
	override function initVars():Void 
	{
		super.initVars();
		animation = new FlxAnimationController(this);
	}
	
	override public function destroy():Void 
	{
		super.destroy();
		animation = FlxDestroyUtil.destroy(animation);
	}
	
	override public function update(elapsed:Float):Void 
	{
		super.update(elapsed);
		updateAnimation(elapsed);
	}
	
	/**
	 * This is separated out so it can be easily overriden
	 */
	private function updateAnimation(elapsed:Float):Void
	{
		animation.update(elapsed);
	}
	
	/**
	 * Sets frames and allows you to save animations in sprite's animation controller
	 * 
	 * @param	Frames				Frames collection to set for this sprite
	 * @param	saveAnimations		Whether to save animations in animation controller or not
	 * @return	This sprite with loaded frames
	 */
	public function setFrames(Frames:FlxFramesCollection, saveAnimations:Bool = true):FlxAnimated
	{
		if (saveAnimations)
		{
			var animations = animation._animations;
			var reverse:Bool = false;
			var index:Int = 0;
			var frameIndex:Int = animation.frameIndex;
			var currName:String = null;
			
			if (animation.curAnim != null)
			{
				reverse = animation.curAnim.reversed;
				index = animation.curAnim.curFrame;
				currName = animation.curAnim.name;
			}
			
			animation._animations = null;
			this.frames = Frames;
			frame = frames.frames[frameIndex];
			animation._animations = animations;
			
			if (currName != null)
				animation.play(currName, false, reverse, index);
		}
		else
		{
			this.frames = Frames;
		}
		
		return this;
	}
	
	override private function set_clipRect(rect:FlxRect):FlxRect
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
			frame = frames.frames[animation.frameIndex];
		}
		
		return rect;
	}
	
	override private function set_frames(Frames:FlxFramesCollection):FlxFramesCollection
	{
		if (animation != null)
			animation.destroyAnimations();
			
		super.set_frames(Frames);
		
		if (Frames != null)
			animation.frameIndex = 0;
		
		return Frames;
	}
}