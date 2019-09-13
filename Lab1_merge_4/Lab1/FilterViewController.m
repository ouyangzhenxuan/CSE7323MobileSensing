//
//  FilterViewController.m
//  Lab1
//
//  Created by Yu Chen on 9/8/19.
//  Copyright © 2019 梅沈潇. All rights reserved.
//

#import "FilterViewController.h"



@interface FilterViewController ()

@property (strong, nonatomic) NSArray* tagArray;
@property (strong, nonatomic) NSString* seletedTag;
@property (weak, nonatomic) IBOutlet UISlider *sliders;
@property (weak, nonatomic) IBOutlet UILabel *tagLabel;

@property (weak, nonatomic) IBOutlet UILabel *sliderValueLabel;
@property (weak, nonatomic) IBOutlet UIPickerView * tagPicker;
@property (weak, nonatomic) IBOutlet UIView *modalView;
@property (strong, nonatomic) NSNumber *sliderValue;
@property (weak, nonatomic) IBOutlet UILabel *stepperValueLabel;
@property (weak, nonatomic) IBOutlet UIStepper *steppers;
@property (weak, nonatomic) IBOutlet UISwitch *switchs;
@property (strong, nonatomic) NSNumber *stepperValue;
@end

@implementation FilterViewController
@synthesize sliderValue = _sliderValue;
@synthesize stepperValue = _stepperValue;
@synthesize delegate = _delegate;

- (IBAction)tapDimiss:(UITapGestureRecognizer *)sender {
    CATransition *animation = [CATransition animation];
    animation.type = kCATransitionFade;
    animation.duration = 0.4;
    [self.tagPicker.layer addAnimation:animation forKey:nil];
    self.tagPicker.hidden = true;
}

-(NSNumber*)sliderValue{
    if(!_sliderValue)
        _sliderValue = @59.99;
    return _sliderValue;
}

-(NSNumber*)stepperValue{
    if(!_stepperValue)
        _stepperValue = @8;
    return _stepperValue;
}

- (void)setStepperValue:(NSNumber *)stepperValue{
    _stepperValue = stepperValue;
    self.stepperValueLabel.text = [NSString stringWithFormat:@"%@", _stepperValue];
    
}
- (void)setSliderValue:(NSNumber *)sliderValue{
    _sliderValue = sliderValue;
    self.sliderValueLabel.text = [NSString stringWithFormat:@"$%@", _sliderValue];
}

- (IBAction)sliderChange:(UISlider *)sender {
    self.sliderValue = @(sender.value);
}
- (IBAction)stepperChange:(UIStepper *)sender {
    self.stepperValue= @(sender.value);
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.modalView.layer.cornerRadius = 10;
    self.modalView.layer.masksToBounds = true;
    // Do any additional setup after loading the view.
    self.tagPicker.delegate = self;
    self.tagPicker.hidden = true;
    
    self.tagPicker.backgroundColor = [UIColor grayColor];
    self.tagPicker.layer.zPosition = 1;
    
    self.sliders.maximumValue = 59.99;
    self.sliders.minimumValue = 0;
    self.sliders.value = 59.99;
    
    self.steppers.maximumValue = 8;
    self.steppers.minimumValue =1;
    self.steppers.value = 8;
    
    [self.switchs setOnTintColor:[UIColor redColor]];
    [self.sliders setTintColor:[UIColor redColor]];
    [self.steppers setTintColor:[UIColor redColor]];
    
}

-(void) dismissPicker:(id)sender {
    self.tagPicker.hidden = true;
}


- (NSArray*) tagArray{
    if(!_tagArray){
        _tagArray =@[@"Racing",@"Platformer",@"Mutiplayer",@"Sports",@"Arcade",@"Action",@"Adventure",@"Strategy",@"Role-Playing",@"Lifestyle",@"Simulation"];
    }
    return _tagArray;
}
- (IBAction)tagPickerButton:(id)sender {
    if(self.tagPicker.hidden){
        CATransition *animation = [CATransition animation];
        animation.type = kCATransitionFromBottom;
        animation.duration = 0.4;
        [self.tagPicker.layer addAnimation:animation forKey:nil];
        self.tagPicker.hidden = false;
    }else {
        CATransition *animation = [CATransition animation];
        animation.type = kCATransitionFade;
        animation.duration = 0.4;
        [self.tagPicker.layer addAnimation:animation forKey:nil];
        self.tagPicker.hidden = true;
    }
    
}
- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    return 1;
}

- (NSInteger)pickerView: (UIPickerView*)pickerView numberOfRowsInComponent:(NSInteger)component {
    return self.tagArray.count;
    
}

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
    return self.tagArray[row];
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component{
    self.seletedTag = self.tagArray[row];
    self.tagLabel.text = self.seletedTag;
}
/*
 #pragma mark - Navigation
 
 // In a storyboard-based application, you will often want to do a little preparation before navigation
 - (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
 // Get the new view controller using [segue destinationViewController].
 // Pass the selected object to the new view controller.
 }
 */
- (IBAction)cancelButton:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}
- (IBAction)finishButton:(id)sender {
    NSString* switchValue=[self.switchs isOn] ? @"YES" : @"NO";
    NSArray* modalData=@[self.tagLabel.text, self.stepperValueLabel.text, [self.sliderValue stringValue],switchValue];
    [self.delegate delegateData:modalData];
    [self dismissViewControllerAnimated:YES completion:nil];
    NSLog(@"%@",@"?");
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
    NSLog(@"%@",@"yesyes");
}

@end
