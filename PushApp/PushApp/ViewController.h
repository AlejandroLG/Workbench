//
//  ViewController.h
//  PushApp
//
//  Created by Alejandro López on 8/18/15.
//  Copyright (c) 2015 BBVA Bancomer. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ViewController : UIViewController

@property (strong, nonatomic) IBOutlet UITextView *txtVwMessage;
@property (strong, nonatomic) IBOutlet UISwitch *switchAll;
@property (strong, nonatomic) IBOutlet UITableView *tblUsers;
@property (strong, nonatomic) IBOutlet UILabel *lblSelectUSer;

@property (weak, nonatomic) IBOutlet UILabel *lblMessageToBeSent;
@property (weak, nonatomic) IBOutlet UIButton *btnSendPush;
@property (weak, nonatomic) IBOutlet UILabel *lblToAllDevices;
@property (weak, nonatomic) IBOutlet UIScrollView *scroll;
@property (weak, nonatomic) IBOutlet UILabel *lblJSONformat;
@property (weak, nonatomic) IBOutlet UISwitch *switchJSON;

@end

