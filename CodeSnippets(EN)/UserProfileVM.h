#import <Foundation/Foundation.h>
// Network Operation
#import <RXNetworkOperation/RXNetworkOperation.h>
// Consts
#import "FoundationConsts.h"

NS_ASSUME_NONNULL_BEGIN

// ViewModel for UserProfileTVC Controller
@class WallPostCellVM;
@class UserProfileCellVM;
@class UserProfileGalleryCellVM;

/*--------------------------------------------------------------------------------------------------------------
 (🗃⚖️📱) 'UserProfileVM' - viewModel for controller 'UserProfileTVC'.
 --------------------------------------------------------------------------------------------------------------*/

@interface UserProfileVM : NSObject

// User Data
@property (nonatomic, strong) NSString* userID;
@property (nonatomic, weak, nullable) NSString* userFirstName;

// Data for UI
/*--------------------------------------------------------------------------------------------------------------
ViewModels of complex composite tables have the following separation in the storage of ViewModels of cells:
 One common array for all viewModels, and additional array/s for each of the cell viewModel classes.
 1) 'cellsViewModel'         - stores absolutely all the viewModels of the cells presented in the table.
 2) 'wallPostsCellViewModel' - stores only viewModels of the 'WallPostCellVM' class.
 --------------------------------------------------------------------------------------------------------------*/
@property (nonatomic, strong) NSMutableArray<id>* cellsViewModel;
@property (nonatomic, strong) NSMutableArray<WallPostCellVM*>* wallPostsCellViewModel;

// ViewModel reference for horizontal 'UICollectionView' with user photos
@property (nonatomic, strong, readonly) UserProfileGalleryCellVM* photoGalleryVM;


// Network operations
@property (nonatomic, strong) GO* loadAllNeededConentOp;

@property (nonatomic, strong) __block DTO* userInfoNetOp;
@property (nonatomic, strong) __block DTO* userPhotoNetOp;
@property (nonatomic, strong) __block DTO* userWallNetOp;
@property (nonatomic, strong)  DTO* logoutNetOp;

#pragma mark - Work with Network operations
/*--------------------------------------------------------------------------------------------------------------
 Get extended information about a user by 'self.userID' or by 'APIManager.token.userID'.
 Initializes the viewModel of the cell using the resulting model, and adds it to 'cellsViewModel'.
 --------------------------------------------------------------------------------------------------------------*/
- (DTO*) userInfoOpRunItself:(BOOL)runOpItself
                     onQueue:(nullable NSOperationQueue*)queue
                  completion:(nullable void(^)(NSError* _Nullable error, UserProfileCellVM* _Nullable cellVM))completion;


/*--------------------------------------------------------------------------------------------------------------
 Gets the collection of user photos by his 'self.userID' or by 'APIManager.token.userID'.
 Initializes the viewModel of the cell using the resulting model, and adds it to 'cellsViewModel'.
 --------------------------------------------------------------------------------------------------------------*/
- (DTO*) photosOpRunItself:(BOOL)runOpItself
                   onQueue:(nullable NSOperationQueue*)queue
                completion:(nullable void(^)(NSError* _Nullable error))completion;


/*--------------------------------------------------------------------------------------------------------------
 Retrieves entries from the user's wall by 'self.userID' or by 'APIManager.token.userID'.
 Initializes the viewModel of the cell using the resulting model, and adds it to 'cellsViewModel'.
 --------------------------------------------------------------------------------------------------------------*/
- (DTO*) wallOpRunItself:(BOOL)runOpItself
                 onQueue:(nullable NSOperationQueue*)queue
              completion:(nullable void(^)(NSError* _Nullable error,
                                           NSArray<WallPostCellVM*>* _Nullable viewModels,
                                           NSArray<NSIndexPath*>*    _Nullable indexPaths))completion;

/*--------------------------------------------------------------------------------------------------------------
Invokes a network operation that sends a logout request. Clear storage on device disk.
 --------------------------------------------------------------------------------------------------------------*/
- (DTO*) logoutOpRunItself:(BOOL)runOpItself
                   onQueue:(nullable NSOperationQueue*)queue
                completion:(nullable void(^)(void))completion;

/*--------------------------------------------------------------------------------------------------------------
 Performs three network operations in sequence (userInfoNetOp,userPhotoNetOp,userWallNetOp)
 --------------------------------------------------------------------------------------------------------------*/
- (GO*) performNeededOperations:(void(^)(NSError* _Nullable error))completion;


#pragma mark - Management of network operations
/*--------------------------------------------------------------------------------------------------------------
 Cancels all running network operations in the queue
 --------------------------------------------------------------------------------------------------------------*/
- (void) cancelAllNetworkOperations;


#pragma mark - Initialization

/*--------------------------------------------------------------------------------------------------------------
  Initializes the viewModel with 'userID'. (The data is obtained by the result of a network request in the future)
 --------------------------------------------------------------------------------------------------------------*/
+ (UserProfileVM*) initWithUserID:(nullable NSString*)userID;

@end

NS_ASSUME_NONNULL_END
