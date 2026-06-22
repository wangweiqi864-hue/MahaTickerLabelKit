#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

typedef NSString* (^MAHA_CountCipherForge)(CGFloat value);

@interface MAHA_TickerValueLabel : UILabel

@property (nonatomic, copy) NSString *mahaTickerPattern;
@property (nonatomic, copy) MAHA_CountCipherForge mahaTickerComposer;

- (void)mahaShiftValueTo:(CGFloat)targetValue
               cycleSpan:(NSTimeInterval)duration NS_SWIFT_NAME(mahaShiftValue(_:cycleSpan:));

@end
