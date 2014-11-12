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
#import <ImageIO/CGImageProperties.h>
#import <AssetsLibrary/AssetsLibrary.h>

typedef struct hsvColor {
    float h;
    float s;
    float v;
}hsvColor;

#define DIFF_COLOR_RANGE 80
#define RED_RANGE 10
#define RESIZE_SCALE 0.4f
#define S_DEFAULT_VALUE 0.4f
#define V_DEFAULT_VALUE 0.4f

@interface MainViewController : UIViewController <AVCaptureMetadataOutputObjectsDelegate, AVCaptureVideoDataOutputSampleBufferDelegate, UIGestureRecognizerDelegate>
{
    EAGLContext *glContext;
    CIContext *ciContext;
    
    AVCaptureDevice *captureDevice;
    AVCaptureDeviceInput *captureDeviceInput;
    AVCaptureVideoDataOutput *captureVideoOutput;
    AVCaptureStillImageOutput *captureStillImageOutput;
    AVCaptureSession *captureSession;
    
    ALAssetsLibrary *assetsLibrary;
    
    CGRect oriImageSize;
    CGRect modiImageSize;
    
    CGFloat settingViewWidth;
    BOOL isSettingViewHide;
    
    CGFloat colorDegrees;
}
@property (weak, nonatomic) IBOutlet GLKView *cameraOutputView;
@property (weak, nonatomic) IBOutlet UIView *settingView;

@property (weak, nonatomic) IBOutlet UIButton *showSettingButton;
@property (weak, nonatomic) IBOutlet UIButton *captureButton;



// settingView
@property (weak, nonatomic) IBOutlet UIButton *hideSettingButton;

@property (weak, nonatomic) IBOutlet UIButton *redColorButton;
@property (weak, nonatomic) IBOutlet UIButton *yellowColorButton;
@property (weak, nonatomic) IBOutlet UIButton *blueColorButton;
@property (weak, nonatomic) IBOutlet UIButton *greenColorButton;

@property (weak, nonatomic) IBOutlet UISlider *hValueSlider;
@property (weak, nonatomic) IBOutlet UISlider *sValueSlider;
@property (weak, nonatomic) IBOutlet UISlider *vValueSlider;
@property (weak, nonatomic) IBOutlet UILabel *hValueLabel;
@property (weak, nonatomic) IBOutlet UILabel *sValueLabel;
@property (weak, nonatomic) IBOutlet UILabel *vValueLabel;


@end
