﻿//
// 
//  NativeAudioAsset.m
//  NativeAudioAsset
//
//  Created by Sidney Bofah on 2014-06-26.
//

#import "NativeAudioAsset.h"

@implementation NativeAudioAsset

static const CGFloat FADE_STEP = 0.05;
static const CGFloat FADE_DELAY = 0.08;

static AVAudioEngine *engine = [[AVAudioEngine alloc] init];
static AVAudioMixer *mixer = [engine mainMixerNode];

-(id) init:(NSString*) path withVolume:(NSNumber*) volume withFadeDelay:(NSNumber *)delay
{
    self = [super init];
    if(self) {        
        NSURL *pathURL = [NSURL fileURLWithPath : path];
		//NSData *data = [[NSFileManager defaultManager] contentsAtPath:pathURL];
		file = [[AVAudioFile alloc] initForReading:pathURL];
        player = [[AVAudioPlayerNode alloc] init];

        player.volume = volume.floatValue;
         
        if(delay)
        {
            fadeDelay = delay;
        }
        else {
            fadeDelay = [NSNumber numberWithFloat:FADE_DELAY];
        }
            
        initialVolume = volume;
    }
    return(self);
}

- (void) play
{
	[player setCurrentTime:0.0];
	player.numberOfLoops = 0;
	[player play];
}


// The volume is increased repeatedly by the fade step amount until the last step where the audio is stopped.
// The delay determines how fast the decrease happens
- (void)playWithFade
{

    if (!player.isPlaying)
    {
        [self play];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self performSelector:@selector(playWithFade) withObject:nil afterDelay:fadeDelay.floatValue];
        });
    }
    else
    {
        if(player.volume < initialVolume.floatValue)
        {
            player.volume += FADE_STEP;
            dispatch_async(dispatch_get_main_queue(), ^{
                [self performSelector:@selector(playWithFade) withObject:nil afterDelay:fadeDelay.floatValue];
            });
        }
    }
}

- (void) stop
{
        [player stop];
  
}

// The volume is decreased repeatedly by the fade step amount until the volume reaches the configured level.
// The delay determines how fast the increase happens
- (void)stopWithFade
{
    if (player.isPlaying && player.volume > FADE_STEP) {
        player.volume -= FADE_STEP;
        [self performSelector:@selector(stopWithFade) withObject:nil afterDelay:fadeDelay.floatValue];
    } else {
        // Stop and get the sound ready for playing again
        [player stop];
        player.volume = initialVolume.floatValue;
        player.currentTime = 0;
    }
}

- (void) loop
{
    [self stop];
    [player setCurrentTime:0.0];
    player.numberOfLoops = -1;
    [player play];
}

- (void) unload 
{
    [self stop];
    player = nil;
}

- (void) setVolume:(NSNumber*) volume;
{
    [player setVolume:volume.floatValue];
}

- (void) setRate:(NSNumber*) rate;
{
 if (!player.enableRate) { 
	 player.enableRate = YES;
 };

 player.rate = rate.floatValue;
   // [player setVolume:volume.floatValue];
}

- (void) setCallbackAndId:(CompleteCallback)cb audioId:(NSString*)aID
{
    self->audioId = aID;
    self->finished = cb;
}

- (void) audioPlayerDidFinishPlaying:(AVAudioPlayer *)ap successfully:(BOOL)flag
{
    if (self->finished) {
        self->finished(self->audioId);
    }
}

- (void) audioPlayerDecodeErrorDidOccur:(AVAudioPlayer *)ap error:(NSError *)error
{
    if (self->finished) {
        self->finished(self->audioId);
    }
}

@end
