//
//  MainViewController.m
//  PoCamera
//
//  Created by 서광덕 on 2014. 11. 11..
//  Copyright (c) 2014년 Dewey. All rights reserved.
//

#import "MainViewController.h"

@interface MainViewController ()

@end

@implementation MainViewController

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    [self setSettingInfo];
    
    glContext = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    if ( !glContext )
    {
        NSLog(@"Failed to create ES context");
    }
    
    ciContext = [CIContext contextWithEAGLContext:glContext];
    
    self.cameraOutputView.context = glContext;
    self.cameraOutputView.drawableDepthFormat = GLKViewDrawableDepthFormat24;
    
    // for Capture Image
    captureStillImageOutput = [[AVCaptureStillImageOutput alloc] init];
    NSDictionary *outputSettings = [[NSDictionary alloc] initWithObjectsAndKeys: AVVideoCodecJPEG, AVVideoCodecKey, nil];
    [captureStillImageOutput setOutputSettings:outputSettings];
    
    assetsLibrary = [[ALAssetsLibrary alloc] init];
    
    [self setFocusSetting];
    [self initCapture];
}

- (void)setSettingInfo {
    settingViewWidth = self.settingView.frame.size.width;
    [self actHideSettingView:nil];
    
    self.sValueSlider.minimumValue = 0.0f;
    self.sValueSlider.maximumValue = 1.0f;
    self.vValueSlider.minimumValue = 0.0f;
    self.vValueSlider.maximumValue = 1.0f;
    
    self.sValueSlider.value = S_DEFAULT_VALUE;
    self.vValueSlider.value = V_DEFAULT_VALUE;
    [self applySliderInfo];
}
- (void)setFocusSetting {
    UITapGestureRecognizer *tapGR = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapToFocus:)];
    [tapGR setNumberOfTapsRequired:1];
    [tapGR setNumberOfTouchesRequired:1];
    [self.cameraOutputView addGestureRecognizer:tapGR];
}

- (void)initCapture {
    /*We setup the input*/
    captureDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    captureDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:captureDevice error:nil];
    /*We setupt the output*/
    captureVideoOutput = [[AVCaptureVideoDataOutput alloc] init];
    /*While a frame is processes in -captureOutput:didOutputSampleBuffer:fromConnection: delegate methods no other frames are added in the queue.
     If you don't want this behaviour set the property to NO */
    
    captureVideoOutput.alwaysDiscardsLateVideoFrames = YES;
    
    /*We create a serial queue to handle the processing of our frames*/
    dispatch_queue_t queue;
    queue = dispatch_queue_create("cameraQueue", DISPATCH_QUEUE_SERIAL);
    [captureVideoOutput setSampleBufferDelegate:self queue:queue];
    
    // Set the video output to store frame in BGRA (It is supposed to be faster)
    NSString* key = (NSString*)kCVPixelBufferPixelFormatTypeKey;
    NSNumber* value = [NSNumber numberWithUnsignedInt:kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange];
    NSDictionary* videoSettings = [NSDictionary dictionaryWithObject:value forKey:key];
    [captureVideoOutput setVideoSettings:videoSettings];
    
    /*And we create a capture session*/
    captureSession = [[AVCaptureSession alloc] init];
    
    /*We add input and output*/
    [captureSession addInput:captureDeviceInput];
    [captureSession addOutput:captureVideoOutput];
    
    /*We use medium quality, ont the iPhone 4 this demo would be laging too much, the conversion in UIImage and CGImage demands too much ressources for a 720p resolution.*/
    [captureSession setSessionPreset:AVCaptureSessionPreset1280x720];
    
    /*Setting Capture.*/
    [captureSession addOutput:captureStillImageOutput];
    
    /*We start the capture*/
    [captureSession startRunning];
}

#pragma mark - IBAction
- (IBAction)actShowSettingView:(id)sender {
    isSettingViewHide = NO;
    [UIView animateWithDuration:0.3f animations:^{
        self.settingView.transform = CGAffineTransformIdentity;
        //        self.cameraOutputView.transform = CGAffineTransformMakeTranslation(-settingViewWidth, 0.0f);
        
        self.showSettingButton.hidden = YES;
    } completion:nil];
}
- (IBAction)actHideSettingView:(id)sender {
    isSettingViewHide = YES;
    [UIView animateWithDuration:0.3f animations:^{
        self.settingView.transform = CGAffineTransformMakeTranslation(settingViewWidth, 0.0f);
        //        self.cameraOutputView.transform = CGAffineTransformIdentity;
        
        self.showSettingButton.hidden = NO;
    } completion:nil];
}

- (IBAction)sValueSliderChanged:(id)sender {
}
- (IBAction)vValueSliderChanged:(id)sender {
    
}

- (IBAction)actCapture:(id)sender {
    NSLog(@"%s", __func__);
    AVCaptureConnection *videoConnection = nil;
    for (AVCaptureConnection *connection in captureStillImageOutput.connections){
        for (AVCaptureInputPort *port in [connection inputPorts]){
            if ([[port mediaType] isEqual:AVMediaTypeVideo]){
                videoConnection = connection;
                break;
            }
        }
        if (videoConnection) {
            break;
        }
    }
    
    NSLog(@"about to request a capture from: %@", captureStillImageOutput);
    [captureStillImageOutput captureStillImageAsynchronouslyFromConnection:videoConnection completionHandler: ^(CMSampleBufferRef imageSampleBuffer, NSError *error){
        CFDictionaryRef exifAttachments = CMGetAttachment(imageSampleBuffer, kCGImagePropertyExifDictionary, NULL);
        if (exifAttachments){
            NSLog(@"attachements: %@", exifAttachments);
        } else {
            NSLog(@"no attachments");
        }
        
        // get row Image Data
        NSData *imageData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageSampleBuffer];
        
        UIImage *filteredImage = [self pointFilterForSave:imageData];
        [self saveToCameraAlbum:filteredImage];
    }];
}

-(void)tapToFocus:(UITapGestureRecognizer *)singleTap{
    CGPoint touchPoint = [singleTap locationInView:self.cameraOutputView];
    CGPoint focusPoint = [self calculateFocusPoint:touchPoint];
    if(captureDevice) {
        if([captureDevice isFocusPointOfInterestSupported] && [captureDevice isFocusModeSupported:AVCaptureFocusModeAutoFocus]) {
            if([captureDevice lockForConfiguration:nil]) {
                [captureDevice setFocusPointOfInterest:focusPoint];
                [captureDevice setFocusMode:AVCaptureFocusModeAutoFocus];
                [captureDevice setExposurePointOfInterest:focusPoint];
                [captureDevice setExposureMode:AVCaptureExposureModeAutoExpose];
            }
            [captureDevice unlockForConfiguration];
        }
    }
    NSLog(@"touch : %@", NSStringFromCGPoint(touchPoint));
    NSLog(@"foucus : %@", NSStringFromCGPoint(focusPoint));
}

- (CGPoint)calculateFocusPoint:(CGPoint)touchPoint {
    
    CGFloat focusX = touchPoint.x / modiImageSize.size.width;
    CGFloat focusY = touchPoint.y / modiImageSize.size.height;
    
    return CGPointMake(focusX, focusY);
}

#pragma mark - AVCaptureSession delegate
- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
    CVPixelBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    
    if (pixelBuffer) {
        CFDictionaryRef attachments = CMCopyDictionaryOfAttachments( kCFAllocatorDefault, sampleBuffer, kCMAttachmentMode_ShouldPropagate );
        CIImage *capturedImage = [[CIImage alloc] initWithCVPixelBuffer:pixelBuffer options:(__bridge NSDictionary *)attachments];
        oriImageSize = capturedImage.extent;
        
        CIImage *displayImage = [self resizeCIImageForDisPlay:capturedImage];
        CIImage *filteredDisplayImage = [self pointFilterForDisplay:displayImage];
        
        // make a new UIImage to return
        dispatch_async( dispatch_get_main_queue(),
                       ^{
                           UIView *view = self.cameraOutputView;
                           CGRect bounds = view.bounds;
                           CGFloat scale = view.contentScaleFactor;
                           
                           CGFloat extentFitWidth = displayImage.extent.size.height / ( bounds.size.height / bounds.size.width );
                           CGRect extentFit = CGRectMake( ( displayImage.extent.size.width - extentFitWidth ) / 2, 0, extentFitWidth, displayImage.extent.size.height );
                           
                           CGRect scaledBounds = CGRectMake( bounds.origin.x * scale, bounds.origin.y * scale, bounds.size.width * scale, bounds.size.height * scale );
                           
                           [ciContext drawImage:filteredDisplayImage inRect:scaledBounds fromRect:extentFit];
                           
                           [glContext presentRenderbuffer:GL_RENDERBUFFER];
                           [self.cameraOutputView display];
                       });
    }
}




#pragma mark - function
- (CIImage *)resizeCIImageForDisPlay:(CIImage *)oriImage {
    CIImage *modiImage = [oriImage imageByApplyingTransform:CGAffineTransformMakeScale(RESIZE_SCALE, RESIZE_SCALE)];
    modiImageSize = modiImage.extent;
    
    return modiImage;
}

- (CIImage *)pointFilterForDisplay:(CIImage *)displayImage {
    // the pixels will be painted to this array
    uint32_t *pixels = (uint32_t *) malloc(displayImage.extent.size.width * displayImage.extent.size.height * sizeof(uint32_t));
    
    // clear the pixels so any transparency is preserved
    memset(pixels, 0, displayImage.extent.size.width * displayImage.extent.size.height * sizeof(uint32_t));
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    
    // create a context with RGBA pixels
    CGContextRef context = CGBitmapContextCreate(pixels, displayImage.extent.size.width, displayImage.extent.size.height, 8, displayImage.extent.size.width * sizeof(uint32_t), colorSpace, kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedLast);
    
    // paint the bitmap to our context which will fill in the pixels array
    CIContext *tempContext = [CIContext contextWithOptions:nil];
    struct CGImage *cgImageRef = [tempContext createCGImage:displayImage fromRect:displayImage.extent];
    
    // CIImage -> context
    CGContextDrawImage(context, CGRectMake(0, 0, displayImage.extent.size.width, displayImage.extent.size.height), cgImageRef);
    CGImageRelease(cgImageRef);
    
    // Image Filtering //
    int pRED = 3; int pGREEN = 2; int pBLUE = 1;
    
    for(int pY=0; pY<displayImage.extent.size.height; pY++) {
        for(int pX=0; pX<displayImage.extent.size.width; pX++) {
            uint8_t *processPoint = (uint8_t *) &pixels[(pY) * (int)displayImage.extent.size.width + (pX)];
            int vR = (int)processPoint[pRED];
            int vG = (int)processPoint[pGREEN];
            int vB = (int)processPoint[pBLUE];
            hsvColor modiHSV = [self RGBtoHSV:vR Green:vG Blue:vB];
            if ((modiHSV.h >=0 && modiHSV.h <= RED_RANGE && modiHSV.s > self.sValueSlider.value && modiHSV.v > self.vValueSlider.value)
                || (modiHSV.h >=360 - RED_RANGE && modiHSV.h <= 360 && modiHSV.s > self.sValueSlider.value && modiHSV.v > self.vValueSlider.value)) {
            } else {
                int avrgColor = (int)((vR + vG + vB) * 0.3333);
                processPoint[pRED] = processPoint[pGREEN] = processPoint[pBLUE] = avrgColor;
            }
        }
    }
    
    //// .... image filtering End //
    
    // create a new CGImageRef from our context with the modified pixels
    CGImageRef image = CGBitmapContextCreateImage(context);
    CIImage *filteredImg = [[CIImage alloc] initWithCGImage:image];
    CGImageRelease(image);
    
    // we're done with the context, color space, and pixels
    CGContextRelease(context);
    CGColorSpaceRelease(colorSpace);
    free(pixels);
    
    
    return filteredImg;
}

- (UIImage *)pointFilterForSave:(NSData *)rowImage {
    CGDataProviderRef imgDataProvider = CGDataProviderCreateWithCFData((__bridge CFDataRef)(rowImage));
    CGImageRef imageRef = CGImageCreateWithJPEGDataProvider(imgDataProvider, NULL, true, kCGRenderingIntentDefault);
    
    // the pixels will be painted to this array
    uint32_t *pixels = (uint32_t *) malloc(oriImageSize.size.width * oriImageSize.size.height * sizeof(uint32_t));
    
    // clear the pixels so any transparency is preserved
    memset(pixels, 0, oriImageSize.size.width * oriImageSize.size.height * sizeof(uint32_t));
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    
    // create a context with RGBA pixels
    CGContextRef context = CGBitmapContextCreate(pixels, oriImageSize.size.width, oriImageSize.size.height, 8, oriImageSize.size.width * sizeof(uint32_t), colorSpace,
                                                 kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedLast);
    
    // CIImage -> context
    CGContextDrawImage(context, CGRectMake(0, 0, oriImageSize.size.width, oriImageSize.size.height), imageRef);
    CGImageRelease(imageRef);
    
    // Image Processing //
    int pRED = 3; int pGREEN = 2; int pBLUE = 1;
    
    for(int pY=0; pY<oriImageSize.size.height; pY++) {
        for(int pX=0; pX<oriImageSize.size.width; pX++) {
            uint8_t *processPoint = (uint8_t *) &pixels[(pY) * (int)oriImageSize.size.width + (pX)];
            int vR = (int)processPoint[pRED];
            int vG = (int)processPoint[pGREEN];
            int vB = (int)processPoint[pBLUE];
            hsvColor modiHSV = [self RGBtoHSV:vR Green:vG Blue:vB];
            if ((modiHSV.h >=0 && modiHSV.h <= RED_RANGE && modiHSV.s > 0.4 && modiHSV.v > 0.4) || (modiHSV.h >=360 - RED_RANGE && modiHSV.h <= 360 && modiHSV.s > 0.4 && modiHSV.v > 0.4)) {
                
            } else {
                int avrgColor = (int)((vR + vG + vB) * 0.333);
                processPoint[pRED] = processPoint[pGREEN] = processPoint[pBLUE] = avrgColor;
            }
        }
    }
    //// .... image Processing End //
    
    // create a new CGImageRef from our context with the modified pixels
    CGImageRef image = CGBitmapContextCreateImage(context);
    UIImage *filteredImg = [UIImage imageWithCGImage:image];
    
    CGImageRelease(image);
    
    // we're done with the context, color space, and pixels
    CGContextRelease(context);
    CGColorSpaceRelease(colorSpace);
    free(pixels);
    
    return filteredImg;
}

- (void)saveToCameraAlbum:(UIImage *)img
{
    __weak ALAssetsLibrary *alAssetLib = assetsLibrary;
    
    [alAssetLib addAssetsGroupAlbumWithName:@"PoCamera" resultBlock:^(ALAssetsGroup *group) {
        ///checks if group previously created
        if(group == nil){
            //enumerate albums
            [alAssetLib enumerateGroupsWithTypes:ALAssetsGroupAlbum usingBlock:^(ALAssetsGroup *g, BOOL *stop){
                //if the album is equal to our album
                if ([[g valueForProperty:ALAssetsGroupPropertyName] isEqualToString:@"PoCamera"]) {
                    //save image
                    [alAssetLib writeImageDataToSavedPhotosAlbum:UIImagePNGRepresentation(img) metadata:nil completionBlock:^(NSURL *assetURL, NSError *error) {
                        //then get the image asseturl
                        [alAssetLib assetForURL:assetURL resultBlock:^(ALAsset *asset) {
                            //put it into our album
                            [g addAsset:asset];
                        } failureBlock:^(NSError *error) {
                            NSLog(@"error 1");
                        }];
                    }];
                }
            }failureBlock:^(NSError *error){
                NSLog(@"error 2");
            }];
        }else{
            // save image directly to library
            [alAssetLib writeImageDataToSavedPhotosAlbum:UIImagePNGRepresentation(img) metadata:nil completionBlock:^(NSURL *assetURL, NSError *error) {
                [alAssetLib assetForURL:assetURL resultBlock:^(ALAsset *asset) {
                    [group addAsset:asset];
                } failureBlock:^(NSError *error) {
                    NSLog(@"error 3");
                }];
            }];
        }
    } failureBlock:^(NSError *error) {
        NSLog(@"error 4");
    }];
}

- (void)applySliderInfo {
    self.sValueLabel.text = [NSString stringWithFormat:@"%2f", self.sValueSlider.value];
    self.vValueLabel.text = [NSString stringWithFormat:@"%2f", self.vValueSlider.value];
}

- (hsvColor)RGBtoHSV:(int)r Green:(int)g Blue:(int)b {
    hsvColor tHSV;
    double min, max, delta;
    
    min = r < g ? r : g;
    min = min  < b ? min  : b;
    
    max = r > g ? r : g;
    max = max  > b ? max  : b;
    
    tHSV.v = max;                                // v
    delta = max - min;
    if( max > 0.0 ) { // NOTE: if Max is == 0, this divide would cause a crash
        tHSV.s = (delta / max);                  // s
    } else {
        // if max is 0, then r = g = b = 0
        // s = 0, v is undefined
        tHSV.s = 0.0;
        tHSV.h = 180.0; // its now undefined
        return tHSV;
    }
    if( r >= max )                           // > is bogus, just keeps compilor happy
        tHSV.h = ( g - b ) / delta;        // between yellow & magenta
    else
        if( g >= max )
            tHSV.h = 2.0 + ( b - r ) / delta;  //between cyan & yellow
        else
            tHSV.h = 4.0 + ( r - g ) / delta;  //between magenta & cyan
    
    tHSV.h *= 60.0;  // degrees
    
    if( tHSV.h < 0.0 )
        tHSV.h += 360.0;
    
    return tHSV;
}

@end
