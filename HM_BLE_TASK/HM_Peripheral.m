//
//  HM_Peripheral.m
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


#import "HM_Peripheral.h"

@implementation HM_Peripheral

@synthesize peripheral;
@synthesize RSSI;
@synthesize isConnected;

+ (HM_Peripheral*) initWithPeripheral:(CBPeripheral*)peripheral rssi:(int)RSSI isPeripheralConnected:(BOOL)isConnected
{
  HM_Peripheral* value = [HM_Peripheral alloc];
  value.peripheral = peripheral;
  value.RSSI = RSSI;
  value.isConnected = isConnected;
  return value;
}

-(NSString*) name
{
  NSString* name = [peripheral name];
  if (name == nil)
  {
    return @"NULL";
  }
  return name;
}

-(BOOL)isEqual:(id)object
{
  HM_Peripheral* other = (HM_Peripheral*) object;
  return peripheral == other.peripheral;
}

@end
