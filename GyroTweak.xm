#import <Foundation/Foundation.h>
#import <CoreMotion/CoreMotion.h>
#import <UIKit/UIKit.h>
#import "GyroTweak.h"

static CMMotionManager* _motionManager = nil;
static dispatch_queue_t _motionQueue = nil;
static float _sensitivity = 1.0f;
static UIWindow* _settingsWindow = nil;

static const float kDefaultSensitivity = 1.0f;
static const float kMinSensitivity = 0.1f;
static const float kMaxSensitivity = 5.0f;

static void GyroTweak_LoadSettings() {
    NSUserDefaults* prefs = [NSUserDefaults standardUserDefaults];
    float saved = [prefs floatForKey:@"GyroTweakSensitivity"];
    _sensitivity = saved > 0 ? saved : kDefaultSensitivity;
}

static void GyroTweak_SaveSettings() {
    NSUserDefaults* prefs = [NSUserDefaults standardUserDefaults];
    [prefs setFloat:_sensitivity forKey:@"GyroTweakSensitivity"];
    [prefs synchronize];
}

@interface GyroSettingsViewController : UIViewController
@end

@implementation GyroSettingsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.9];
    self.view.layer.cornerRadius = 16;
    self.view.layer.masksToBounds = YES;

    UIView* container = [[UIView alloc] init];
    container.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:container];

    UILabel* title = [[UILabel alloc] init];
    title.text = @"GyroTweak";
    title.font = [UIFont boldSystemFontOfSize:20];
    title.textColor = [UIColor whiteColor];
    title.textAlignment = NSTextAlignmentCenter;
    title.translatesAutoresizingMaskIntoConstraints = NO;
    [container addSubview:title];

    UILabel* sensLabel = [[UILabel alloc] init];
    sensLabel.text = @"Чувствительность";
    sensLabel.font = [UIFont systemFontOfSize:16];
    sensLabel.textColor = [UIColor lightGrayColor];
    sensLabel.textAlignment = NSTextAlignmentCenter;
    sensLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [container addSubview:sensLabel];

    UISlider* slider = [[UISlider alloc] init];
    slider.minimumValue = kMinSensitivity;
    slider.maximumValue = kMaxSensitivity;
    slider.value = _sensitivity;
    slider.minimumTrackTintColor = [UIColor systemBlueColor];
    slider.translatesAutoresizingMaskIntoConstraints = NO;
    [slider addTarget:self action:@selector(sliderChanged:) forControlEvents:UIControlEventValueChanged];
    [container addSubview:slider];

    UILabel* valueLabel = [[UILabel alloc] init];
    valueLabel.font = [UIFont monospacedDigitSystemFontOfSize:16 weight:UIFontWeightMedium];
    valueLabel.textColor = [UIColor whiteColor];
    valueLabel.text = [NSString stringWithFormat:@"%.2f", _sensitivity];
    valueLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [container addSubview:valueLabel];

    UIButton* closeBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    [closeBtn setTitle:@"Готово" forState:UIControlStateNormal];
    closeBtn.titleLabel.font = [UIFont boldSystemFontOfSize:18];
    [closeBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    closeBtn.backgroundColor = [UIColor systemBlueColor];
    closeBtn.layer.cornerRadius = 10;
    closeBtn.translatesAutoresizingMaskIntoConstraints = NO;
    [closeBtn addTarget:self action:@selector(closeTapped:) forControlEvents:UIControlEventTouchUpInside];
    [container addSubview:closeBtn];

    [NSLayoutConstraint activateConstraints:@[
        container.centerXAnchor.constraintEqualToAnchor:self.view.centerXAnchor,
        container.centerYAnchor.constraintEqualToAnchor:self.view.centerYAnchor,
        container.widthAnchor.constraintEqualToConstant:300,

        title.topAnchor.constraintEqualToAnchor:container.topAnchor, constant:20],
        title.leadingAnchor.constraintEqualToAnchor:container.leadingAnchor, constant:20],
        title.trailingAnchor.constraintEqualToAnchor:container.trailingAnchor, constant:-20],

        sensLabel.topAnchor.constraintEqualToAnchor:title.bottomAnchor, constant:20],
        sensLabel.leadingAnchor.constraintEqualToAnchor:container.leadingAnchor, constant:20],

        slider.topAnchor.constraintEqualToAnchor:sensLabel.bottomAnchor, constant:12],
        slider.leadingAnchor.constraintEqualToAnchor:container.leadingAnchor, constant:20],
        slider.trailingAnchor.constraintEqualToAnchor:valueLabel.leadingAnchor, constant:-12],

        valueLabel.centerYAnchor.constraintEqualToAnchor:slider.centerYAnchor],
        valueLabel.trailingAnchor.constraintEqualToAnchor:container.trailingAnchor, constant:-20],
        valueLabel.widthAnchor.constraintEqualToConstant:50],

        closeBtn.topAnchor.constraintEqualToAnchor:slider.bottomAnchor, constant:24],
        closeBtn.leadingAnchor.constraintEqualToAnchor:container.leadingAnchor, constant:20],
        closeBtn.trailingAnchor.constraintEqualToAnchor:container.trailingAnchor, constant:-20],
        closeBtn.heightAnchor.constraintEqualToConstant:48],
        closeBtn.bottomAnchor.constraintEqualToAnchor:container.bottomAnchor, constant:-20]
    ];

    objc_setAssociatedObject(self, "slider", slider, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    objc_setAssociatedObject(self, "valueLabel", valueLabel, OBJC_ASSOCIATION_RETAIN_NONATOMIC);

    [self updateLabel];
}

- (void)updateLabel {
    UILabel* valueLabel = objc_getAssociatedObject(self, "valueLabel");
    valueLabel.text = [NSString stringWithFormat:@"%.2f", _sensitivity];
}

- (void)sliderChanged:(UISlider*)sender {
    _sensitivity = sender.value;
    [self updateLabel];
}

- (void)closeTapped:(id)sender {
    GyroTweak_SaveSettings();
    [self dismissWindow];
}

- (void)dismissWindow {
    if (_settingsWindow) {
        [_settingsWindow setHidden:YES];
        _settingsWindow = nil;
    }
}

@end

static void GyroTweak_ShowSettings() {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (_settingsWindow) return;

        UIWindow* keyWindow = nil;
        for (UIWindow* w in [UIApplication sharedApplication].windows) {
            if (w.windowLevel == UIWindowLevelNormal && !w.hidden && w.frame.size.width > 0) {
                keyWindow = w;
                break;
            }
        }
        if (!keyWindow) keyWindow = [UIApplication sharedApplication].keyWindow;
        if (!keyWindow) return;

        GyroSettingsViewController* vc = [[GyroSettingsViewController alloc] init];
        vc.modalPresentationStyle = UIModalPresentationOverFullScreen;
        vc.view.backgroundColor = [UIColor colorWithWhite:0 alpha:0.4];

        _settingsWindow = [[UIWindow alloc] initWithFrame:keyWindow.frame];
        _settingsWindow.windowLevel = UIWindowLevelAlert + 1;
        _settingsWindow.rootViewController = vc;
        _settingsWindow.backgroundColor = [UIColor clearColor];
        [_settingsWindow makeKeyAndVisible];
    });
}

@interface GyroTweakGestureHandler : NSObject
+ (void)handleTripleTap:(UITapGestureRecognizer*)gesture;
@end

@implementation GyroTweakGestureHandler
+ (void)handleTripleTap:(UITapGestureRecognizer*)gesture {
    if (gesture.state == UIGestureRecognizerStateRecognized) {
        GyroTweak_ShowSettings();
    }
}
@end

static void GyroTweak_InstallGesture() {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIWindow* keyWindow = nil;
        for (UIWindow* w in [UIApplication sharedApplication].windows) {
            if (w.windowLevel == UIWindowLevelNormal && !w.hidden) {
                keyWindow = w;
                break;
            }
        }
        if (!keyWindow) return;

        UITapGestureRecognizer* tap = [[UITapGestureRecognizer alloc] initWithTarget:[GyroTweakGestureHandler class] action:@selector(handleTripleTap:)];
        tap.numberOfTapsRequired = 2;
        tap.numberOfTouchesRequired = 3;
        [keyWindow addGestureRecognizer:tap];
    });
}

__attribute__((constructor))
static void GyroTweak_Constructor(void) {
    GyroTweak_LoadSettings();
    GyroTweak_Init();
    GyroTweak_InstallGesture();
}

__attribute__((destructor))
static void GyroTweak_Destructor(void) {
    GyroTweak_Shutdown();
}

int GyroTweak_Init(void) {
    if (_motionManager != nil) return 0;

    _motionManager = [[CMMotionManager alloc] init];
    if (!_motionManager) return -1;

    _motionQueue = dispatch_queue_create("com.gyrotweak.motion", DISPATCH_QUEUE_SERIAL);
    if (!_motionQueue) {
        [_motionManager release];
        _motionManager = nil;
        return -1;
    }

    _motionManager.gyroUpdateInterval = 1.0 / 60.0;
    _motionManager.accelerometerUpdateInterval = 1.0 / 60.0;
    _motionManager.deviceMotionUpdateInterval = 1.0 / 60.0;

    if ([_motionManager isGyroAvailable]) {
        [_motionManager startGyroUpdatesToQueue:_motionQueue withHandler:^(CMGyroData* gyroData, NSError* err) {}];
    }
    if ([_motionManager isAccelerometerAvailable]) {
        [_motionManager startAccelerometerUpdatesToQueue:_motionQueue withHandler:^(CMAccelerometerData* accelData, NSError* err) {}];
    }
    if ([_motionManager isDeviceMotionAvailable]) {
        [_motionManager startDeviceMotionUpdatesUsingReferenceFrame:CMAttitudeReferenceFrameXArbitraryZVertical
                                                           toQueue:_motionQueue
                                                      withHandler:^(CMDeviceMotion* motion, NSError* err) {}];
    }
    return 0;
}

void GyroTweak_Shutdown(void) {
    if (_motionManager) {
        [_motionManager stopGyroUpdates];
        [_motionManager stopAccelerometerUpdates];
        [_motionManager stopDeviceMotionUpdates];
        [_motionManager release];
        _motionManager = nil;
    }
    if (_motionQueue) {
        dispatch_release(_motionQueue);
        _motionQueue = nil;
    }
}

int GyroTweak_GetRotationRate(float* outX, float* outY, float* outZ) {
    if (!_motionManager || !_motionManager.gyroData) return -1;
    CMGyroData* data = _motionManager.gyroData;
    if (outX) *outX = data.rotationRate.x * _sensitivity;
    if (outY) *outY = data.rotationRate.y * _sensitivity;
    if (outZ) *outZ = data.rotationRate.z * _sensitivity;
    return 0;
}

int GyroTweak_GetAcceleration(float* outX, float* outY, float* outZ) {
    if (!_motionManager || !_motionManager.accelerometerData) return -1;
    CMAccelerometerData* data = _motionManager.accelerometerData;
    if (outX) *outX = data.acceleration.x * _sensitivity;
    if (outY) *outY = data.acceleration.y * _sensitivity;
    if (outZ) *outZ = data.acceleration.z * _sensitivity;
    return 0;
}

int GyroTweak_GetAttitudeQuaternion(float* outX, float* outY, float* outZ, float* outW) {
    if (!_motionManager || !_motionManager.deviceMotion) return -1;
    CMAttitude* attitude = _motionManager.deviceMotion.attitude;
    if (outX) *outX = attitude.quaternion.x;
    if (outY) *outY = attitude.quaternion.y;
    if (outZ) *outZ = attitude.quaternion.z;
    if (outW) *outW = attitude.quaternion.w;
    return 0;
}

int GyroTweak_IsAvailable(void) {
    if (!_motionManager) return 0;
    return [_motionManager isGyroAvailable] || [_motionManager isDeviceMotionAvailable];
}

float GyroTweak_GetSensitivity(void) { return _sensitivity; }
void GyroTweak_SetSensitivity(float v) {
    if (v < kMinSensitivity) v = kMinSensitivity;
    if (v > kMaxSensitivity) v = kMaxSensitivity;
    _sensitivity = v;
    GyroTweak_SaveSettings();
}
