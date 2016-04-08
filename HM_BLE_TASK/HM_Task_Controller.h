//
//  HM_Task_Controller.h
//  HM_BLE_TASK
//
//  Created by YongSuk Jin on 4/3/16.
//  Copyright (c) 2016 Yongsuk Jin ( https://github.com/JYSSoftware ).
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.
//

#import <UIKit/UIKit.h>
#import <CoreBluetooth/CoreBluetooth.h>


@interface HM_Task_Controller : UIViewController <CBCentralManagerDelegate, CBPeripheralDelegate, UITextFieldDelegate>

@property (weak, nonatomic) IBOutlet UIImageView *imgReadVal;

@property (weak, nonatomic) IBOutlet UIButton *btnConnect;
@property (weak, nonatomic) IBOutlet UILabel *lblStateMSG;

@property (weak, nonatomic) IBOutlet UILabel *lblColorState;
@property (weak, nonatomic) IBOutlet UILabel *lblReplyState;
@property (weak, nonatomic) IBOutlet UITextField *txtMSGSend;
@property (weak, nonatomic) IBOutlet UIButton *btnSendMSG;

@property (strong, atomic) CBCentralManager *central;
@property (strong, atomic) CBPeripheral *currentPeri;

@end
