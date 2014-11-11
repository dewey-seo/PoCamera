//
//  MainViewController.h
//  PoCamera
//
//  Created by 서광덕 on 2014. 11. 11..
//  Copyright (c) 2014년 Dewey. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <GLKit/GLKit.h>
#import <AVFoundation/AVFoundation.h>
#import <AssetsLibrary/AssetsLibrary.h>

typedef struct hsvColor {
    float h;
    float s;
    float v;
}hsvColor;

#define DIFF_COLOR_RANGE 80
#define RED_RANGE 10
#define RESIZE_SCALE 0.4f

@interface MainViewController : UIViewController <AVCaptureMetadataOutputObjectsDelegate, AVCaptureVideoDataOutputSampleBufferDelegate>
{
    EAGLContext *glContext;
    CIContext *ciContext;
    
    AVCaptureDeviceInput *captureDeviceInput;
    AVCaptureVideoDataOutput *captureVideoOutput;
    AVCaptureStillImageOutput *captureStillImageOutput;
    AVCaptureSession *captureSession;
    
    ALAssetsLibrary *assetsLibrary;
    
    CGRect oriImageSize;
    CGRect modiImageSize;
    
    CGFloat settingViewWidth;
    BOOL isSettingViewHide;
}
@property (weak, nonatomic) IBOutlet GLKView *cameraOutputView;
@property (weak, nonatomic) IBOutlet UIView *settingView;

@property (weak, nonatomic) IBOutlet UIButton *showSettingButton;
@property (weak, nonatomic) IBOutlet UIButton *hideSettingButton;
@property (weak, nonatomic) IBOutlet UIButton *captureButton;

@end
