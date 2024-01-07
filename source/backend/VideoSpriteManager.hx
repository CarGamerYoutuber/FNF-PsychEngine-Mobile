package backend;

#if VIDEOS_ALLOWED 
#if hxCodec
#if (hxCodec >= "3.0.0") import hxcodec.flixel.FlxVideoSprite as VideoSprite;
#elseif (hxCodec >= "2.6.1") import hxcodec.VideoSprite;
#elseif (hxCodec == "2.6.0") import VideoSprite;
#else import vlc.MP4Sprite as VideoSprite; #end
#elseif hxvlc
import hxvlc.flixel.FlxVideoSprite as VideoSprite;
#end
#end
import states.PlayState;
import haxe.extern.EitherType;
import flixel.util.FlxSignal;
import haxe.io.Path;


#if VIDEOS_ALLOWED

class VideoSpriteManager extends VideoSprite {
    
    public var playbackRate(get, set):EitherType<Single, Float>;
    public var paused(default, set):Bool = false;
    public var onVideoEnd:FlxSignal;
    public var onVideoStart:FlxSignal;

    var daX:Dynamic;
    var daY:Dynamic;
    
    public function new(x:Float = 0, y:Float = 0 #if (hxCodec < "2.6.0" && hxCodec), width:Float = 1280, height:Float = 720, autoScale:Bool = true #end){

        #if hxvlc
        daX = Std.int(x); // not my fault X and Y are int in hxvlc
        daY = Std.int(y);
        #elseif hxCodec
        daX = x;
        daY = y;
        #end

        super(daX, daY #if (hxCodec < "2.6.0" && hxCodec), width, height, autoScale #end);
        
        onVideoEnd = new FlxSignal();
        onVideoEnd.add(function(){
            destroy();
        });
        onVideoStart = new FlxSignal();
        #if (hxCodec >= "3.0.0" || hxvlc)
        onVideoEnd.add(destroy);
        bitmap.onOpening.add(function(){
            onVideoStart.dispatch();
        });
        bitmap.onEndReached.add(function(){
            onVideoEnd.dispatch();
        });
        #elseif (hxCodec < "3.0.0" && hxCodec)
        openingCallback = function(){
            onVideoStart.dispatch();
        };
        finishCallback = function(){
            onVideoEnd.dispatch(); // using  bitmap.finishCallback = onVideoEnd.dispatch was giving a null function pointer
        };
        #end
    }
    
     public function startVideo(path:String, loop:Bool = false #if hxvlc ,?options:Array<String> #end) {
        #if (hxCodec >= "3.0.0" && hxCodec)
        play(path, loop);
        #elseif (hxCodec < "3.0.0" && hxCodec)
        playVideo(path, loop, false);
        #elseif hxvlc
        var repeats = 0;
        if(loop)
            repeats = 100 * 100;
        load(path, repeats, options);
        new FlxTimer().start(0.001, function(tmr:FlxTimer) {
            play();
        });
        #end
    }

    @:noCompletion
    private function set_paused(shouldPause:Bool){
        #if (hxCodec >= "3.0.0" || hxvlc)
        var parentResume = resume;
        var parentPause = pause;
        #elseif(hxCodec < "3.0.0" && hxCodec)
        var parentResume = bitmap.resume;
        var parentPause = bitmap.pause;
        #end

        if(shouldPause){
            #if (hxCodec >= "3.0.0" || hxvlc)
            pause();
            #elseif (hxCodec < "3.0.0" && hxCodec)
            bitmap.pause();
            #end
    
            if(FlxG.autoPause) {
                if(FlxG.signals.focusGained.has(parentResume))
                    FlxG.signals.focusGained.remove(parentResume);
    
                if(FlxG.signals.focusLost.has(parentPause))
                    FlxG.signals.focusLost.remove(parentPause);
            }
        } else {
            #if (hxCodec >= "3.0.0" || hxvlc)
            resume();
            #elseif (hxCodec < "3.0.0" && hxCodec)
            bitmap.resume();
            #end

            if(FlxG.autoPause) {
                FlxG.signals.focusGained.add(parentResume);
                FlxG.signals.focusLost.add(parentPause);
            }
        }
        return shouldPause;
    }

    @:noCompletion
    private function set_playbackRate(multi:EitherType<Single, Float>){
        bitmap.rate = multi;
        return multi;
    }

    @:noCompletion
    private function get_playbackRate():Float {
        return bitmap.rate;
    }

    public function altDestroy() {
        super.destroy();
        #if (hxCodec < "3.0.0" && hxCodec)
        bitmap.finishCallback = null;
        bitmap.onEndReached();
        #end
    }
    #end
}
