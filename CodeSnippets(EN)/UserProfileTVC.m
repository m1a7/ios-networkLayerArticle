//
//  UserProfileTVC.h
//  vk-networkLayer
//
//  Created by Admin on 06/08/2020.
//  Copyright © 2020 iOS-Team. All rights reserved.
//

#import "UserProfileTVC.h"
// ViewModel
#import "UserProfileVM.h"

// Cell
#import "UserProfileCell.h"
#import "UserProfileGalleryCell.h"
#import "WallPostCell.h"

// Cell's ViewModels
#import "UserProfileCellVM.h"
#import "UserProfileGalleryCellVM.h"
#import "WallPostCellVM.h"

// APIManager
#import "APIManager.h"

// Router
#import "Router.h"

// Views
#import "FooterView.h"

// Foundation
#import "MultiThreads.h"

// Third-party frameworks
#import "TWWatchdogInspector.h"
#import <RXImageGallerySDK/RXImageGallerySDK.h>

// Categories
#import "UIView+AdditionalProperties.h"
#import "NSObject+AdditionalProperties.h"

#import "UIKitHelper.h"
#import "UIImage+AdditionalProperties.h"

@interface UserProfileTVC ()

// User data
@property (nonatomic, strong) NSString* userID;
@property (nonatomic, strong) UserProfileVM* viewModel;

// UI
@property (nonatomic, strong) FooterView* footerView;

// Helper property to restrict multiple method calls
@property (nonatomic, assign) BOOL isLoadingData;

@end

@implementation UserProfileTVC

#pragma mark - Life cycle
/*--------------------------------------------------------------------------------------------------------------
  Inside the 'viewDidLoad' call the 'performNeededOperations' method of the viewModel, which will receive data from the Internet.
 --------------------------------------------------------------------------------------------------------------*/
- (void)viewDidLoad
{
    printMethod;
    [super viewDidLoad];
    
    __weak UserProfileTVC* weak = self;
    CGSize tableSize = weak.tableView.frame.size;
    
    [self.viewModel performNeededOperations:^(NSError * _Nullable error) {
       
        if (error){
            [Router presentAlertVCwithTitle:error.domain message:nil userInfo:error.userInfo delay:1.3f];
            return;
        }
        // Calculate coordinates for subviews cells
        for (id viewModelCell in weak.viewModel.cellsViewModel) {
            
            NSString* cellIdentifier = [UserProfileTVC getClassNameByViewModelCell:viewModelCell];
            if ([NSClassFromString(cellIdentifier) respondsToSelector:@selector(calculateCoordinatesForVM:tableSize:)]){
                [NSClassFromString(cellIdentifier) calculateCoordinatesForVM:viewModelCell tableSize:tableSize];
            }
        }
        // Reloading the table
        MainQueue(^{
            weak.title = weak.viewModel.userFirstName;
            [weak.tableView reloadData];
        });
    }];
}


/*--------------------------------------------------------------------------------------------------------------
 Inside the method, an internal method is called that configures all UI elements
 --------------------------------------------------------------------------------------------------------------*/
- (void)viewDidAppear:(BOOL)animated
{
    printMethod;
    [super viewDidAppear:animated];
    [TWWatchdogInspector start];
    [self setupViews];
}

/*--------------------------------------------------------------------------------------------------------------
 Deallocates the memory occupied by the receiver.
 --------------------------------------------------------------------------------------------------------------*/
- (void) dealloc
{
    printMethod;
    [self.viewModel cancelAllNetworkOperations];
}

#pragma mark - UITableViewDataSource

/*--------------------------------------------------------------------------------------------------------------
 Asks the data source to return the number of sections in the table view.
 --------------------------------------------------------------------------------------------------------------*/
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return [self.viewModel.cellsViewModel count];
}

/*--------------------------------------------------------------------------------------------------------------
 Tells the data source to return the number of rows in a given section of a table view.
 --------------------------------------------------------------------------------------------------------------*/
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 1;
}

/*--------------------------------------------------------------------------------------------------------------
 Asks the data source for a cell to insert in a particular location of the table view.
 --------------------------------------------------------------------------------------------------------------*/
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell* cell = nil;
    id vm = self.viewModel.cellsViewModel[indexPath.section];
    
    // Get the cell class names by the type of the viewModel class
    NSString* identifier = [UserProfileTVC getClassNameByViewModelCell:vm];

    cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    if (!cell){
         cell = [[NSClassFromString(identifier) alloc] initWithStyle:UITableViewCellStyleDefault
                                                     reuseIdentifier:identifier];
    }
    // Insert viewModel for further cell configuration
    if ([(id)cell respondsToSelector:@selector(setViewModel:)]){
        [(id)cell setViewModel:vm];
    }
    return cell;
}

#pragma mark - UITableViewDelegate
/*--------------------------------------------------------------------------------------------------------------
 Asks the delegate for the height to use for a row in a specified location.
 --------------------------------------------------------------------------------------------------------------*/
- (CGFloat)tableView:(UITableView*)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    CGFloat height = 40.f;
    // Get viewmodel from our datasource array
    id vm = self.viewModel.cellsViewModel[indexPath.section];
    Class cellClass = NSClassFromString([UserProfileTVC getClassNameByViewModelCell:vm]);

    //We call the method for calculating the height of the cell from the data located in the viewModel
    if ([cellClass respondsToSelector:@selector(calculateCellHeightFromVM:tableSize:)]){
        height = [cellClass calculateCellHeightFromVM:vm tableSize:tableView.frame.size];
    }
    return roundf(height);
}

/*--------------------------------------------------------------------------------------------------------------
 Tells the delegate that the specified row is now selected.
 --------------------------------------------------------------------------------------------------------------*/
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}


/*--------------------------------------------------------------------------------------------------------------
 Asks the delegate for the height to use for the header of a particular section.
 --------------------------------------------------------------------------------------------------------------*/
- (CGFloat)tableView:(UITableView*)tableView heightForHeaderInSection:(NSInteger)section {
   
    if (section < 2){
        return CGFLOAT_MIN;
    }
    return 15.f;
}

/*--------------------------------------------------------------------------------------------------------------
 Asks the delegate for the height to use for the footer of a particular section.
 --------------------------------------------------------------------------------------------------------------*/
- (CGFloat)tableView:(UITableView*)tableView heightForFooterInSection:(NSInteger)section {
    return CGFLOAT_MIN;
}

#pragma mark - Actions

- (void) logoutAction:(UIBarButtonItem*)button
{
    printMethod;
    [self.viewModel logoutOpRunItself:NO onQueue:APIManager.aSyncQueue completion:^{
        [Router showStarterVC:SetRootViewController_ShowType];
    }];
}


#pragma mark - UI Setuping
/*--------------------------------------------------------------------------------------------------------------
 Creates, customizes, adds UI elements before using the controller
 --------------------------------------------------------------------------------------------------------------*/
- (void) setupViews
{
    //==================================== Registers cell's class ========================================//
    
    [self.tableView registerClass:[UserProfileCell class] forCellReuseIdentifier:@"UserProfileCell"];
    [self.tableView registerClass:[WallPostCell class]    forCellReuseIdentifier:@"WallPostCell"];
    
    //==================================== Setup UITableView ========================================//

    self.tableView.estimatedRowHeight           = 0;
    self.tableView.estimatedSectionHeaderHeight = 0;
    self.tableView.estimatedSectionFooterHeight = 0;
    
    self.tableView.backgroundColor = [UIColor colorWithRed:0.949 green:0.937 blue:0.965 alpha:1.000];
    self.tableView.sectionHeaderHeight = 40;
    self.tableView.sectionFooterHeight = 40;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    //self.tableView.allowsSelection = NO;
    
    self.footerView = [[FooterView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.tableView.frame), 40)];
    self.tableView.tableFooterView = self.footerView;
    
    //==================================== NavigationController ========================================//

    self.navigationController.hidesBarsOnSwipe = YES;
    
    self.navigationController.navigationBar.tintColor = [UIColor whiteColor];
    self.navigationController.navigationBar.barTintColor = [UIColor colorWithRed:0.286 green:0.494 blue:0.741 alpha:1.000];

    float titleFontSize = (IS_IPHONE) ? 20.f : 25.f;
    self.navigationController.navigationBar.titleTextAttributes =  @{
                                                                      NSForegroundColorAttributeName : [UIColor whiteColor],
                                                                      NSFontAttributeName :  [UIFont fontWithName:@"SFProText-Medium" size:titleFontSize]
                                                                    };
    //==================================== NavigationBar ========================================//

    UIImage *imageLogout = [[UIImage imageNamed:@"iconLogout"]  tintColor:[UIColor whiteColor] backgroundColor:nil];
    UIButton *logoutButton = [UIButton buttonWithType:UIButtonTypeCustom];
    logoutButton.bounds = CGRectMake(0, 0, imageLogout.size.width, imageLogout.size.height);
    [logoutButton setImage:imageLogout forState:UIControlStateNormal];
    [logoutButton addTarget:self action:@selector(logoutAction:) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *logoutBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:logoutButton];
    self.navigationItem.rightBarButtonItem = logoutBarButtonItem;
}

#pragma mark - Helpers TableView Methods

/*--------------------------------------------------------------------------------------------------------------
 This is helpers method, which make work with -cellForRowAtIndexPath easy !
 Method return Class of viewmodel's objects.
 After in -cellForRowAtIndexPath init cell by returned class from this method
 --------------------------------------------------------------------------------------------------------------*/
+ (NSString*) getClassNameByViewModelCell:(id)viewModel
{
    NSString* identifier;
    if ([viewModel isKindOfClass:[UserProfileCellVM class]])
        identifier = NSStringFromClass([UserProfileCell class]);
   
    if ([viewModel isKindOfClass:[UserProfileGalleryCellVM class]])
        identifier = NSStringFromClass([UserProfileGalleryCell class]);
    
    if ([viewModel isKindOfClass:[WallPostCellVM class]])
        identifier = NSStringFromClass([WallPostCell class]);

    if (!identifier)
         identifier = NSStringFromClass([viewModel class]);
    return identifier;
}


#pragma mark - ScrollView

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/*
      _______.  ______ .______        ______    __       __      ____    ____  __   ___________    __    ____
     /       | /      ||   _  \      /  __  \  |  |     |  |     \   \  /   / |  | |   ____\   \  /  \  /   /
    |   (----`|  ,----'|  |_)  |    |  |  |  | |  |     |  |      \   \/   /  |  | |  |__   \   \/    \/   /
     \   \    |  |     |      /     |  |  |  | |  |     |  |       \      /   |  | |   __|   \            /
 .----)   |   |  `----.|  |\  \----.|  `--'  | |  `----.|  `----.   \    /    |  | |  |____   \    /\    /
 |_______/     \______|| _| `._____| \______/  |_______||_______|    \__/     |__| |_______|   \__/  \__/
 */
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

#pragma mark - <UIScrollViewDelegate>

/*--------------------------------------------------------------------------------------------------------------
 The method handles changes in the scrollBar position.
 In this controller, when the bottom border of the screen is reached, a check is performed and the data loading method is called.
 --------------------------------------------------------------------------------------------------------------*/
-(void)scrollViewDidScroll:(UIScrollView*)scrollView
{
    float contentOffsetY    = scrollView.contentOffset.y;
    float contentSizeHeight = scrollView.contentSize.height;
    float tableViewHeight   = CGRectGetHeight(self.tableView.frame);
    
    if ((contentSizeHeight > 0)  && ((contentSizeHeight - contentOffsetY) <= (tableViewHeight+(tableViewHeight/10))) && (!self.isLoadingData))
    {
        // Set the flag to avoid re-entering the if-block.
        self.isLoadingData = YES;

        // We get the size of the table so that later we can use the value in the background thread
        CGSize tableSize = self.tableView.frame.size;
        
        // Start the animation process
        [self.footerView.footerLoader startAnimating];

        // Calling the viewModel method to get data
        __weak UserProfileTVC* weak = self;
        [self.viewModel wallOpRunItself:NO onQueue:APIManager.aSyncQueue completion:^(NSError* error,
                                                                                      NSArray<WallPostCellVM*>* viewModels,
                                                                                      NSArray<NSIndexPath*>*    indexPaths){
            // handle the variant of the error
            if ((error) || (!indexPaths) || (indexPaths.count < 1)) {
                MainQueue(^{
                    [weak.footerView.footerLoader stopAnimating];
                });
                weak.isLoadingData = NO;
                return;
            }
            //Thus, we calculate and copy all the values for the content inside the cell - here on the background thread.
            for (WallPostCellVM* cellVM in viewModels) {
                [WallPostCell calculateCoordinatesForVM:cellVM tableSize:tableSize];
            }

            MainQueue(^{
                [weak.tableView reloadData];
                // Change flag values
                weak.isLoadingData = NO;
                // Stopping the animation
                [weak.footerView.footerLoader stopAnimating];
            });
        }];
    }
}
#pragma mark - Initialization

/*--------------------------------------------------------------------------------------------------------------
 Initializes the controller with 'userID'. (ViewModel builds itself)
 --------------------------------------------------------------------------------------------------------------*/
+ (UserProfileTVC*) initWithUserID:(nullable NSString*)userID
{
    UserProfileTVC* vc = [[UserProfileTVC alloc] initWithStyle:UITableViewStyleGrouped];
    if (vc) {
        vc.userID    = userID;
        vc.viewModel = [UserProfileVM initWithUserID:userID];
    }
    return vc;
}

@end
