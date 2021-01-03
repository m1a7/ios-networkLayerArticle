//
//  UserProfileTVC.h
//  vk-networkLayer
//
//  Created by Admin on 06/08/2020.
//  Copyright © 2020 iOS-Team. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/*--------------------------------------------------------------------------------------------------------------
 (👱‍♂️📱) 'UserProfileTVC' - The controller displays the user's page.
 --------------------------------------------------------------------------------------------------------------*/

@interface UserProfileTVC : UITableViewController

#pragma mark - Initialization

/*--------------------------------------------------------------------------------------------------------------
 Initializes the controller with 'userID'. (ViewModel builds itself)
 --------------------------------------------------------------------------------------------------------------*/
+ (UserProfileTVC*) initWithUserID:(nullable NSString*)userID;

@end

NS_ASSUME_NONNULL_END
