//
//  ViewController.m
//  PushApp
//
//  Created by Alejandro López on 8/18/15.
//  Copyright (c) 2015 BBVA Bancomer. All rights reserved.
//

#import "ViewController.h"
#import <Parse/Parse.h>
#define IS_IPHONE_4 ( fabs( ( double )[ [ UIScreen mainScreen ] bounds ].size.height - ( double )480 ) < DBL_EPSILON )

@interface ViewController () <UITableViewDataSource, UITableViewDelegate>

@property(strong, nonatomic) NSArray *currentUsers;
@property(nonatomic) NSInteger indexSelected;
@property(nonatomic) float content;
@property(nonatomic, strong) PFObject *currentUserSelected;

@end

@implementation ViewController

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if(_switchAll.isOn)
        [self showHideAllDevicesView:YES];
    else
        [self showHideAllDevicesView:NO];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Add an observer that detects when keyboard will be presented
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(showKeyBoard:)
                                                 name:UIKeyboardWillChangeFrameNotification
                                               object:nil];
    
    // Add an observer that detects when keyboard will be hidden
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(hideKeyBoard:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];
    
    // Set tap gesture recognizer when user taps on any place of the view, in order to hide the keyboard
    UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapAnywhere:)];
    tapRecognizer.cancelsTouchesInView = NO;
    [self.view addGestureRecognizer:tapRecognizer];
    
    [_switchAll setOn:YES];
    [_switchJSON setOn:YES];
    [self loadAllUsersFromParse];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)sendPushAction:(id)sender {
    if(_txtVwMessage.text.length > 0) {
        PFPush *push = [[PFPush alloc] init];

        if(!_switchAll.isOn && _currentUserSelected != nil) {
            // Make a query for specific user.
            PFQuery *qe = [PFInstallation query];
            [qe whereKey:@"user" equalTo:_currentUserSelected];
            [push setQuery:qe];
        }
        
        [push setMessage:_txtVwMessage.text];
        [push sendPushInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
            if(succeeded) {
                NSLog(@"The push has beeen sent successfully!");
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Success"
                                                                message:@"The push was sent"
                                                               delegate:nil
                                                      cancelButtonTitle:@"Continue"
                                                      otherButtonTitles:nil, nil];
                [alert show];
            }
        }];
        
        [_txtVwMessage setText:@""];
        _indexSelected = -1;
        [_tblUsers reloadData];
    }
    else {
        if(_switchJSON.isOn) {
            PFPush *push = [[PFPush alloc] init];
            NSString *jsonFormat = @"{\"aps\":{\"alert\":{\"body\":\"Tienes un nuevo recibo por pagar por parte de Iusacell, ¿Deseas pagarlo ahora?\",\"title\":\"Nuevo Recibo\"},\"category\":\"BILL_RECEIVED_CATEGORY\",\"badge\":\"Increment\",\"sound\":\"default\"},\"datosrecibo\":{\"descripcion\":\"Nuevo recibo\",\"idCompania\":\"12344321424\",\"idReferencia\":\"13579864\",\"nombreCompania\":\"Iusacell\",\"montoPagar\":\"1010.00\",\"diasRestantes\":\"26\"}}";
            
            NSData *jsonData = [jsonFormat dataUsingEncoding:NSUTF8StringEncoding];
            NSError *error;
            NSDictionary *data = [NSJSONSerialization JSONObjectWithData:jsonData
                                                                           options:NSJSONReadingAllowFragments
                                                                             error:&error];
            
            if (!_switchAll.isOn && _currentUserSelected != nil) {
                // Make a query for specific user.
                PFQuery *qe = [PFInstallation query];
                [qe whereKey:@"user" equalTo:_currentUserSelected];
                [push setQuery:qe];
            }
                
            [push setData:data];
            [push sendPushInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                if(succeeded) {
                    NSLog(@"The push has beeen sent successfully!\n%@", data);
                    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Success"
                                                                    message:[NSString stringWithFormat:@"The push was sent:\n%@", data]
                                                                   delegate:nil
                                                          cancelButtonTitle:@"Continue"
                                                          otherButtonTitles:nil, nil];
                    [alert show];
                }
            }];
                
            [_txtVwMessage setText:@""];
            _indexSelected = -1;
            [_tblUsers reloadData];
        }
        else {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Warning"
                                                            message:@"You must write a message to send a push"
                                                           delegate:nil
                                                  cancelButtonTitle:@"Continue"
                                                  otherButtonTitles:nil, nil];
            [alert show];
        }
    }
}

- (IBAction)siwitchAction:(id)sender {
    UISwitch *switchComponent = (UISwitch *)sender;
    if(switchComponent.isOn) {
        NSLog(@"Siwtch on");
        [self showHideAllDevicesView:YES];
        [_txtVwMessage resignFirstResponder];
    }
    else {
        NSLog(@"Switch Off");
        [self showHideAllDevicesView:NO];
        [_txtVwMessage resignFirstResponder];
        [self loadAllUsersFromParse];
    }
}

- (IBAction)switchToJsonFormat:(id)sender {
    CGRect lblWriteMessageFrame = _lblMessageToBeSent.frame;
    CGRect txtMessageFieldFrame = _txtVwMessage.frame;
    CGRect btnSendPushFrame = _btnSendPush.frame;
    CGRect switchJsonFrame = _switchJSON.frame;
    
    if(_switchJSON.isOn) {
        [_lblMessageToBeSent setHidden:YES];
        [_txtVwMessage setHidden:YES];
        
        btnSendPushFrame.origin.y = CGRectGetMaxY(switchJsonFrame) + 20;
        [_btnSendPush setFrame:btnSendPushFrame];
    }
    else {
        [_lblMessageToBeSent setHidden:NO];
        [_txtVwMessage setHidden:NO];
        
        lblWriteMessageFrame.origin.y = CGRectGetMaxY(switchJsonFrame) + 15;
        [_lblMessageToBeSent setFrame:lblWriteMessageFrame];
        txtMessageFieldFrame.origin.y = CGRectGetMaxY(lblWriteMessageFrame) + 10;
        [_txtVwMessage setFrame:txtMessageFieldFrame];
        btnSendPushFrame.origin.y = CGRectGetMaxY(txtMessageFieldFrame) + 25;
        [_btnSendPush setFrame:btnSendPushFrame];
    }
    
    _content = CGRectGetMaxY(btnSendPushFrame) + 10;
    NSLog(@"button: %@", NSStringFromCGRect(_btnSendPush.frame));
    NSLog(@"content: %f", _content);
    if(IS_IPHONE_4) {
        [_scroll setFrame:CGRectMake(0, 20, self.view.frame.size.width, 460)];
    }
    
    [_scroll setContentSize:CGSizeMake(self.view.frame.size.width, _content)];
    [_scroll setNeedsDisplay];
}

- (void)loadAllUsersFromParse {
    // Get all current users from Parse
    PFQuery *query = [PFQuery queryWithClassName:@"Users"];
    _currentUsers = [query findObjects];
    _indexSelected = -1;
    [_tblUsers setDelegate:self];
    [_tblUsers setDataSource:self];
    [_tblUsers reloadData];
}

- (void) showHideAllDevicesView:(BOOL)isAllDevicesShown {
    CGRect lblAllDevicesFrame = _lblToAllDevices.frame;
    CGRect tblUsersFrame = _tblUsers.frame;
    CGRect lblJsonFormatFrame = _lblJSONformat.frame;
    CGRect switchJsonFrame = _switchJSON.frame;
    
    if(isAllDevicesShown) {
        [_lblSelectUSer setHidden:YES];
        [_tblUsers setHidden:YES];
        
        lblJsonFormatFrame.origin.y = CGRectGetMaxY(lblAllDevicesFrame) + 20;
        [_lblJSONformat setFrame:lblJsonFormatFrame];
        switchJsonFrame.origin.y = CGRectGetMaxY(lblAllDevicesFrame) + 15;
        [_switchJSON setFrame:switchJsonFrame];
    }
    else {
        [_lblSelectUSer setHidden:NO];
        [_tblUsers setHidden:NO];
        
        lblJsonFormatFrame.origin.y = CGRectGetMaxY(tblUsersFrame) + 20;
        [_lblJSONformat setFrame:lblJsonFormatFrame];
        switchJsonFrame.origin.y = CGRectGetMaxY(tblUsersFrame) + 15;
        [_switchJSON setFrame:switchJsonFrame];
    }
    
    [self switchToJsonFormat:_switchJSON];
}


#pragma mark - Keyboard actions
- (void)showKeyBoard:(NSNotification *)notification {
    // Check if the current device is an iPhone 4 or not in order to move up the view with a certain value
    CGRect selfViewFrame = self.view.frame;
    if(IS_IPHONE_4) {
        if(_switchAll.isOn)
            selfViewFrame.origin.y = 0;
        else
            selfViewFrame.origin.y = -200;
    }
    else {
        if(!_switchAll.isOn)
            selfViewFrame.origin.y = - 150;
    }
    [UIView animateWithDuration:0.3 animations:^{
        [self.view setFrame:selfViewFrame];
    } completion:nil];
}

- (void)hideKeyBoard:(NSNotification *)notification {
    // Move the view to its default position
    [UIView animateWithDuration:0.3 animations:^{
        [self.view setFrame:CGRectMake(0, 0, CGRectGetWidth(self.view.frame), CGRectGetHeight(self.view.frame))];
    } completion:nil];
}

- (void)tapAnywhere:(UITapGestureRecognizer *)tap {
    [self.view endEditing:YES];
}

#pragma mark - table methods

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _currentUsers.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *identifier = @"Cell";
    PFObject *user = [_currentUsers objectAtIndex:indexPath.row];
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    if(cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
        cell.textLabel.text = [user objectForKey:@"name"];
    }
    else {
        cell.textLabel.text = [user objectForKey:@"name"];
    }
    
    if(indexPath.row == _indexSelected) {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    } else {
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    _indexSelected = indexPath.row;
    [_tblUsers reloadData];
    _currentUserSelected = [_currentUsers objectAtIndex:indexPath.row];
    NSLog(@"user: %@", [_currentUserSelected objectForKey:@"name"]);

}

@end
