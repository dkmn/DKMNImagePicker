//
//  GKImageCropper.m
//  GKImageEditor
//
//  Created by Genki Kondo on 9/18/12.
//  Copyright (c) 2012 Genki Kondo. All rights reserved.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.

#import "GKImageCropper.h"

#define OVERLAY_COLOR [UIColor colorWithRed:0/255. green:0/255. blue:0/255. alpha:0.7]

@interface GKImageCropper ()

@end

@implementation GKImageCropper

@synthesize delegate = _delegate;

- (id)initWithImage:(UIImage*)theImage withSize:(CGSize)theSize {
    self= [super init];
    if(self) {
        image = theImage;
        size = theSize;
    }
    return self;
}

#pragma mark - View lifecycle

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    
    // **********************************************
    // * Configure navigation item
    // **********************************************
    self.navigationItem.title = @"Crop Image";
    UIBarButtonItem *okButton = [[UIBarButtonItem alloc] initWithTitle:@"Done" style:UIBarButtonItemStyleBordered target:self action:@selector(handleDoneButton)];
    [self.navigationItem setRightBarButtonItem:okButton animated:NO];
    
    // **********************************************
    // * Determine image scaling if necessary
    // **********************************************
    double navBarHeight = self.navigationController.navigationBar.frame.size.height;
    double frameWidth = self.view.frame.size.width;
    double frameHeight = self.view.frame.size.height-navBarHeight;
    CGFloat imageWidth = CGImageGetWidth(image.CGImage);
    CGFloat imageHeight = CGImageGetHeight(image.CGImage);
    float scaleX = frameWidth / imageWidth;
    float scaleY = frameHeight / imageHeight;
    float scaleScroll =  (scaleX < scaleY ? scaleY : scaleX);
    if (imageWidth < frameWidth || imageHeight < frameHeight) {
        UIImage *scaledImage = [UIImage imageWithCGImage:[image CGImage] scale:1./scaleScroll orientation:UIImageOrientationUp];
        image = scaledImage;
    }
    
    // **********************************************
    // * Create scroll view
    // **********************************************
    scrollView = [[UIScrollView alloc] initWithFrame:self.view.frame];
    scrollView.bounds = CGRectMake(0, 0,imageWidth, imageHeight);
    scrollView.frame = CGRectMake(0, 0, frameWidth, frameHeight);
    scrollView.delegate = self;
    scrollView.scrollEnabled = YES;
    scrollView.contentSize = image.size;
    scrollView.pagingEnabled = NO;
    scrollView.directionalLockEnabled = NO;
    scrollView.showsHorizontalScrollIndicator = NO;
    scrollView.showsVerticalScrollIndicator = NO;
    //Limit zoom
    //scrollView.maximumZoomScale = scaleScroll*3;
    //scrollView.minimumZoomScale = scaleScroll;

    [self.view addSubview:scrollView];
    
    // **********************************************
    // * Create scroll view
    // **********************************************
    imageView = [[UIImageView alloc] initWithImage:image];
    NSLog(@"Image w: %.2f",image.size.width);
    NSLog(@"Image h: %.2f",image.size.height);
    [scrollView addSubview:imageView];
    
    [UIColor colorWithRed:0/255. green:140/255. blue:190/255. alpha:1];
    // **********************************************
    // * Create top shaded overlay
    // **********************************************
    UIImageView *overlayTop = [[UIImageView alloc] initWithFrame:CGRectMake(0., 0., frameWidth, frameHeight/2.-size.height/2.)];
    overlayTop.backgroundColor = OVERLAY_COLOR;
    [self.view addSubview:overlayTop];
    
    // **********************************************
    // * Create bottom shaded overlay
    // **********************************************
    UIImageView *overlayBottom = [[UIImageView alloc] initWithFrame:CGRectMake(0., frameHeight/2.+size.height/2., frameWidth, frameHeight/2.-size.height/2.)];
    overlayBottom.backgroundColor = OVERLAY_COLOR;
    [self.view addSubview:overlayBottom];
    
    // **********************************************
    // * Create left shaded overlay
    // **********************************************
    UIImageView *overlayLeft = [[UIImageView alloc] initWithFrame:CGRectMake(0., frameHeight/2.-size.height/2., frameWidth/2.-size.width/2., size.height)];
    overlayLeft.backgroundColor = OVERLAY_COLOR;
    [self.view addSubview:overlayLeft];
    
    // **********************************************
    // * Create right shaded overlay
    // **********************************************
    UIImageView *overlayRight = [[UIImageView alloc] initWithFrame:CGRectMake(frameWidth/2.+size.width/2., frameHeight/2.-size.height/2., frameWidth/2.-size.width/2., size.height)];
    overlayRight.backgroundColor = OVERLAY_COLOR;
    [self.view addSubview:overlayRight];
    
    // **********************************************
    // * Set scroll view inset so that corners of images can be accessed
    // **********************************************
    scrollView.contentInset = UIEdgeInsetsMake(overlayTop.frame.size.height, overlayLeft.frame.size.width, overlayBottom.frame.size.height, overlayRight.frame.size.width);
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - Helper methods

UIImage* imageFromView(UIImage* srcImage, CGRect* rect) {
    CGImageRef cr = CGImageCreateWithImageInRect(srcImage.CGImage, *rect);
    UIImage* cropped = [UIImage imageWithCGImage:cr];
    
    CGImageRelease(cr);
    return cropped;
}

#pragma mark - User interaction handle methods

-(void)handleDoneButton {
    // **********************************************
    // * Define CGRect to crop
    // **********************************************
    double cropAreaVerticalOffset = self.view.frame.size.height/2.-size.height/2.;
    CGRect cropRect;
    float scale = 1.0f/scrollView.zoomScale;
    cropRect.origin.x = scrollView.contentOffset.x * scale;
    cropRect.origin.y = (scrollView.contentOffset.y+cropAreaVerticalOffset) * scale;
    cropRect.size.width = size.width * scale;
    cropRect.size.height = size.height * scale;
    
    [self dismissModalViewControllerAnimated:YES];
    [self.delegate GKImageCropDidFinishEditingWithImage:imageFromView(image, &cropRect)];
}

#pragma mark - UIScrollView delegate methods

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
    return imageView;
}

@end