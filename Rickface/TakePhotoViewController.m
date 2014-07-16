//
//  SNGViewController.m
//  Camera Handler
//
//  Created by Eddy Gammon on 08/05/2014.
//  Copyright (c) 2014 Kudan. All rights reserved.
//

static void * CapturingStillImageContext = &CapturingStillImageContext;
static void * SessionRunningAndDeviceAuthorizedContext = &SessionRunningAndDeviceAuthorizedContext;

#import "TakePhotoViewController.h"
#import "TakePhotoViewController+SocialShare.h"
#import <Parse/Parse.h>
#import "GAI.h"
#import "GAIDictionaryBuilder.h"
@import AssetsLibrary;
@import AVFoundation;
@import Social;

@interface TakePhotoViewController () <AVCaptureVideoDataOutputSampleBufferDelegate, UITextFieldDelegate>

@property (weak, nonatomic) IBOutlet UIView *cameraView;
@property (weak, nonatomic) IBOutlet UIButton *takePhotoButton;
@property (weak, nonatomic) IBOutlet UIButton *switchCameraButton;
@property (weak, nonatomic) IBOutlet UIButton *cancelButton;

- (IBAction)takePicture:(UIButton *)sender;
- (IBAction)switchCamera:(UIButton *)sender;
- (IBAction)cancelPressed:(id)sender;

- (void)checkDeviceAuthorisationStatus;

// Session management.
@property (nonatomic) dispatch_queue_t sessionQueue;
@property (nonatomic) AVCaptureSession *captureSession;
@property (nonatomic) AVCaptureDeviceInput *videoDeviceInput;
@property (nonatomic) AVCaptureVideoDataOutput *videoOutput;
@property (nonatomic) AVCaptureStillImageOutput *stillImageOutput;
@property (nonatomic) CIContext *ciContext;

// Utilities.
@property (nonatomic) UIBackgroundTaskIdentifier backgroundRecordingID;
@property (nonatomic, getter = isDeviceAuthorized) BOOL deviceAuthorized;
@property (nonatomic, readonly, getter = isSessionRunningAndDeviceAuthorized) BOOL sessionRunningAndDeviceAuthorized;
@property (nonatomic) BOOL lockInterfaceRotation;

@end

@implementation TakePhotoViewController

- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    [self.takePhotoButton setTitle:CameraString forState:UIControlStateNormal];
    [self.takePhotoButton.titleLabel setFont:[UIFont fontWithName:@"FontAwesome" size:24]];
	self.takePhotoButton.layer.borderColor = [UIColor redColor].CGColor;
    self.takePhotoButton.layer.borderWidth = 5;
    self.takePhotoButton.layer.cornerRadius = self.takePhotoButton.layer.bounds.size.width/2.;
    
	AVCaptureSession *session = [[AVCaptureSession alloc] init];
    
	self.captureSession = session;
    
	[self checkDeviceAuthorisationStatus];
	
	self.ciContext = [CIContext contextWithOptions:nil];
	
	// In general it is not safe to mutate an AVCaptureSession or any of its inputs, outputs, or connections from multiple threads at the same time.
	// Why not do all of this on the main queue?
	// -[AVCaptureSession startRunning] is a blocking call which can take a long time. We dispatch session setup to the sessionQueue so that the main queue isn't blocked (which keeps the UI responsive).
	
	dispatch_queue_t sessionQueue = dispatch_queue_create("session queue", DISPATCH_QUEUE_SERIAL);
	self.sessionQueue = sessionQueue;
	
	dispatch_async(sessionQueue, ^{
		[self setBackgroundRecordingID:UIBackgroundTaskInvalid];
		
		NSError *error = nil;
		
		AVCaptureDevice *videoDevice = [TakePhotoViewController deviceWithMediaType:AVMediaTypeVideo preferringPosition:AVCaptureDevicePositionFront];
		AVCaptureDeviceInput *videoDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:videoDevice error:&error];
		
		if (error)
		{
			NSLog(@"%@", error);
		}
		
		if ([session canAddInput:videoDeviceInput])
		{
			[session addInput:videoDeviceInput];
			[self setVideoDeviceInput:videoDeviceInput];
		}
		
		AVCaptureStillImageOutput *stillImageOutput = [[AVCaptureStillImageOutput alloc] init];
		if ([session canAddOutput:stillImageOutput])
		{
			[stillImageOutput setOutputSettings:@{AVVideoCodecKey : AVVideoCodecJPEG}];
			[session addOutput:stillImageOutput];
			self.stillImageOutput = stillImageOutput;
		}
		
		AVCaptureVideoDataOutput *videoOutput = [AVCaptureVideoDataOutput new];
		self.videoOutput = videoOutput;
		videoOutput.videoSettings = @{(id)kCVPixelBufferPixelFormatTypeKey:@(kCVPixelFormatType_32BGRA)};
		[videoOutput setSampleBufferDelegate:self queue:self.sessionQueue];
		
		if ([session canAddOutput:videoOutput]) {
			
			[session addOutput:videoOutput];
		}
	});
}

- (void)viewWillAppear:(BOOL)animated
{
	dispatch_async(self.sessionQueue, ^{
		[self.captureSession startRunning];
		
	});
}

- (void)checkDeviceAuthorisationStatus
{
	NSString *mediaType = AVMediaTypeVideo;
	
	[AVCaptureDevice requestAccessForMediaType:mediaType completionHandler:^(BOOL granted) {
        
		if (granted) {
			self.deviceAuthorized = YES;
			
		} else {
            
			dispatch_async(dispatch_get_main_queue(), ^{
				[[[UIAlertView alloc] initWithTitle:@"AVCam!"
											message:@"AVCam doesn't have permission to use Camera, please change privacy settings"
										   delegate:self
								  cancelButtonTitle:@"OK"
								  otherButtonTitles:nil] show];
				self.deviceAuthorized = NO;
			});
		}
	}];
}

+ (AVCaptureDevice *)deviceWithMediaType:(NSString *)mediaType preferringPosition:(AVCaptureDevicePosition)position
{
	NSArray *devices = [AVCaptureDevice devicesWithMediaType:mediaType];
	AVCaptureDevice *captureDevice = [devices firstObject];
	
	for (AVCaptureDevice *device in devices)
	{
		if ([device position] == position)
		{
			captureDevice = device;
			break;
		}
	}
	
	return captureDevice;
}

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
	
	[connection setVideoOrientation:AVCaptureVideoOrientationPortrait];
	
	CVPixelBufferRef ref = CMSampleBufferGetImageBuffer(sampleBuffer);
	CIImage *image = [CIImage imageWithCVPixelBuffer:ref];
    CGImageRef cgImage = [self.ciContext createCGImage:image fromRect:[image extent]];
	
    if (!cgImage) {
        return;
    }
    
    UIImage *flipped = [UIImage imageWithCGImage:cgImage scale:2.0 orientation:UIImageOrientationDownMirrored];
    
	dispatch_async(dispatch_get_main_queue(), ^{
		self.cameraView.layer.contents = (id)CFBridgingRelease(flipped.CGImage);
	});
}

#pragma mark - UI Stuff
- (IBAction)takePicture:(UIButton *)sender {
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSMutableDictionary *event = [[GAIDictionaryBuilder createEventWithCategory:@"Picture" action:@"Taken" label:self.moodLabel.text value:nil] build];
        [[GAI sharedInstance].defaultTracker send:event];
        [[GAI sharedInstance] dispatch];
    });
    
    [self.captureSession stopRunning];
    
	CGImageRef imageRef = (__bridge CGImageRef)(self.cameraView.layer.contents);
	
//	[[[ALAssetsLibrary alloc] init] writeImageToSavedPhotosAlbum:[image CGImage] orientation:ALAssetOrientationUp completionBlock:nil];
    
    UIImage *userImage = [UIImage imageWithCGImage:imageRef];
    // amalgamate the two images
    UIImage *imageToShare = [self imageFromRick:self.rickFaceImageView.image andUser:userImage];
    // and share (in category)
    [self showShareScreenWithImage:imageToShare];
}

- (UIImage *)imageFromRick:(UIImage *)rickface andUser:(UIImage *)userface {
    
    CGSize rickSize = rickface.size;
//    CGSize userSize = userface.size;
//    CGFloat scale = userSize.height/rickSize.height;
    
    CGSize fullSize = CGSizeMake(rickSize.width*2, rickSize.height);
    
    UIGraphicsBeginImageContextWithOptions(fullSize, YES, 0);
    
    [rickface drawInRect:CGRectMake(0, 0, rickSize.width, rickSize.height)];
    
    CGRect offsetRect = CGRectMake(rickface.size.width, 0, rickface.size.width, rickface.size.height);
    [userface drawInRect:offsetRect];
    
    UIImage *combImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return combImage;
}

- (IBAction)switchCamera:(UIButton *)sender {
    
	dispatch_async([self sessionQueue], ^{
		AVCaptureDevice *currentVideoDevice = [[self videoDeviceInput] device];
		AVCaptureDevicePosition preferredPosition = AVCaptureDevicePositionUnspecified;
		AVCaptureDevicePosition currentPosition = [currentVideoDevice position];
		
		switch (currentPosition) {
                
			case AVCaptureDevicePositionUnspecified:
				preferredPosition = AVCaptureDevicePositionBack;
				break;
			case AVCaptureDevicePositionBack:
				preferredPosition = AVCaptureDevicePositionFront;
				break;
			case AVCaptureDevicePositionFront:
				preferredPosition = AVCaptureDevicePositionBack;
				break;
		}
		
		AVCaptureDevice *videoDevice = [TakePhotoViewController deviceWithMediaType:AVMediaTypeVideo preferringPosition:preferredPosition];
		AVCaptureDeviceInput *videoDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:videoDevice error:nil];
		
		[self.captureSession beginConfiguration];
		
		[self.captureSession removeInput:[self videoDeviceInput]];
		
		if ([self.captureSession canAddInput:videoDeviceInput]) {
			[self.captureSession addInput:videoDeviceInput];
			[self setVideoDeviceInput:videoDeviceInput];
            
		} else {
			[self.captureSession addInput:[self videoDeviceInput]];
		}
		
		[self.captureSession commitConfiguration];
	});
}

- (IBAction)cancelPressed:(id)sender {
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
