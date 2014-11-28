//
//  DoPhotoCell.m
//  DoImagePickerController
//
//  Created by Donobono on 2014. 1. 23..
//

#import "DoPhotoCell.h"

@implementation DoPhotoCell

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
//        self.autoresizesSubviews = YES;
//        _vSelect.autoresizingMask = UIViewAutoresizingFlexibleTopMargin|UIViewAutoresizingFlexibleRightMargin;
    }
    return self;
}

- (void)setSelectMode:(BOOL)bSelect
{
    if (bSelect) {
        _ivPhoto.alpha = 0.5;
        _vSelect.image = [UIImage imageNamed:@"image_selected"];
        _vSelect.hidden = NO;
    } else {
        _ivPhoto.alpha = 1.0;
        _vSelect.image = nil;
        _vSelect.hidden = YES;
    }
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

- (void)layoutSubviews
{
    CGSize size = self.bounds.size;
    CGSize vSelectSize = _vSelect.frame.size;
    
    CGPoint vSelectCenterPoint = CGPointMake(size.width - vSelectSize.width + 5, vSelectSize.height - 5);
    _vSelect.center = vSelectCenterPoint;
}

@end
