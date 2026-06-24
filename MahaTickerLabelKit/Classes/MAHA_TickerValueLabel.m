#import <QuartzCore/QuartzCore.h>

#import "MAHA_TickerValueLabel.h"

#if !__has_feature(objc_arc)
#error MAHA_TickerValueLabel is ARC only. Either turn on ARC for the project or use -fobjc-arc flag
#endif

#ifndef kMAHA_CountPulseRate
#define kMAHA_CountPulseRate 3.0
#endif

typedef struct {
    CGFloat maha_startValue;
    CGFloat maha_endValue;
    NSTimeInterval maha_elapsedTime;
    NSTimeInterval maha_duration;
    NSTimeInterval maha_lastUpdateTime;
    BOOL maha_isAnimating;
} MAHA_TickerCycleState;

static inline CGFloat MAHA_TickerClampedProgress(CGFloat progress) {
    return fmaxf(0.0f, fminf(progress, 1.0f));
}

static inline CGFloat MAHA_TickerEasedProgress(CGFloat progress) {
    CGFloat normalizedProgress = MAHA_TickerClampedProgress(progress);
    CGFloat doubledProgress = normalizedProgress * 2.0f;
    if (doubledProgress < 1.0f) {
        return 0.5f * powf(doubledProgress, kMAHA_CountPulseRate);
    }
    return 0.5f * (2.0f - powf(2.0f - doubledProgress, kMAHA_CountPulseRate));
}

@interface MAHA_TickerValueLabel ()

@property (nonatomic, assign) MAHA_TickerCycleState maha_animationState;
@property (nonatomic, strong) CADisplayLink *maha_displayLink;
@property (nonatomic, assign) BOOL maha_patternUsesIntegerFormat;

@end

@implementation MAHA_TickerValueLabel

- (void)mahaShiftValueTo:(CGFloat)targetValue cycleSpan:(NSTimeInterval)duration {
    [self maha_invalidateDisplayLink];
    [self maha_preparePatternIfNeeded];
    [self maha_configureAnimationStateForTargetValue:targetValue duration:duration];

    if (duration <= 0.0) {
        [self maha_renderTickerValue:targetValue];
        return;
    }

    [self maha_startDisplayLink];
}

- (CGFloat)maha_activeValue {
    MAHA_TickerCycleState animationState = self.maha_animationState;
    if (animationState.maha_isAnimating == NO ||
        animationState.maha_duration <= 0.0 ||
        animationState.maha_elapsedTime >= animationState.maha_duration) {
        return animationState.maha_endValue;
    }

    CGFloat normalizedProgress = animationState.maha_elapsedTime / animationState.maha_duration;
    CGFloat easedProgress = MAHA_TickerEasedProgress(normalizedProgress);
    return animationState.maha_startValue + ((animationState.maha_endValue - animationState.maha_startValue) * easedProgress);
}

- (void)setMahaTickerPattern:(NSString *)mahaTickerPattern {
    _mahaTickerPattern = [mahaTickerPattern copy];
    self.maha_patternUsesIntegerFormat = [self maha_patternUsesIntegerSpecifier:mahaTickerPattern];
    [self maha_preparePatternIfNeeded];
    [self maha_renderTickerValue:[self maha_activeValue]];
}

- (void)setMahaTickerComposer:(MAHA_CountCipherForge)mahaTickerComposer {
    _mahaTickerComposer = [mahaTickerComposer copy];
    [self maha_preparePatternIfNeeded];
    [self maha_renderTickerValue:[self maha_activeValue]];
}

- (void)maha_handleTickerLink:(CADisplayLink *)displayLink {
    (void)displayLink;
    if ([self maha_advanceAnimationWithTimestamp:CACurrentMediaTime()] == NO) {
        return;
    }

    [self maha_renderTickerValue:[self maha_activeValue]];

    if (self.maha_animationState.maha_isAnimating == NO) {
        [self maha_invalidateDisplayLink];
    }
}

- (void)maha_renderTickerValue:(CGFloat)value {
    if (self.mahaTickerComposer != nil) {
        self.text = self.mahaTickerComposer(value);
        return;
    }

    self.text = [self maha_formattedTextForValue:value];
}

- (void)maha_preparePatternIfNeeded {
    if (self.mahaTickerPattern == nil) {
        self.mahaTickerPattern = @"%f";
    }
}

- (void)maha_configureAnimationStateForTargetValue:(CGFloat)targetValue duration:(NSTimeInterval)duration {
    MAHA_TickerCycleState animationState = self.maha_animationState;
    animationState.maha_startValue = [self maha_activeValue];
    animationState.maha_endValue = targetValue;
    animationState.maha_elapsedTime = 0.0;
    animationState.maha_duration = duration;
    animationState.maha_lastUpdateTime = CACurrentMediaTime();
    animationState.maha_isAnimating = duration > 0.0;
    self.maha_animationState = animationState;
}

- (BOOL)maha_advanceAnimationWithTimestamp:(NSTimeInterval)timestamp {
    MAHA_TickerCycleState animationState = self.maha_animationState;
    if (animationState.maha_isAnimating == NO) {
        return NO;
    }

    animationState.maha_elapsedTime += timestamp - animationState.maha_lastUpdateTime;
    animationState.maha_lastUpdateTime = timestamp;

    if (animationState.maha_elapsedTime >= animationState.maha_duration) {
        animationState.maha_elapsedTime = animationState.maha_duration;
        animationState.maha_isAnimating = NO;
    }

    self.maha_animationState = animationState;
    return YES;
}

- (NSString *)maha_formattedTextForValue:(CGFloat)value {
    NSString *pattern = self.mahaTickerPattern;
    if (self.maha_patternUsesIntegerFormat) {
        return [NSString stringWithFormat:pattern, (int)value];
    }
    return [NSString stringWithFormat:pattern, value];
}

- (BOOL)maha_patternUsesIntegerSpecifier:(NSString *)pattern {
    if (pattern.length == 0) {
        return NO;
    }

    NSRange integerSpecifierRange = [pattern rangeOfString:@"%[^fega]*[diouxc]"
                                                  options:NSRegularExpressionSearch | NSCaseInsensitiveSearch];
    return integerSpecifierRange.location != NSNotFound;
}

- (void)maha_startDisplayLink {
    CADisplayLink *displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(maha_handleTickerLink:)];
    if ([displayLink respondsToSelector:@selector(setPreferredFramesPerSecond:)]) {
        displayLink.preferredFramesPerSecond = 30;
    } else {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        displayLink.frameInterval = 2;
#pragma clang diagnostic pop
    }

    NSRunLoop *mainRunLoop = [NSRunLoop mainRunLoop];
    [displayLink addToRunLoop:mainRunLoop forMode:NSDefaultRunLoopMode];
    [displayLink addToRunLoop:mainRunLoop forMode:UITrackingRunLoopMode];
    self.maha_displayLink = displayLink;
}

- (void)maha_invalidateDisplayLink {
    [self.maha_displayLink invalidate];
    self.maha_displayLink = nil;
}

@end
