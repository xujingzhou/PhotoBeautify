//
//  VideoEffect
//  PhotoBeautify
//
//  Created by Johnny Xu(徐景周) on 7/23/14.
//  Copyright (c) 2014 Future Studio. All rights reserved.
//

#import "VideoEffect.h"
#import "VideoBuilder.h"
#import "VideoThemes.h"
#import "CommonDefine.h"
#import <AssetsLibrary/AssetsLibrary.h>

#pragma mark - Private
@interface VideoEffect()
{
    AVAssetExportSession *_exportSession;
    NSTimer *_timerEffect;
    
    NSMutableDictionary *_themesDic;
    
    VideoBuilder *_videoBuilder;
}

@property (retain, nonatomic) VideoBuilder *videoBuilder;
@property (retain, nonatomic) NSMutableDictionary *themesDic;
@property (weak, nonatomic) id delegate;

@property (retain, nonatomic) AVAssetExportSession *exportSession;
@property (retain, nonatomic) NSTimer *timerEffect;

@end


@implementation VideoEffect

@synthesize exportSession = _exportSession;
@synthesize timerEffect = _timerEffect;

@synthesize delegate = _delegate;
@synthesize themeCurrentType = _themeCurrentType;
@synthesize themesDic = _themesDic;
@synthesize videoBuilder = _videoBuilder;

#pragma mark - Init instance
- (id) initWithDelegate:(id)delegate
{
	if (self = [super init])
    {
        _delegate = delegate;
        _exportSession = nil;
        _timerEffect = nil;
        _themesDic = nil;
        
        // Default theme
        self.themeCurrentType = kThemeButterfly;
        
        self.videoBuilder = [[VideoBuilder alloc] init];
        
        self.themesDic = [[VideoThemesData sharedInstance] getThemeData];
	}
    
	return self;
}

- (void) clearAll
{
    if (_videoBuilder)
    {
        _videoBuilder = nil;
    }
    
    if (_exportSession)
    {
        _exportSession = nil;
    }
    
    if (_timerEffect)
    {
        [_timerEffect invalidate];
        _timerEffect = nil;
    }
}

- (void)dealloc
{
    [self clearAll];
    
//    [super dealloc];
}

- (void) pause
{
    if (_exportSession.progress < 1.0)
    {
        [_exportSession cancelExport];
    }
}

- (void) resume
{
    [self clearAll];
}

#pragma mark - Common function
//- (void) writeExportedVideoToAssetsLibrary:(NSString *)outputURL
//{
//	NSURL *exportURL = [NSURL fileURLWithPath:outputURL];
//	ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
//	if ([library videoAtPathIsCompatibleWithSavedPhotosAlbum:exportURL])
//    {
//		[library writeVideoAtPathToSavedPhotosAlbum:exportURL completionBlock:^(NSURL *assetURL, NSError *error)
//         {
//             dispatch_async(dispatch_get_main_queue(), ^{
//                 if (error)
//                 {
//                     if (_delegate && [_delegate respondsToSelector:@selector(AVAssetExportMP4ToAlbumStatusFailed:)])
//                     {
//                         [_delegate performSelector:@selector(AVAssetExportMP4ToAlbumStatusFailed:) withObject:nil];
//                     }
//                 }
//                 else
//                 {
//                     if (_delegate && [_delegate respondsToSelector:@selector(AVAssetExportMP4ToAlbumStatusCompleted:)])
//                     {
//                         [_delegate performSelector:@selector(AVAssetExportMP4ToAlbumStatusCompleted:) withObject:nil];
//                     }
//                 }
//                 
//#if !TARGET_IPHONE_SIMULATOR
//                 [[NSFileManager defaultManager] removeItemAtURL:exportURL error:nil];
//#endif
//             });
//         }];
//	}
//    else
//    {
//		NSLog(@"Video could not be exported to camera roll.");
//	}
//
//  [library release];
//}

- (UIImage *)imageFromAsset:(ALAsset *)asset
{
    ALAssetRepresentation *representation = [asset defaultRepresentation];
    return [UIImage imageWithCGImage:representation.fullResolutionImage
                               scale:[representation scale]
                         orientation:(UIImageOrientation)[representation orientation]];
}

#pragma mark - Build video
- (void)image2Video:(NSMutableArray*)photos exportVideoFile:(NSString *)exportVideoFile highestQuality:(BOOL)highestQuality
{
    if (self.themeCurrentType == kThemeNone)
    {
        NSLog(@"Theme is empty!");
        
        return;
    }
    
    VideoThemes *themeCurrent = nil;
    if (self.themeCurrentType != kThemeNone && [self.themesDic count] >= self.themeCurrentType)
    {
        themeCurrent = [self.themesDic objectForKey:[NSNumber numberWithInt:self.themeCurrentType]];
    }
    
    [self buildVideoEffectsToMP4:exportVideoFile inputVideoFile:themeCurrent.bgVideoFile photos:photos highestQuality:highestQuality];
}

// Convert 'space' char
- (NSString *)returnFormatString:(NSString *)str
{
    return [str stringByReplacingOccurrencesOfString:@" " withString:@""];
}
                       
// Add effect
- (BOOL)buildVideoEffectsToMP4:(NSString *)exportVideoFile inputVideoFile:(NSString *)inputVideoFile photos:(NSMutableArray*)photos  highestQuality:(BOOL)highestQuality
{
    // 1.
    if (isStringEmpty(inputVideoFile) || isStringEmpty(exportVideoFile) || (!photos || [photos count]<1))
    {
        NSLog(@"Input filename or Output filename is invalied for convert to Mp4!");
        return NO;
    }
    
    NSString *fileName = [inputVideoFile stringByDeletingPathExtension];
    NSLog(@"%@",fileName);
    NSString *fileExt = [inputVideoFile pathExtension];
    NSLog(@"%@",fileExt);
    NSURL *inputVideoURL = [[NSBundle mainBundle] URLForResource:fileName withExtension:fileExt];
    
    
    // 2. Create the composition and tracks
    AVURLAsset *asset = [[AVURLAsset alloc] initWithURL:inputVideoURL options:nil];
    NSParameterAssert(asset);
    if(asset == nil || [[asset tracksWithMediaType:AVMediaTypeVideo] count]<1)
    {
        NSLog(@"Input video is invalid!");
        return NO;
    }
   
    AVMutableComposition *composition = [AVMutableComposition composition];
    AVMutableCompositionTrack *videoTrack = [composition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
    AVMutableCompositionTrack *audioTrack = [composition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
    
    NSArray *assetVideoTracks = [asset tracksWithMediaType:AVMediaTypeVideo];
    if (assetVideoTracks.count <= 0)
    {
        // Retry once
        asset = [[AVURLAsset alloc] initWithURL:inputVideoURL options:nil];
        assetVideoTracks = [asset tracksWithMediaType:AVMediaTypeVideo];
        if ([assetVideoTracks count] <= 0)
        {
            if (asset)
            {
                asset = nil;
            }
            
            NSLog(@"Error reading the transformed video track");
            return NO;
        }
    }
    
    // 3. Insert the tracks in the composition's tracks
    AVAssetTrack *assetVideoTrack = [assetVideoTracks firstObject];
    [videoTrack insertTimeRange:assetVideoTrack.timeRange ofTrack:assetVideoTrack atTime:CMTimeMake(0, 1) error:nil];
    [videoTrack setPreferredTransform:assetVideoTrack.preferredTransform];
    
    if ([[asset tracksWithMediaType:AVMediaTypeAudio] count]>0)
    {
        AVAssetTrack *assetAudioTrack = [[asset tracksWithMediaType:AVMediaTypeAudio] objectAtIndex:0];
        [audioTrack insertTimeRange:assetAudioTrack.timeRange ofTrack:assetAudioTrack atTime:CMTimeMake(0, 1) error:nil];
    }
    else
    {
         NSLog(@"Reminder: video hasn't audio!");
    }
    
    // 4. Effects
    CALayer *parentLayer = [CALayer layer];
    CALayer *videoLayer = [CALayer layer];
    parentLayer.frame = CGRectMake(0, 0, assetVideoTrack.naturalSize.width, assetVideoTrack.naturalSize.height);
    videoLayer.frame = CGRectMake(0, 0, assetVideoTrack.naturalSize.width, assetVideoTrack.naturalSize.height);
    [parentLayer addSublayer:videoLayer];
    
    VideoThemes *themeCurrent = nil;
    if (self.themeCurrentType != kThemeNone && [self.themesDic count] >= self.themeCurrentType)
    {
        themeCurrent = [self.themesDic objectForKey:[NSNumber numberWithInt:self.themeCurrentType]];
    }
    
    // Animation effects
    NSMutableArray *animatedLayers = [[NSMutableArray alloc] initWithCapacity:[[themeCurrent animationActions] count]];
    if (themeCurrent && [[themeCurrent animationActions] count]>0)
    {
        for (NSNumber *animationAction in [themeCurrent animationActions])
        {
            CALayer *animatedLayer = nil;
            switch ([animationAction intValue])
            {
                case kAnimationFireworks:
                {
                    NSTimeInterval timeInterval = 0.1;
                    animatedLayer = [_videoBuilder buildEmitterFireworks:assetVideoTrack.naturalSize startTime:timeInterval];
                    if (animatedLayer)
                    {
                        [animatedLayers addObject:(id)animatedLayer];
                    }
                    
                    break;
                }
                case kAnimationSnow:
                {
                    NSTimeInterval timeInterval = 0.1;
                    animatedLayer = [_videoBuilder buildEmitterSnow:assetVideoTrack.naturalSize startTime:timeInterval];
                    if (animatedLayer)
                    {
                        [animatedLayers addObject:(id)animatedLayer];
                    }
                    
                    break;
                }
                case kAnimationSnow2:
                {
                    NSTimeInterval timeInterval = 0.1;
                    animatedLayer = [_videoBuilder buildEmitterSnow2:assetVideoTrack.naturalSize startTime:timeInterval];
                    if (animatedLayer)
                    {
                        [animatedLayers addObject:(id)animatedLayer];
                    }
                    
                    break;
                }
                case kAnimationHeart:
                {
                    NSTimeInterval timeInterval = 0.1;
                    animatedLayer = [_videoBuilder buildEmitterHeart:assetVideoTrack.naturalSize startTime:timeInterval];
                    if (animatedLayer)
                    {
                        [animatedLayers addObject:(id)animatedLayer];
                    }
                    
                    break;
                }
                case kAnimationRing:
                {
                    NSTimeInterval timeInterval = 0.1;
                    animatedLayer = [_videoBuilder buildEmitterRing:assetVideoTrack.naturalSize startTime:timeInterval];
                    if (animatedLayer)
                    {
                        [animatedLayers addObject:(id)animatedLayer];
                    }
                    
                    break;
                }
                case kAnimationStar:
                {
                    NSTimeInterval timeInterval = 0.1;
                    animatedLayer = [_videoBuilder buildEmitterStar:assetVideoTrack.naturalSize startTime:timeInterval];
                    if (animatedLayer)
                    {
                        [animatedLayers addObject:(id)animatedLayer];
                    }
                    
                    break;
                }
                case kAnimationMoveDot:
                {
                    NSTimeInterval timeInterval = 0.1;
                    animatedLayer = [_videoBuilder buildEmitterMoveDot:assetVideoTrack.naturalSize position:CGPointMake(160, 240) startTime:timeInterval];
                    if (animatedLayer)
                    {
                        [animatedLayers addObject:(id)animatedLayer];
                    }
                    
                    break;
                }
                case kAnimationTextSparkle:
                {
                    if (!isStringEmpty(themeCurrent.textSparkle))
                    {
                        NSTimeInterval startTime = 10;
                        animatedLayer = [_videoBuilder buildEmitterSparkle:assetVideoTrack.naturalSize text:themeCurrent.textSparkle startTime:startTime];
                        if (animatedLayer)
                        {
                            [animatedLayers addObject:(id)animatedLayer];
                        }
                    }
                    
                    break;
                }
                case kAnimationTextStar:
                {
                    if (!isStringEmpty(themeCurrent.textStar))
                    {
                        NSTimeInterval startTime = 0.1;
                        animatedLayer = [_videoBuilder buildAnimationStarText:assetVideoTrack.naturalSize text:themeCurrent.textStar startTime:startTime];
                        if (animatedLayer)
                        {
                            [animatedLayers addObject:(id)animatedLayer];
                        }
                    }
                    
                    break;
                }
                case kAnimationSky:
                {
                    NSTimeInterval timeInterval = 0.1;
                    animatedLayer = [_videoBuilder buildEmitterSky:assetVideoTrack.naturalSize startTime:timeInterval];
                    if (animatedLayer)
                    {
                        [animatedLayers addObject:(id)animatedLayer];
                    }
                    
                    break;
                }
                case kAnimationMeteor:
                {
                    NSTimeInterval timeInterval = 0.1;
                    for (int i=0; i<2; ++i)
                    {
                        animatedLayer = [_videoBuilder buildEmitterMeteor:assetVideoTrack.naturalSize startTime:timeInterval pathN:i];
                        if (animatedLayer)
                        {
                            [animatedLayers addObject:(id)animatedLayer];
                        }
                    }
                    
                    break;
                }
                case kAnimationRain:
                {
                    animatedLayer = [_videoBuilder buildEmitterRain:assetVideoTrack.naturalSize];
                    if (animatedLayer)
                    {
                        [animatedLayers addObject:(id)animatedLayer];
                    }
                    
                    break;
                }
                case kAnimationFlower:
                {
                    NSTimeInterval timeInterval = 0.1;
                    animatedLayer = [_videoBuilder buildEmitterFlower:assetVideoTrack.naturalSize startTime:timeInterval];
                    if (animatedLayer)
                    {
                        [animatedLayers addObject:(id)animatedLayer];
                    }
                    
                    break;
                }
                case kAnimationFire:
                {
                    if (!isStringEmpty(themeCurrent.imageFile))
                    {
                        UIImage *image = [UIImage imageNamed:themeCurrent.imageFile];
                        animatedLayer = [_videoBuilder buildEmitterFire:assetVideoTrack.naturalSize position:CGPointMake(assetVideoTrack.naturalSize.width/2.0, image.size.height+10)];
                        if (animatedLayer)
                        {
                            [animatedLayers addObject:(id)animatedLayer];
                        }
                    }
                    break;
                }
                case kAnimationSmoke:
                {
                    animatedLayer = [_videoBuilder buildEmitterSmoke:assetVideoTrack.naturalSize position:CGPointMake(assetVideoTrack.naturalSize.width/2.0, 105)];
                    if (animatedLayer)
                    {
                        [animatedLayers addObject:(id)animatedLayer];
                    }
                    
                    break;
                }
                case kAnimationSpark:
                {
                    animatedLayer = [_videoBuilder buildEmitterSpark:assetVideoTrack.naturalSize];
                    if (animatedLayer)
                    {
                        [animatedLayers addObject:(id)animatedLayer];
                    }
                    
                    break;
                }
                case kAnimationBirthday:
                {
                    animatedLayer = [_videoBuilder buildEmitterBirthday:assetVideoTrack.naturalSize];
                    if (animatedLayer)
                    {
                        [animatedLayers addObject:(id)animatedLayer];
                    }
                    
                    break;
                }
                case kAnimationImage:
                {
                    if (!isStringEmpty(themeCurrent.imageFile))
                    {
                        UIImage *image = [UIImage imageNamed:themeCurrent.imageFile];
                        animatedLayer = [_videoBuilder buildImage:assetVideoTrack.naturalSize image:themeCurrent.imageFile position:CGPointMake(assetVideoTrack.naturalSize.width/2, image.size.height/2)];
                        
                        if (animatedLayer)
                        {
                            [animatedLayers addObject:(id)animatedLayer];
                        }
                    }
                    
                    break;
                }
                case kAnimationImageArray:
                {
                    if(themeCurrent.animationImages)
                    {
                        UIImage *image = [UIImage imageWithCGImage:(CGImageRef)themeCurrent.animationImages[0]];
                        animatedLayer = [_videoBuilder buildAnimationImages:assetVideoTrack.naturalSize imagesArray:themeCurrent.animationImages position:CGPointMake(assetVideoTrack.naturalSize.width/2, image.size.height/2)];
                        
                        if (animatedLayer)
                        {
                            [animatedLayers addObject:(id)animatedLayer];
                        }
                    }
                    
                    break;
                }
                case kAnimationVideoFrame:
                {
                    if (themeCurrent.keyFrameTimes  && [[themeCurrent keyFrameTimes] count]>0)
                    {
                        for (NSNumber *timeSecond in themeCurrent.keyFrameTimes)
                        {
                            CMTime time = CMTimeMake([timeSecond doubleValue], 1);
                            if (CMTIME_COMPARE_INLINE([asset duration], >, time))
                            {
                                animatedLayer = [_videoBuilder buildVideoFrameImage:assetVideoTrack.naturalSize videoFile:inputVideoURL startTime:time];
                                if (animatedLayer)
                                {
                                    [animatedLayers addObject:(id)animatedLayer];
                                }
                            }
                        }
                    }
                    
                    break;
                }
                case kAnimationSpotlight:
                {
                    NSTimeInterval timeInterval = 0.1;
                    animatedLayer = [_videoBuilder buildSpotlight:assetVideoTrack.naturalSize startTime:timeInterval];
                    if (animatedLayer)
                    {
                        [animatedLayers addObject:(id)animatedLayer];
                    }
                    
                    break;
                }
                case kAnimationScrollScreen:
                {
                    NSTimeInterval timeInterval = 0.1;
                    animatedLayer = [_videoBuilder buildAnimationScrollScreen:assetVideoTrack.naturalSize startTime:timeInterval];
                    if (animatedLayer)
                    {
                        [animatedLayers addObject:(id)animatedLayer];
                    }
                    
                    break;
                }
                case kAnimationTextScroll:
                {
                    if (themeCurrent.scrollText && [[themeCurrent scrollText] count] > 0)
                    {
                        NSArray *startYPoints = [NSArray arrayWithObjects:[NSNumber numberWithFloat:assetVideoTrack.naturalSize.height/3], [NSNumber numberWithFloat:assetVideoTrack.naturalSize.height/2], [NSNumber numberWithFloat:assetVideoTrack.naturalSize.height*2/3], nil];
                        
                        NSTimeInterval timeInterval = 0.0;
                        for (NSString *text in themeCurrent.scrollText)
                        {
                            animatedLayer = [_videoBuilder buildAnimatedScrollText:assetVideoTrack.naturalSize text:text startPoint:CGPointMake(assetVideoTrack.naturalSize.width, [startYPoints[arc4random()%(int)3] floatValue]) startTime:timeInterval];
                            
                            if (animatedLayer)
                            {
                                [animatedLayers addObject:(id)animatedLayer];
                                
                                timeInterval += 2.0;
                            }
                        }
                    }
                    
                    break;
                }
                case kAnimationBlackWhiteDot:
                {
                    for (int i=0; i<2; ++i)
                    {
                        animatedLayer = [_videoBuilder buildEmitterBlackWhiteDot:assetVideoTrack.naturalSize positon:CGPointMake(assetVideoTrack.naturalSize.width/2, i*assetVideoTrack.naturalSize.height) startTime:2.0f];
                        if (animatedLayer)
                        {
                            [animatedLayers addObject:(id)animatedLayer];
                        }
                    }
                    
                    break;
                }
                case kAnimationScrollLine:
                {
                    NSTimeInterval timeInterval = 0.1;
                    animatedLayer = [_videoBuilder buildAnimatedScrollLine:assetVideoTrack.naturalSize startTime:timeInterval lineHeight:30.0f image:nil];
                    if (animatedLayer)
                    {
                        [animatedLayers addObject:(id)animatedLayer];
                    }
                    
                    break;
                }
                case kAnimationRipple:
                {
                    NSTimeInterval timeInterval = 1.0;
                    animatedLayer = [_videoBuilder buildAnimationRipple:assetVideoTrack.naturalSize centerPoint:CGPointMake(assetVideoTrack.naturalSize.width/2, assetVideoTrack.naturalSize.height/2) radius:assetVideoTrack.naturalSize.width/2 startTime:timeInterval];
                    
                    if (animatedLayer)
                    {
                        [animatedLayers addObject:(id)animatedLayer];
                    }
                    
                    break;
                }
                case kAnimationSteam:
                {
                    animatedLayer = [_videoBuilder buildEmitterSteam:assetVideoTrack.naturalSize positon:CGPointMake(assetVideoTrack.naturalSize.width/2, assetVideoTrack.naturalSize.height - assetVideoTrack.naturalSize.height/8)];
                    if (animatedLayer)
                    {
                        [animatedLayers addObject:(id)animatedLayer];
                    }
                    
                    break;
                }
                case kAnimationTextGradient:
                {
                    if (!isStringEmpty(themeCurrent.textGradient))
                    {
                        NSTimeInterval timeInterval = 1.0;
                        animatedLayer = [_videoBuilder buildGradientText:assetVideoTrack.naturalSize positon:CGPointMake(assetVideoTrack.naturalSize.width/2, assetVideoTrack.naturalSize.height - assetVideoTrack.naturalSize.height/4) text:themeCurrent.textGradient startTime:timeInterval];
                        if (animatedLayer)
                        {
                            [animatedLayers addObject:(id)animatedLayer];
                        }
                    }
                    
                    break;
                }
                case kAnimationFlashScreen:
                {
                    for (int timeSecond=2; timeSecond<12; timeSecond+=3)
                    {
                        CMTime time = CMTimeMake(timeSecond, 1);
                        if (CMTIME_COMPARE_INLINE([asset duration], >, time))
                        {
                            animatedLayer = [_videoBuilder buildAnimationFlashScreen:assetVideoTrack.naturalSize startTime:timeSecond startOpacity:TRUE];
                            if (animatedLayer)
                            {
                                [animatedLayers addObject:(id)animatedLayer];
                            }
                        }
                    }
                    
                    break;
                }
                case kAnimationPhotoLinearScroll:
                {
                    NSTimeInterval startTime = 3;
                    animatedLayer = [_videoBuilder buildAnimatedPhotoLinearScroll:assetVideoTrack.naturalSize photos:photos startTime:startTime];
                    if (animatedLayer)
                    {
                        [animatedLayers addObject:(id)animatedLayer];
                    }
                    
                    break;
                }
                case KAnimationPhotoCentringShow:
                {
                    NSTimeInterval startTime = 10;
                    animatedLayer = [_videoBuilder buildAnimatedPhotoCentringShow:assetVideoTrack.naturalSize photos:photos startTime:startTime];
                    if (animatedLayer)
                    {
                        [animatedLayers addObject:(id)animatedLayer];
                    }
                    
                    break;
                }
                case kAnimationPhotoDrop:
                {
                    NSTimeInterval startTime = 1;
                    animatedLayer = [_videoBuilder buildAnimatedPhotoDrop:assetVideoTrack.naturalSize photos:photos startTime:startTime];
                    if (animatedLayer)
                    {
                        [animatedLayers addObject:(id)animatedLayer];
                    }

                    break;
                }
                case kAnimationPhotoParabola:
                {
                    NSTimeInterval startTime = 1;
                    animatedLayer = [_videoBuilder buildAnimatedPhotoParabola:assetVideoTrack.naturalSize photos:photos startTime:startTime];
                    if (animatedLayer)
                    {
                        [animatedLayers addObject:(id)animatedLayer];
                    }
                    
                    break;
                }
                case kAnimationPhotoFlare:
                {
                    NSTimeInterval startTime = 1;
                    animatedLayer = [_videoBuilder buildAnimatedPhotoFlare:assetVideoTrack.naturalSize photos:photos startTime:startTime];
                    if (animatedLayer)
                    {
                        [animatedLayers addObject:(id)animatedLayer];
                    }
                    
                    break;
                }
                case kAnimationPhotoEmitter:
                {
                    NSTimeInterval startTime = 1;
                    animatedLayer = [_videoBuilder BuildAnimationPhotoEmitter:assetVideoTrack.naturalSize photos:photos startTime:startTime];
                    if (animatedLayer)
                    {
                        [animatedLayers addObject:(id)animatedLayer];
                    }
                    
                    break;
                }
                case kAnimationPhotoExplode:
                {
                    NSTimeInterval startTime = 1;
                    animatedLayer = [_videoBuilder buildAnimatedPhotoExplode:assetVideoTrack.naturalSize photos:photos startTime:startTime];
                    if (animatedLayer)
                    {
                        [animatedLayers addObject:(id)animatedLayer];
                    }
                    
                    break;
                }
                case kAnimationPhotoExplodeDrop:
                {
                    NSTimeInterval startTime = 0.1;
                    animatedLayer = [_videoBuilder buildAnimatedPhotoExplodeDrop:assetVideoTrack.naturalSize photos:photos startTime:startTime];
                    if (animatedLayer)
                    {
                        [animatedLayers addObject:(id)animatedLayer];
                    }
                    
                    break;
                }
                case kAnimationPhotoCloud:
                {
                    NSTimeInterval startTime = 0.1;
                    animatedLayer = [_videoBuilder buildAnimatedPhotoCloud:assetVideoTrack.naturalSize photos:photos startTime:startTime];
                    if (animatedLayer)
                    {
                        [animatedLayers addObject:(id)animatedLayer];
                    }
                    
                    break;
                }
                case kAnimationPhotoSpin360:
                {
                    NSTimeInterval startTime = 0.1;
                    animatedLayer = [_videoBuilder buildAnimatedPhotoSpin360:assetVideoTrack.naturalSize photos:photos startTime:startTime];
                    if (animatedLayer)
                    {
                        [animatedLayers addObject:(id)animatedLayer];
                    }
                    
                    break;
                }
                case kAnimationPhotoCarousel:
                {
                    NSTimeInterval startTime = 0.1;
                    animatedLayer = [_videoBuilder buildAnimatedPhotoCarousel:assetVideoTrack.naturalSize photos:photos startTime:startTime];
                    if (animatedLayer)
                    {
                        [animatedLayers addObject:(id)animatedLayer];
                    }
                    
                    break;
                }
                default:
                    break;
            }
        }
        
        if (animatedLayers && [animatedLayers count] > 0)
        {
            for (CALayer *animatedLayer in animatedLayers)
            {
                [parentLayer addSublayer:animatedLayer];
            }
        }
    }
    
    // Make a "pass through video track" video composition.
    AVMutableVideoCompositionInstruction *passThroughInstruction = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
    passThroughInstruction.timeRange = CMTimeRangeMake(kCMTimeZero, [asset duration]);
    
    AVMutableVideoCompositionLayerInstruction *passThroughLayer = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:assetVideoTrack];
    passThroughInstruction.layerInstructions = [NSArray arrayWithObject:passThroughLayer];
    
    // Fixing orientation
//    AVMutableVideoCompositionInstruction * MainInstruction = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
//    MainInstruction.timeRange = CMTimeRangeMake(kCMTimeZero, asset.duration);
//    
//    AVMutableVideoCompositionLayerInstruction *FirstlayerInstruction = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:assetVideoTrack];
//    
//    UIImageOrientation FirstAssetOrientation_  = UIImageOrientationUp;
//    BOOL  isFirstAssetPortrait_  = NO;
//    CGAffineTransform firstTransform = assetVideoTrack.preferredTransform;
//    
//    if(firstTransform.a == 0 && firstTransform.b == 1.0 && firstTransform.c == -1.0 && firstTransform.d == 0)
//    {
//        FirstAssetOrientation_= UIImageOrientationRight;
//        isFirstAssetPortrait_ = YES;
//    }
//    else if(firstTransform.a == 0 && firstTransform.b == -1.0 && firstTransform.c == 1.0 && firstTransform.d == 0)
//    {
//        FirstAssetOrientation_ =  UIImageOrientationLeft;
//        isFirstAssetPortrait_ = YES;
//    }
//    else if(firstTransform.a == 1.0 && firstTransform.b == 0 && firstTransform.c == 0 && firstTransform.d == 1.0)
//    {
//        FirstAssetOrientation_ =  UIImageOrientationUp;
//    }
//    else if(firstTransform.a == -1.0 && firstTransform.b == 0 && firstTransform.c == 0 && firstTransform.d == -1.0)
//    {
//        FirstAssetOrientation_ = UIImageOrientationDown;
//    }
//    
//    CGFloat FirstAssetScaleToFitRatio = 480/assetVideoTrack.naturalSize.width;
//    if(isFirstAssetPortrait_)
//    {
//        FirstAssetScaleToFitRatio = 480/assetVideoTrack.naturalSize.height;
//        CGAffineTransform FirstAssetScaleFactor = CGAffineTransformMakeScale(FirstAssetScaleToFitRatio,FirstAssetScaleToFitRatio);
//        [FirstlayerInstruction setTransform:CGAffineTransformConcat(assetVideoTrack.preferredTransform, FirstAssetScaleFactor) atTime:kCMTimeZero];
//    }
//    else
//    {
//        CGAffineTransform FirstAssetScaleFactor = CGAffineTransformMakeScale(FirstAssetScaleToFitRatio,FirstAssetScaleToFitRatio);
//        [FirstlayerInstruction setTransform:CGAffineTransformConcat(CGAffineTransformConcat(assetVideoTrack.preferredTransform, FirstAssetScaleFactor),CGAffineTransformMakeTranslation(0, 20)) atTime:kCMTimeZero];
//    }
//    
//    [FirstlayerInstruction setOpacity:0.0 atTime:asset.duration];
//    MainInstruction.layerInstructions = [NSArray arrayWithObjects:FirstlayerInstruction, nil];
    
    AVMutableVideoComposition *videoComposition = [AVMutableVideoComposition videoComposition];
    videoComposition.instructions = [NSArray arrayWithObject:passThroughInstruction];
    videoComposition.animationTool = [AVVideoCompositionCoreAnimationTool videoCompositionCoreAnimationToolWithPostProcessingAsVideoLayer:videoLayer inLayer:parentLayer];
    videoComposition.frameDuration = CMTimeMake(1, 30); // 30 fps
    videoComposition.renderSize =  assetVideoTrack.naturalSize;
    
    if (animatedLayers)
    {
        [animatedLayers removeAllObjects];
        animatedLayers = nil;
    }
    
    // 5. Music effect
    AVMutableAudioMix *audioMix = nil;
    if (themeCurrent && !isStringEmpty(themeCurrent.bgMusicFile))
    {
        NSString *fileName = [themeCurrent.bgMusicFile stringByDeletingPathExtension];
        NSLog(@"%@",fileName);
        
        NSString *fileExt = [themeCurrent.bgMusicFile pathExtension];
        NSLog(@"%@",fileExt);
        
        NSURL *bgMusicURL = [[NSBundle mainBundle] URLForResource:fileName withExtension:fileExt];
        AVURLAsset *assetMusic = [[AVURLAsset alloc] initWithURL:bgMusicURL options:nil];
        _videoBuilder.commentary = assetMusic;
        audioMix = [AVMutableAudioMix audioMix];
        [_videoBuilder addCommentaryTrackToComposition:composition withAudioMix:audioMix];
    }
    
    // 6. Export to mp4 （Attention: iOS 5.0不支持导出MP4，会crash）
    unlink([exportVideoFile UTF8String]);
    
    NSString *mp4Quality = AVAssetExportPresetMediumQuality; //AVAssetExportPresetPassthrough
    if (highestQuality)
    {
        mp4Quality = AVAssetExportPresetHighestQuality;
    }
    NSString *exportPath = exportVideoFile;
    NSURL *exportUrl = [NSURL fileURLWithPath:[self returnFormatString:exportPath]];
    
    _exportSession = [[AVAssetExportSession alloc] initWithAsset:composition presetName:mp4Quality];
    _exportSession.outputURL = exportUrl;
    _exportSession.outputFileType = [[[UIDevice currentDevice] systemVersion] floatValue] >= 6.0 ? AVFileTypeMPEG4 : AVFileTypeQuickTimeMovie;
    
    _exportSession.shouldOptimizeForNetworkUse = YES;
    
    if (audioMix)
    {
        _exportSession.audioMix = audioMix;
    }
    
    if (videoComposition)
    {
        _exportSession.videoComposition = videoComposition;
    }
    
    // 6.1
    dispatch_async(dispatch_get_main_queue(), ^{
        
        // Progress monitor for effect
        _timerEffect = [NSTimer scheduledTimerWithTimeInterval:0.3f
                                                 target:self
                                               selector:@selector(retrievingProgressMP4)
                                               userInfo:nil
                                                repeats:YES];
    });
    
    
    // 7. Success status
    __unsafe_unretained typeof(self) weakSelf = self;
    [weakSelf.exportSession exportAsynchronouslyWithCompletionHandler:^{
        switch ([weakSelf.exportSession status])
        {
            case AVAssetExportSessionStatusCompleted:
            {
                dispatch_async(dispatch_get_main_queue(), ^{
                    
                    // Close timer
                    [weakSelf.timerEffect invalidate];
                    weakSelf.timerEffect = nil;
                    
                    NSLog(@"MP4 Successful!");
                    
                    if (weakSelf.delegate && [weakSelf.delegate respondsToSelector:@selector(AVAssetExportMP4SessionStatusCompleted:)])
                    {
                        [weakSelf.delegate performSelector:@selector(AVAssetExportMP4SessionStatusCompleted:) withObject:nil];
                    }

                    NSLog(@"Output Mp4 is %@", exportVideoFile);
                    
                });
                
                break;
            }
            case AVAssetExportSessionStatusFailed:
            {
                dispatch_async(dispatch_get_main_queue(), ^{
                    
                    // Close timer
                    [weakSelf.timerEffect invalidate];
                    weakSelf.timerEffect = nil;
                    
                    if (weakSelf.delegate && [weakSelf.delegate respondsToSelector:@selector(AVAssetExportMP4SessionStatusFailed:)])
                    {
                        [weakSelf.delegate performSelector:@selector(AVAssetExportMP4SessionStatusFailed:) withObject:nil];
                    }
                    
                });
                
                NSLog(@"Export failed: %@", [[_exportSession error] localizedDescription]);
                
                break;
            }
            case AVAssetExportSessionStatusCancelled:
            {
                NSLog(@"Export canceled");
                break;
            }
            case AVAssetExportSessionStatusWaiting:
            {
                NSLog(@"Export Waiting");
                break;
            }
            case AVAssetExportSessionStatusExporting:
            {
                NSLog(@"Export Exporting");
                break;
            }
            default:
                break;
        }
        
    }];
    
    return YES;
}

- (void)retrievingProgressMP4
{
    if (_exportSession)
    {
        if (_delegate && [_delegate respondsToSelector:@selector(retrievingProgressMP4:)])
        {
            [_delegate performSelector:@selector(retrievingProgressMP4:) withObject:[NSNumber numberWithFloat:_exportSession.progress]];
            
//            NSLog(@"Effect Progress: %f", exportSession.progress);
        }
    }
    
}

@end
