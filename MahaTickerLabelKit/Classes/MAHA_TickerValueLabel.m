#import <QuartzCore/QuartzCore.h>

#import "MAHA_TickerValueLabel.h"

#if !__has_feature(objc_arc)
#error MAHA_TickerValueLabel is ARC only. Either turn on ARC for the project or use -fobjc-arc flag
#endif

#ifndef kMAHA_CountPulseRate
#define kMAHA_CountPulseRate 3.0
#endif

typedef struct {
    CGFloat maha_originValue;
    CGFloat maha_targetValue;
    NSTimeInterval maha_cycleProgress;
    NSTimeInterval maha_totalPulseClock;
    NSTimeInterval maha_lastPulseClock;
    BOOL maha_isCycling;
} MAHA_TickerCycleState;

static inline CGFloat MAHA_TickerResolvedCurve(CGFloat progress) {
    CGFloat doubled = progress * 2.0f;
    if (doubled < 1.0f) {
        return 0.5f * powf(doubled, kMAHA_CountPulseRate);
    }
    return 0.5f * (2.0f - powf(2.0f - doubled, kMAHA_CountPulseRate));
}

@interface MAHA_TickerValueLabel ()

@property (nonatomic, assign) MAHA_TickerCycleState maha_tickerState;
@property (nonatomic, strong) CADisplayLink *maha_tickerLink;

@end

@implementation MAHA_TickerValueLabel

- (void)mahaShiftValueTo:(CGFloat)targetValue cycleSpan:(NSTimeInterval)duration {
    [self maha_resetTickerLink];
    [self maha_prepareTickerPatternIfNeeded];

    MAHA_TickerCycleState state = self.maha_tickerState;
    state.maha_originValue = [self maha_activeValue];
    state.maha_targetValue = targetValue;
    state.maha_cycleProgress = 0.0;
    state.maha_totalPulseClock = duration;
    state.maha_lastPulseClock = CACurrentMediaTime();
    state.maha_isCycling = duration > 0.0;
    self.maha_tickerState = state;

    if (duration == 0.0) {
        [self maha_renderTickerValue:targetValue];
        return;
    }

    CADisplayLink *link = [CADisplayLink displayLinkWithTarget:self selector:@selector(maha_handleTickerLink:)];
    link.frameInterval = 2;
    [link addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];
    [link addToRunLoop:[NSRunLoop mainRunLoop] forMode:UITrackingRunLoopMode];
    self.maha_tickerLink = link;
}

- (CGFloat)maha_activeValue {
    MAHA_TickerCycleState state = self.maha_tickerState;
    if (state.maha_isCycling == NO || state.maha_totalPulseClock <= 0.0 || state.maha_cycleProgress >= state.maha_totalPulseClock) {
        return state.maha_targetValue;
    }

    CGFloat progress = state.maha_cycleProgress / state.maha_totalPulseClock;
    progress = fmaxf(0.0f, fminf(progress, 1.0f));
    CGFloat curveValue = MAHA_TickerResolvedCurve(progress);
    return state.maha_originValue + ((state.maha_targetValue - state.maha_originValue) * curveValue);
}

- (void)setMahaTickerPattern:(NSString *)mahaTickerPattern {
    _mahaTickerPattern = [mahaTickerPattern copy];
    [self maha_renderTickerValue:[self maha_activeValue]];
}

- (void)setMahaTickerComposer:(MAHA_CountCipherForge)mahaTickerComposer {
    _mahaTickerComposer = [mahaTickerComposer copy];
    [self maha_renderTickerValue:[self maha_activeValue]];
}

- (void)maha_handleTickerLink:(CADisplayLink *)ticker {
    MAHA_TickerCycleState state = self.maha_tickerState;
    if (state.maha_isCycling == NO) {
        return;
    }

    NSTimeInterval now = CACurrentMediaTime();
    state.maha_cycleProgress += now - state.maha_lastPulseClock;
    state.maha_lastPulseClock = now;

    if (state.maha_cycleProgress >= state.maha_totalPulseClock) {
        state.maha_cycleProgress = state.maha_totalPulseClock;
        state.maha_isCycling = NO;
    }

    self.maha_tickerState = state;
    [self maha_renderTickerValue:[self maha_activeValue]];

    if (state.maha_isCycling == NO) {
        [self maha_resetTickerLink];
    }
}

- (void)maha_renderTickerValue:(CGFloat)value {
    if (self.mahaTickerComposer != nil) {
        self.text = self.mahaTickerComposer(value);
        return;
    }

    NSString *pattern = self.mahaTickerPattern;
    if ([pattern rangeOfString:@"%[^fega]*[diouxc]" options:NSRegularExpressionSearch | NSCaseInsensitiveSearch].location != NSNotFound) {
        self.text = [NSString stringWithFormat:pattern, (int)value];
    } else {
        self.text = [NSString stringWithFormat:pattern, value];
    }
}

- (void)maha_prepareTickerPatternIfNeeded {
    if (self.mahaTickerPattern == nil) {
        self.mahaTickerPattern = @"%f";
    }
}

- (void)maha_resetTickerLink {
    [self.maha_tickerLink invalidate];
    self.maha_tickerLink = nil;
}

@end
