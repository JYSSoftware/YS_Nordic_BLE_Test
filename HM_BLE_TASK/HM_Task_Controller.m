//
//  HM_Task_Controller.m
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

#import "HM_Task_Controller.h"
#import "HM_Peripheral.h"

#define kDefaultStateText @"STATE : %@"
#define kDefaultColorText @"COLOR : %@"
#define kDefaultReplyTest @"Reply : %@"
#define kDefaultServiceUUID @"001"

static NSString *UUID_WRITE = @"6E401525-B5A3-F393-E0A9-E50E24DCCA9E";

@interface HM_Task_Controller (){
  CGFloat window_width, window_height;
  NSString *value_hexForm;
  BOOL currentState;
  NSString *write_value;
}

@property (strong, nonatomic) NSMutableArray *peripheral_Container;
@property (strong, nonatomic) NSMutableArray *readableCharacteristics;
@property (strong, nonatomic) NSMutableArray *writableCharacteristics;
@property (strong, nonatomic) CBPeripheral * connectedPeripheral;
//@property (strong, nonatomic) CBPeripheralManager *peripheralManager;

@property (strong, nonatomic) CBCharacteristic *writeCharacteristic;

@end

@implementation HM_Task_Controller

@synthesize lblColorState = _lblColorState, lblReplyState = _lblReplyState, lblStateMSG = _lblStateMSG;
@synthesize txtMSGSend = _txtMSGSend;
@synthesize imgReadVal = _imgReadVal;
@synthesize btnConnect, btnSendMSG;
@synthesize central = _central, currentPeri = _currentPeri;
@synthesize connectedPeripheral = _connectedPeripheral;

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
  
  [self generalInit];
  
  
  
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (void) generalInit{
  
  //not write yet
  currentState = NO;
  
  
  [self changeState:false];
  
  [btnConnect addTarget:self action:@selector(connect:) forControlEvents:UIControlEventAllTouchEvents];
  [btnSendMSG addTarget:self action:@selector(send:) forControlEvents:UIControlEventAllTouchEvents];
  
  //align labels at center line
  window_height = [self.view bounds].size.height;
  window_width = [self.view bounds].size.width;
  
  [_lblReplyState setPreferredMaxLayoutWidth:200];
  [_lblColorState setPreferredMaxLayoutWidth:200];
  [_lblStateMSG setPreferredMaxLayoutWidth:200];
  [self reloadLabelViews];
  
  
  
  
  //init BLEs
  _central = [[CBCentralManager alloc] initWithDelegate:self queue:nil options:nil];
  _peripheral_Container = [[NSMutableArray alloc] init];
  _writableCharacteristics = [[NSMutableArray alloc] init];
  _readableCharacteristics = [[NSMutableArray alloc] init];
  
}

- (IBAction)connect:(id)sender{
  [_central scanForPeripheralsWithServices:nil options:nil];
}


//found peripheral
- (void) centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary<NSString *,id> *)advertisementData RSSI:(NSNumber *)RSSI{

  
  if ([[advertisementData objectForKey: CBAdvertisementDataIsConnectable] boolValue])
  {
    dispatch_queue_t concurrentQueue;
    concurrentQueue = dispatch_queue_create("com.hmbletask.gcd", DISPATCH_QUEUE_CONCURRENT);
    
    
    dispatch_async(concurrentQueue, ^{
      HM_Peripheral *foundPeri = [HM_Peripheral initWithPeripheral:peripheral rssi:RSSI.intValue isPeripheralConnected:NO];
      
      if (![_peripheral_Container containsObject:foundPeri]) {
        [_peripheral_Container addObject:foundPeri];
      }
      
      foundPeri = [_peripheral_Container objectAtIndex:[_peripheral_Container indexOfObject:foundPeri]];
      foundPeri.RSSI = RSSI.intValue;
      
    });
  }
  if ([_peripheral_Container count] != 0) {
    NSLog(@"No available Devices");
    [self changeState:NO];
  }
  else{
    //currently just connect the first device (but add later -- after recognize which uuid shoud use)
    [_central connectPeripheral:peripheral options:nil];
    
  }
  [_central stopScan];
  
}


//did connect to a peripheral
- (void) centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral{
  
  NSLog(@"Connected %@", peripheral.name);
  
  //connected change state text
  [self changeState:YES];
  
  _connectedPeripheral = peripheral;
  _connectedPeripheral.delegate = self;
  
  
  peripheral.delegate = self;
  
  if (peripheral.services) {
    [self peripheral:peripheral didDiscoverServices:nil];
  }
  else{
    
    [peripheral discoverServices:nil];
  }
}

- (void) centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error{
  
  NSLog(@"fail to connect %@", [error localizedDescription]);
}

- (void) centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error{
  NSLog(@"Connection Disconnected");
  
  
  UIAlertAction *reconnectAlert = [UIAlertAction actionWithTitle:@"Reconnect?" style:UIAlertActionStyleDefault
                                                         handler:^(UIAlertAction * action){
                                                                   [central connectPeripheral:peripheral options:nil];
                                                         }];
  UIAlertAction *actionCancel = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil];
  [self alertController:@"Alert" withMessge:@"Connection has disconnected" withActionArray:[NSMutableArray arrayWithObjects:reconnectAlert, actionCancel, nil]];
}

//after found device and connected (look for advertised services)
- (void) peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error{
  

  
  //if any error comes
  if (error) {
    NSLog(@"%@", [error localizedDescription]);
    return;
  }
  
  dispatch_queue_t concurrentQueue;
  concurrentQueue = dispatch_queue_create("com.hmbletask.gcd", DISPATCH_QUEUE_CONCURRENT);
  
  
  //else look for services
  dispatch_async(concurrentQueue, ^{
    for (CBService* svc in peripheral.services) {
      
      NSLog(@"Discovered Service : %@", svc.UUID);
      
      [peripheral discoverCharacteristics:nil forService:svc];
    }
  });

}

//when Characteristics are found
- (void) peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error{
  

  
  if (error) {
    NSLog(@"%@", [error localizedDescription]);
    return;
  }
  
  //traverse all the characteristics in a service
  for (CBCharacteristic *chr in service.characteristics) {
    
    NSLog(@"Characteristic UUID %@ ", chr.UUID.UUIDString);
    
    //check if characteristic is notifying or (not) writable
    if (![chr.UUID.UUIDString isEqualToString:UUID_WRITE]) {
      
      //subscribe the data modification on
      [_connectedPeripheral setNotifyValue:YES forCharacteristic:chr];
      [_readableCharacteristics addObject:chr];
    }
    
    //read
    else{
      
      NSLog(@"Write");
      // this time only one writable characteristic
      _writeCharacteristic = chr;
      [_writableCharacteristics addObject:_writeCharacteristic];
    }
    
  }
  
}

- (void) peripheral:(CBPeripheral *)peripheral didWriteValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error{
  
  NSLog(@"Succeded writing Value");
  
}

- (void) peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error{
  
  NSLog(@"Characteristic value : %@ with UUID %@", characteristic.value, characteristic.UUID);
  [self getColorData:characteristic Char:error];
}


- (void) centralManagerDidUpdateState:(CBCentralManager *)central{
  // Determine the state of the peripheral
  if ([central state] == CBCentralManagerStatePoweredOff) {
    NSLog(@"CoreBluetooth BLE hardware is powered off");
  }
  else if ([central state] == CBCentralManagerStatePoweredOn) {
    NSLog(@"CoreBluetooth BLE hardware is powered on and ready");
  }
  else if ([central state] == CBCentralManagerStateUnauthorized) {
    NSLog(@"CoreBluetooth BLE state is unauthorized");
  }
  else if ([central state] == CBCentralManagerStateUnknown) {
    NSLog(@"CoreBluetooth BLE state is unknown");
  }
  else if ([central state] == CBCentralManagerStateUnsupported) {
    NSLog(@"CoreBluetooth BLE hardware is unsupported on this platform");
  }
}

- (IBAction)send:(id)sender{
  
  //if send is trigered then parse string to data
  //and send data to device
  
  if ([_txtMSGSend.text isEqual:@""]
      || [_txtMSGSend.text isEqual:nil]) {
    
    UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"Done" style:UIAlertActionStyleCancel handler:nil];
    [self alertController:@"Warning" withMessge:@"Please type data" withActionArray:[NSMutableArray arrayWithObject:cancel]];
  }
  else{
  
    write_value = _txtMSGSend.text;
    currentState = YES;
    //parse string to NSData
    NSData *val = [write_value dataUsingEncoding:NSUTF8StringEncoding];
    
    NSLog(@"%s", val.bytes);
    NSLog( @"current peri = %@ " , _connectedPeripheral.description);
    NSLog( @"_writeCharacteristic = %@ ", _writeCharacteristic.description );
    
    
    //write without response
    if (_connectedPeripheral && _writeCharacteristic) {
      [_connectedPeripheral writeValue:val forCharacteristic:_writeCharacteristic type:CBCharacteristicWriteWithoutResponse];
    }
    else{
      NSLog(@"Something is wrong in currentPeripheral and writable Characteristics");
    }
  }
}

- (void) getColorData : (CBCharacteristic *) characteristic Char : (NSError *) error{
  if (error) {
    NSLog(@"%@", [error localizedDescription]);
    return;
  }
  
  NSLog(@"data : %@", characteristic.value);
  
  //value_hexForm = [self hexadecimalString:characteristic.value];
  
  //pull out string from the data
  value_hexForm = [[NSString alloc] initWithData:characteristic.value encoding:NSUTF8StringEncoding];
  
  [_lblColorState setText: [NSString stringWithFormat:kDefaultColorText, value_hexForm]];
  
  @try {
    [_imgReadVal setBackgroundColor:[self colorWithHexString:value_hexForm]];
  }
  @catch (NSError *e || NSException *exception) {
    NSLog(@"Error from string to UIColor");
    UIAlertAction *errorAction = [UIAlertAction actionWithTitle:@"Ok" style:UIAlertActionStyleDefault handler:nil];
    [self alertController:@"Error"
               withMessge:@"Error from string->color"
          withActionArray:[NSMutableArray arrayWithObject:errorAction]];
  }
  
}

#pragma mark own Helper mthods

//show alert controller (with customized actions)
- (UIAlertController *) alertController : (NSString *) title withMessge: (NSString *) msg withActionArray: (NSMutableArray *) actions {
  
  UIAlertController *alert = [UIAlertController alertControllerWithTitle:title message:msg preferredStyle:UIAlertControllerStyleActionSheet];
  
  for (UIAlertAction *act in actions) {
    [alert addAction:act];
  }
  
  [self presentViewController:alert animated:YES completion:nil];
  return alert;
}

//Dismiss keyboards
- (BOOL) textFieldShouldReturn:(UITextField *)textField{
  [textField resignFirstResponder];
  return NO;
}

- (void) changeState : (BOOL) state{
  
  if (state) {
    [_lblStateMSG setText:[NSString stringWithFormat:kDefaultStateText, @"CONNECTED"]];
  }
  else{
    [_lblStateMSG setText:[NSString stringWithFormat:kDefaultStateText, @"DISCONNECTED"]];
  }
  
  [self reloadLabelViews];
}

- (void) reloadLabelViews{
 
  [_lblColorState sizeToFit];
  [_lblStateMSG sizeToFit];
  [_lblReplyState sizeToFit];
  [_lblColorState setCenter:CGPointMake( window_width * 0.5, _lblColorState.frame.origin.y)];
  [_lblStateMSG setCenter:CGPointMake( window_width * 0.5, _lblStateMSG.frame.origin.y)];
  [_lblReplyState setCenter:CGPointMake( window_width * 0.5, _lblReplyState.frame.origin.y)];
  
  [self reloadInputViews];
}

#pragma mark Helper methods below



- (NSString *)hexadecimalString : (NSData *)value
{
  /* Returns hexadecimal string of NSData. Empty string if data is empty.   */
  
  const unsigned char *dataBuffer = (const unsigned char *)[value bytes];
  
  if (!dataBuffer)
  {
    return [NSString string];
  }
  
  NSUInteger          dataLength  = [value length];
  NSMutableString     *hexString  = [NSMutableString stringWithCapacity:(dataLength * 2)];
  
  for (int i = 0; i < dataLength; ++i)
  {
    [hexString appendFormat:@"%02x", (unsigned int)dataBuffer[i]];
  }
  
  return [NSString stringWithString:hexString];
}

-(UIColor*)colorWithHexString:(NSString*)hex
{
  NSString *cString = [[hex stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] uppercaseString];
  
  // String should be 6 or 8 characters
  if ([cString length] < 6) return [UIColor grayColor];
  
  // strip 0X if it appears
  if ([cString hasPrefix:@"0X"]) cString = [cString substringFromIndex:2];
  
  if ([cString length] != 6) return  [UIColor grayColor];
  
  // Separate into r, g, b substrings
  NSRange range;
  range.location = 0;
  range.length = 2;
  NSString *rString = [cString substringWithRange:range];
  
  range.location = 2;
  NSString *gString = [cString substringWithRange:range];
  
  range.location = 4;
  NSString *bString = [cString substringWithRange:range];
  
  // Scan values
  unsigned int r, g, b;
  [[NSScanner scannerWithString:rString] scanHexInt:&r];
  [[NSScanner scannerWithString:gString] scanHexInt:&g];
  [[NSScanner scannerWithString:bString] scanHexInt:&b];
  
  return [UIColor colorWithRed:((float) r / 255.0f)
                         green:((float) g / 255.0f)
                          blue:((float) b / 255.0f)
                         alpha:1.0f];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
