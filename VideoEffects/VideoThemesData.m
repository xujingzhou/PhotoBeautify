//
//  VideoThemesData.m
//  PhotoBeautify
//
//  Created by Johnny Xu(徐景周) on 7/23/14.
//  Copyright (c) 2014 Future Studio. All rights reserved.
//

#import "VideoThemesData.h"

@interface VideoThemesData()
{
    NSMutableDictionary *_themesDic;
}

@property (retain, nonatomic) NSMutableDictionary *themesDic;
@end


@implementation VideoThemesData

@synthesize themesDic = _themesDic;

#pragma mark - Singleton
+ (VideoThemesData *) sharedInstance
{
    static VideoThemesData *singleton = nil;
    static dispatch_once_t once = 0;
    dispatch_once(&once, ^{
        singleton = [[VideoThemesData alloc] init];
    });
    
    return singleton;
}

#pragma mark - Life cycle
- (id)init
{
	if (self = [super init])
    {
        // Only run once
        [self initThemesData];
    }
    
	return self;
}

- (void)dealloc
{
    [self clearAll];
}

- (void) clearAll
{
    if (self.themesDic && [self.themesDic count]>0)
    {
        [self.themesDic removeAllObjects];
        self.themesDic = nil;
    }
}

#pragma mark - Common function
- (NSString*) getWeekdayFromDate:(NSDate*)date
{
    NSCalendar* calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    NSDateComponents* components = nil; //[[NSDateComponents alloc] init];
    NSInteger unitFlags = NSYearCalendarUnit |
    NSMonthCalendarUnit |
    NSDayCalendarUnit |
    NSWeekdayCalendarUnit |
    NSHourCalendarUnit |
    NSMinuteCalendarUnit |
    NSSecondCalendarUnit;
    components = [calendar components:unitFlags fromDate:date];
    NSUInteger weekday = [components weekday];
    
    NSString *result = nil;
    switch (weekday)
    {
        case 1:
        {
            result = @"Sunday";
            break;
        }
        case 2:
        {
            result = @"Monday";
            break;
        }
        case 3:
        {
            result = @"Tuesday";
            break;
        }
        case 4:
        {
            result = @"Wednesday";
            break;
        }
        case 5:
        {
            result = @"Thursday";
            break;
        }
        case 6:
        {
            result = @"Friday";
            break;
        }
        case 7:
        {
            result = @"Saturday";
            break;
        }
        default:
            break;
    }
    
    return result;
}

-(NSString*) getStringFromDate:(NSDate*)date
{
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc]init];
    [dateFormatter setDateFormat:@"yyyy/MM/dd"];
    NSString *strDate = [dateFormatter stringFromDate:date];
    
    return strDate;
}

#pragma mark - Init themes
- (VideoThemes*) createThemeButterfly
{
    VideoThemes *theme = [[VideoThemes alloc] init];
    theme.ID = kThemeButterfly;
    theme.thumbImageName = @"themeButterfly";
    theme.name = @"Butterfly";
    theme.textStar = @"butterfly";
    theme.textSparkle = @"beautifully";
    theme.textGradient = nil;
    theme.bgMusicFile = @"1.mp3";
    theme.imageFile = nil;
    theme.scrollText = nil;
    theme.bgVideoFile = @"bgVideo01.mov";
    
    // Animation effects
    NSArray *aniActions = [NSArray arrayWithObjects:[NSNumber numberWithInt:kAnimationTextStar], [NSNumber numberWithInt:kAnimationPhotoLinearScroll], [NSNumber numberWithInt:KAnimationPhotoCentringShow], [NSNumber numberWithInt:kAnimationTextSparkle], nil];
    theme.animationActions = [NSArray arrayWithArray:aniActions];
    
    return theme;
}

- (VideoThemes*) createThemeLeaf
{
    VideoThemes *theme = [[VideoThemes alloc] init];
    theme.ID = kThemeLeaf;
    theme.thumbImageName = @"themeLeaf";
    theme.name = @"Leaf";
    theme.textStar = nil;
    theme.textSparkle = nil;
    theme.textGradient = nil;
    theme.bgMusicFile = @"2.mp3";
    theme.imageFile = nil;
    theme.scrollText = nil;
    theme.bgVideoFile = @"bgVideo02.m4v";
    
    // Animation effects
    NSArray *aniActions = [NSArray arrayWithObjects: [NSNumber numberWithInt:kAnimationMeteor], [NSNumber numberWithInt:kAnimationPhotoDrop], nil];
    theme.animationActions = [NSArray arrayWithArray:aniActions];
    
    return theme;
}

- (VideoThemes*) createThemeStarshine
{
    VideoThemes *theme = [[VideoThemes alloc] init];
    theme.ID = kThemeStarshine;
    theme.thumbImageName = @"themeStarshine";
    theme.name = @"Star";
    theme.textStar = nil;
    theme.textSparkle = nil;
    theme.textGradient = nil;
    theme.bgMusicFile = @"3.mp3";
    theme.imageFile = nil;
    theme.scrollText = nil;
    theme.bgVideoFile = @"bgVideo03.m4v";
    
    // Animation effects
    NSArray *aniActions = [NSArray arrayWithObjects:[NSNumber numberWithInt:kAnimationPhotoParabola], [NSNumber numberWithInt:kAnimationMoveDot], nil];
    theme.animationActions = [NSArray arrayWithArray:aniActions];
    
    return theme;
}

- (VideoThemes*) createThemeFlare
{
    VideoThemes *theme = [[VideoThemes alloc] init];
    theme.ID = kThemeFlare;
    theme.thumbImageName = @"themeFlare";
    theme.name = @"Flare";
    theme.textStar = nil;
    theme.textSparkle = nil;
    theme.textGradient = nil;
    theme.bgMusicFile = @"4.mp3";
    theme.imageFile = nil;
    theme.scrollText = nil;
    theme.bgVideoFile = @"bgVideo04.mov";
    
    // Animation effects
    NSArray *aniActions = [NSArray arrayWithObjects:[NSNumber numberWithInt:kAnimationPhotoFlare], [NSNumber numberWithInt:kAnimationSky], nil];
    theme.animationActions = [NSArray arrayWithArray:aniActions];
    
    return theme;
}

- (VideoThemes*) createThemeFruit
{
    VideoThemes *theme = [[VideoThemes alloc] init];
    theme.ID = kThemeFruit;
    theme.thumbImageName = @"themeFruit";
    theme.name = @"Fruit";
    theme.textStar = nil;
    theme.textSparkle = nil;
    theme.textGradient = nil;
    theme.bgMusicFile = @"5.mp3";
    theme.imageFile = nil;
    theme.scrollText = nil;
    theme.bgVideoFile = @"bgVideo05.mov";
    
    // Animation effects
    NSArray *aniActions = [NSArray arrayWithObjects:[NSNumber numberWithInt:kAnimationPhotoEmitter], nil];
    theme.animationActions = [NSArray arrayWithArray:aniActions];
    
    return theme;
}

- (VideoThemes*) createThemeCartoon
{
    VideoThemes *theme = [[VideoThemes alloc] init];
    theme.ID = kThemeCartoon;
    theme.thumbImageName = @"themeCartoon";
    theme.name = @"Cartoon";
    theme.textStar = nil;
    theme.textSparkle = nil;
    theme.textGradient = nil;
    theme.bgMusicFile = @"6.mp3";
    theme.imageFile = nil;
    theme.scrollText = nil;
    theme.bgVideoFile = @"bgVideo06.mov";
    
    // Animation effects
    NSArray *aniActions = [NSArray arrayWithObjects:[NSNumber numberWithInt:kAnimationPhotoExplode], [NSNumber numberWithInt:kAnimationPhotoSpin360], nil];
    theme.animationActions = [NSArray arrayWithArray:aniActions];
    
    return theme;
}

- (VideoThemes*) createThemeScience
{
    VideoThemes *theme = [[VideoThemes alloc] init];
    theme.ID = kThemeScience;
    theme.thumbImageName = @"themeScience";
    theme.name = @"Science";
    theme.textStar = nil;
    theme.textSparkle = nil;
    theme.textGradient = nil;
    theme.bgMusicFile = @"7.mp3";
    theme.imageFile = nil;
    theme.scrollText = nil;
    theme.bgVideoFile = @"bgVideo07.mov";
    
    // Animation effects
    NSArray *aniActions = [NSArray arrayWithObjects:[NSNumber numberWithInt:kAnimationPhotoExplodeDrop], [NSNumber numberWithInt:KAnimationPhotoCentringShow],nil];
    theme.animationActions = [NSArray arrayWithArray:aniActions];
    
    return theme;
}

- (VideoThemes*) createThemeCloud
{
    VideoThemes *theme = [[VideoThemes alloc] init];
    theme.ID = kThemeCloud;
    theme.thumbImageName = @"themeCloud";
    theme.name = @"Cloud";
    theme.textStar = nil;
    theme.textSparkle = nil;
    theme.textGradient = nil;
    theme.bgMusicFile = @"8.mp3";
    theme.imageFile = nil;
    theme.scrollText = nil;
    theme.bgVideoFile = @"bgVideo08.mov";
    
    // Animation effects
    NSArray *aniActions = [NSArray arrayWithObjects:[NSNumber numberWithInt:kAnimationPhotoCloud], [NSNumber numberWithInt:KAnimationPhotoCentringShow],nil];
    theme.animationActions = [NSArray arrayWithArray:aniActions];
    
    return theme;
}

- (void) initThemesData
{
    self.themesDic = [NSMutableDictionary dictionaryWithCapacity:15];
    
    VideoThemes *theme = nil;
    for (int i = kThemeNone; i <= kThemeCloud; ++i)
    {
        switch (i)
        {
            case kThemeNone:
            {
                // 0. 无
                break;
            }
            case kThemeButterfly:
            {
                // Butterfly
                theme = [self createThemeButterfly];
                break;
            }
            case kThemeLeaf:
            {
                theme = [self createThemeLeaf];
                break;
            }
            case kThemeStarshine:
            {
                theme = [self createThemeStarshine];
                break;
            }
            case kThemeFlare:
            {
                theme = [self createThemeFlare];
                break;
            }
            case kThemeFruit:
            {
                theme = [self createThemeFruit];
                break;
            }
            case kThemeCartoon:
            {
                theme = [self createThemeCartoon];
                break;
            }
            case kThemeScience:
            {
                theme = [self createThemeScience];
                break;
            }
            case kThemeCloud:
            {
                theme = [self createThemeCloud];
                break;
            }
            default:
                break;
        }
        
        if (i == kThemeNone)
        {
            [self.themesDic setObject:[NSNull null] forKey:[NSNumber numberWithInt:kThemeNone]];
        }
        else
        {
            [self.themesDic setObject:theme forKey:[NSNumber numberWithInt:i]];
        }
    }
}

- (NSMutableDictionary*) getThemeData
{
    return self.themesDic;
}

@end
