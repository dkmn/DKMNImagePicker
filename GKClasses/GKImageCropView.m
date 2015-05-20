//
//  GKImageCropView.m
//  GKImagePicker
//
//  Created by Georg Kitz on 6/1/12.
//  Copyright (c) 2012 Aurora Apps. All rights reserved.
//

#import "GKImageCropView.h"
#import "GKImageCropOverlayView.h"
#import "GKResizeableCropOverlayView.h"

#import <QuartzCore/QuartzCore.h>

@interface ScrollView : UIScrollView
@end

@implementation ScrollView

- (void)layoutSubviews{
    [super layoutSubviews];

    UIView *zoomView = [self.delegate viewForZoomingInScrollView:self];
    
    CGSize boundsSize = self.bounds.size;
    CGRect frameToCenter = zoomView.frame;
    
    // center horizontally
    if (frameToCenter.size.width < boundsSize.width)
        frameToCenter.origin.x = floorf((boundsSize.width - frameToCenter.size.width) / 2);
    else
        frameToCenter.origin.x = 0;
    
    // center vertically
    if (frameToCenter.size.height < boundsSize.height)
        frameToCenter.origin.y = floorf((boundsSize.height - frameToCenter.size.height) / 2);
    else
        frameToCenter.origin.y = 0;
    
    zoomView.frame = frameToCenter;
}

@end

@interface GKImageCropView ()<UIScrollViewDelegate>
@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, strong) GKImageCropOverlayView *cropOverlayView;
@property (nonatomic, assign) CGFloat xOffset;
@property (nonatomic, assign) CGFloat yOffset;
@end

@implementation GKImageCropView

#pragma mark -
#pragma Getter/Setter

@synthesize scrollView, imageView, cropOverlayView, resizableCropArea, xOffset, yOffset;

- (void)setImageToCrop:(UIImage *)imageToCrop{
    self.imageView.image = imageToCrop;
}

- (UIImage *)imageToCrop{
    return self.imageView.image;
}

- (void)setCropSize:(CGSize)cropSize{
    
    if (self.cropOverlayView == nil){
        if(self.resizableCropArea)
            self.cropOverlayView = [[GKResizeableCropOverlayView alloc] initWithFrame:self.bounds andInitialContentSize:CGSizeMake(cropSize.width, cropSize.height)];
        else
            self.cropOverlayView = [[GKImageCropOverlayView alloc] initWithFrame:self.bounds];
        
        [self addSubview:self.cropOverlayView];
    }
    self.cropOverlayView.cropSize = cropSize;
}

- (CGSize)cropSize{
    return self.cropOverlayView.cropSize;
}

#pragma mark -
#pragma Public Methods

- (UIImage *)croppedImageFullRes{
    // try to apply relative transform to crop original full-res image
    // do we have it?
    NSLog([self.imageToCrop description]);

//    [self.imageToCrop fixOrientation];
    
   // NSLog([self.imageToCrop.size description]);
    CGFloat xs, ys, scale;
    
    //get image dimensions
    if (self.imageToCrop){
         xs = self.imageToCrop.size.width;
         ys = self.imageToCrop.size.height;
         scale = self.imageToCrop.scale;
        NSLog(@"original width: %f \n  height: %f \n scale: %f\n",
              xs, ys, scale);
    }
    
    CGFloat cx, cy, cw, ch;
    CGFloat fx,fy,fw,fh;
    
    //get relative transformation points
    if (self.resizableCropArea){
        GKResizeableCropOverlayView* resizeableView = (GKResizeableCropOverlayView*)self.cropOverlayView;
        
        CGFloat xPositionInScrollView = resizeableView.contentView.frame.origin.x + self.scrollView.contentOffset.x - self.xOffset;
        CGFloat yPositionInScrollView = resizeableView.contentView.frame.origin.y + self.scrollView.contentOffset.y - self.yOffset;
        
        cx = xPositionInScrollView; //resizeableView.contentView.frame.origin.x;
        cy = yPositionInScrollView; //resizeableView.contentView.frame.origin.y;
        cw = resizeableView.contentView.frame.size.width;
        ch = resizeableView.contentView.frame.size.height;
        NSLog(@"crop frame x y width height: %f %f %f %f",
              cx, cy, cw, ch);

        fx = self.imageView.frame.origin.x;
        fy = self.imageView.frame.origin.y;
        fw = self.imageView.frame.size.width;
        fh = self.imageView.frame.size.height;
        NSLog(@"\nunderlying view sizes: \n");
        NSLog(@"%f %f %f %f \n",fx, fy, fw, fh);
        
    }
    
    CGFloat xratio = (xs * scale) / fw;
    CGFloat yratio = (ys * scale) / fh;
    
    NSLog(@"Ratios (x y): %f %f", xratio, yratio);
    
    // use crop or affine transform to crop original full res image
    CGRect transformedCrop = CGRectMake(
                                        cx * xratio,
                                        cy * yratio,
                                        cw * xratio,
                                        ch * yratio);
    NSLog(@"\nTRANSFORMED crop: %f %f %f %f",
          transformedCrop.origin.x,
          transformedCrop.origin.y,
          transformedCrop.size.width,
          transformedCrop.size.height);
    
    UIImage *croppedToReturn = [self.imageToCrop resizedImage:self.imageToCrop.size interpolationQuality:kCGInterpolationNone];
    croppedToReturn = [croppedToReturn croppedImage:transformedCrop];
    [croppedToReturn fixOrientation];
                                
    UIImageWriteToSavedPhotosAlbum(croppedToReturn,nil,nil,nil);
    
    return croppedToReturn;
    
/**        UIGraphicsBeginImageContextWithOptions(CGSizeMake(resizeableView.contentView.frame.size.width, resizeableView.contentView.frame.size.height), self.scrollView.opaque, 0.0);
        CGContextRef ctx = UIGraphicsGetCurrentContext();
        
        CGFloat xPositionInScrollView = resizeableView.contentView.frame.origin.x + self.scrollView.contentOffset.x - self.xOffset;
        CGFloat yPositionInScrollView = resizeableView.contentView.frame.origin.y + self.scrollView.contentOffset.y - self.yOffset;
        CGContextTranslateCTM(ctx, -(xPositionInScrollView), -(yPositionInScrollView));
    }
    else {
        
        UIGraphicsBeginImageContextWithOptions(self.scrollView.frame.size, self.scrollView.opaque, [[UIScreen mainScreen] scale]);
        CGContextRef ctx = UIGraphicsGetCurrentContext();
        CGContextTranslateCTM(ctx, -self.scrollView.contentOffset.x, -self.scrollView.contentOffset.y);
    }

    **/
    
}

- (UIImage *)croppedImage{
    // do we have it?
    NSLog([self.imageToCrop description]);

    //renders the the zoomed area into the cropped image
    if (self.resizableCropArea){
        GKResizeableCropOverlayView* resizeableView = (GKResizeableCropOverlayView*)self.cropOverlayView;
        UIGraphicsBeginImageContextWithOptions(CGSizeMake(resizeableView.contentView.frame.size.width, resizeableView.contentView.frame.size.height), self.scrollView.opaque, 0.0);
        CGContextRef ctx = UIGraphicsGetCurrentContext();
        
        CGFloat xPositionInScrollView = resizeableView.contentView.frame.origin.x + self.scrollView.contentOffset.x - self.xOffset;
        CGFloat yPositionInScrollView = resizeableView.contentView.frame.origin.y + self.scrollView.contentOffset.y - self.yOffset;
        CGContextTranslateCTM(ctx, -(xPositionInScrollView), -(yPositionInScrollView));
    }
    else {
		
        UIGraphicsBeginImageContextWithOptions(self.scrollView.frame.size, self.scrollView.opaque, [[UIScreen mainScreen] scale]);
        CGContextRef ctx = UIGraphicsGetCurrentContext();
        CGContextTranslateCTM(ctx, -self.scrollView.contentOffset.x, -self.scrollView.contentOffset.y);
    }
    [self.scrollView.layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *viewImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return viewImage;
}

#pragma mark -
#pragma Override Methods

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {

        self.userInteractionEnabled = YES;
        self.backgroundColor = [UIColor blackColor];
        self.scrollView = [[ScrollView alloc] initWithFrame:self.bounds ];
        self.scrollView.showsHorizontalScrollIndicator = NO;
        self.scrollView.showsVerticalScrollIndicator = NO;
        self.scrollView.delegate = self;
        self.scrollView.clipsToBounds = NO;
        self.scrollView.decelerationRate = 0.0; 
        self.scrollView.backgroundColor = [UIColor clearColor];
        [self addSubview:self.scrollView];
        
        self.imageView = [[UIImageView alloc] initWithFrame:self.scrollView.frame];
        self.imageView.contentMode = UIViewContentModeScaleAspectFit;
        self.imageView.backgroundColor = [UIColor blackColor];
        [self.scrollView addSubview:self.imageView];
    
        
        self.scrollView.minimumZoomScale = 1;
        self.scrollView.maximumZoomScale = 3.0;
    }
    return self;
}


- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event{
    if (!self.resizableCropArea)
        return self.scrollView;

    GKResizeableCropOverlayView* resizeableCropView = (GKResizeableCropOverlayView*)self.cropOverlayView;
    
    CGRect outerFrame = CGRectInset(resizeableCropView.cropBorderView.frame, -10 , -10);
    if (CGRectContainsPoint(outerFrame, point)){
        
        if (resizeableCropView.cropBorderView.frame.size.width < 60 || resizeableCropView.cropBorderView.frame.size.height < 60 )
            return [super hitTest:point withEvent:event];
        
        CGRect innerTouchFrame = CGRectInset(resizeableCropView.cropBorderView.frame, 30, 30);
        if (CGRectContainsPoint(innerTouchFrame, point))
            return self.scrollView;
        
        CGRect outBorderTouchFrame = CGRectInset(resizeableCropView.cropBorderView.frame, -10, -10);
        if (CGRectContainsPoint(outBorderTouchFrame, point))
            return [super hitTest:point withEvent:event];
        
        return [super hitTest:point withEvent:event];
    }
    return self.scrollView;
}

- (void)layoutSubviews{
    [super layoutSubviews];
    
    CGSize size = self.cropSize;
    CGFloat toolbarSize = UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad ? 0 : 54;
    self.xOffset = floor((CGRectGetWidth(self.bounds) - size.width) * 0.5);
    self.yOffset = floor((CGRectGetHeight(self.bounds) - toolbarSize - size.height) * 0.5); //fixed

    CGFloat cropRatio = size.height / size.width;
    CGFloat imageRatio = self.imageToCrop.size.height / self.imageToCrop.size.width;
    
    CGFloat faktorOriginX = 0.0;
    CGFloat faktorOriginY = 0.0;
    CGFloat faktoredHeight = 0.f;
    CGFloat faktoredWidth = 0.f;
    
    if (imageRatio >= cropRatio) {
        // Fit to width
        faktoredWidth = size.width;
        faktoredHeight = faktoredWidth * imageRatio;
        faktorOriginY = floorf((size.height - faktoredHeight) / 2);
    } else {                        
        // Fit to height
        faktoredHeight = size.height;
        faktoredWidth = faktoredHeight / imageRatio;
        faktorOriginX = floorf((size.width - faktoredWidth) / 2);
    }
    
    self.cropOverlayView.frame = self.bounds;
    self.scrollView.frame = CGRectMake(xOffset, yOffset, size.width, size.height);
    self.imageView.frame = CGRectMake(0, 0, faktoredWidth, faktoredHeight);
    self.scrollView.contentSize = self.imageView.frame.size;
    self.scrollView.contentOffset = CGPointMake(-faktorOriginX, -faktorOriginY);
}

#pragma mark -
#pragma UIScrollViewDelegate Methods

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView{
    return self.imageView;
}

@end
