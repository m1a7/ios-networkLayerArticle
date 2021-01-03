#import "UserProfileVM.h"
// APIManager
#import "APIManager.h"
#import "Token.h"

// Other ViewModels
#import "UserProfileCellVM.h"
#import "UserProfileGalleryCellVM.h"
#import "WallPostCellVM.h"

// Models
#import "UserProfile.h"

// Foundation
#import "NSDate+Expire.h"
#import "NSObject+AdditionalProperties.h"


/*--------------------------------------------------------------------------------------------------------------
 (🗃⚖️📱) 'UserProfileVM' - viewModel for controller 'UserProfileTVC'.
 --------------------------------------------------------------------------------------------------------------*/

@interface UserProfileVM ()
// Link to the viewModel of the cell that has a horizontal collectionView with the user's photo
@property (nonatomic, strong, readwrite) UserProfileGalleryCellVM* photoGalleryVM;
// Models
@property (nonatomic, strong) UserProfile* userProfileModel;
@end



@implementation UserProfileVM

#pragma mark - NetworkOperations

/*--------------------------------------------------------------------------------------------------------------
 Get extended information about a user by 'self.userID' or by 'APIManager.token.userID'.
 Initializes the viewModel of the cell using the resulting model, and adds it to 'cellsViewModel'.
--------------------------------------------------------------------------------------------------------------*/
- (DTO*) userInfoOpRunItself:(BOOL)runOpItself
                     onQueue:(nullable NSOperationQueue*)queue
                  completion:(nullable void(^)(NSError* _Nullable error, UserProfileCellVM* _Nullable cellVM))completion
{
    printMethod;
    if (![self.userInfoNetOp isWorkingOrInProcess])
    {
        __weak UserProfileVM* weak = self;      
        NSArray<NSString*>* userIDs = (self.userID) ? @[self.userID] : @[];
        
        // Network operation initialization
        self.userInfoNetOp =
        [APIManager usersGet:userIDs
                      fields:nil
                  completion:^(NSArray<UserProfile*>* _Nullable userProfiles, BO* _Nonnull op) {
                    
                      // Update property refrence on fresh operation
                      weak.userInfoNetOp = (DTO*)op;
                     
                      // Handle error
                      if ([APIManager callCompletionWithTwoArg:completion ifOccuredErrorInOperation:op]){
                          return;
                      }
                      
                      // Prepare data for completion block.
                      UserProfileCellVM* cellViewModel = nil;
                      if (userProfiles.count > 0){
                          cellViewModel = [UserProfileCellVM initWithModel:[userProfiles firstObject]];
                          weak.userProfileModel = [userProfiles firstObject];
                      }
                      if (cellViewModel){
                          [weak.cellsViewModel addObject:cellViewModel];
                      }
                      
                      
                      // Call completion
                      if (completion) completion(nil,cellViewModel);
                      
        }];
        //Set value in order to if you exit from current screen, the operation will be canceled
        self.userInfoNetOp.owner = self.addressInMemory;

        // Decides whether to start the process of performing the operation at the moment or not.
        if (runOpItself){
            [self.userInfoNetOp start];
        }else if ((!runOpItself) && (queue)){
            [queue addOperation:self.userInfoNetOp];
        }
    }
    return self.userInfoNetOp;
}


/*--------------------------------------------------------------------------------------------------------------
 Gets the collection of user photos by his 'self.userID' or by 'APIManager.token.userID'.
 Initializes the viewModel of the cell using the resulting model, and adds it to 'cellsViewModel'.
 -------
 (⚠️) There is a special circumstance in this method:
 This viewModel ('UserProfileVM') contains another viewModel ('UserProfileGalleryCellVM'), which serves
 horizontal 'UICollectionView' with user photos.
 In fact, it turns out that the property for the network operation contains the child ViewModel.
 So if we urgently need to cancel the operation, we need to contact through the child ViewModel.
 --------------------------------------------------------------------------------------------------------------*/
- (DTO*) photosOpRunItself:(BOOL)runOpItself
                   onQueue:(nullable NSOperationQueue*)queue
                completion:(nullable void(^)(NSError* _Nullable error))completion
{   printMethod;
    // If the operation is currently being performed, then return the property to it.
    if ([self.userPhotoNetOp isWorkingOrInProcess]){
        return self.userPhotoNetOp;
    }
    else if (([self.userPhotoNetOp isFinishedOrCancelled]) || (!self.userPhotoNetOp)){
            
        __weak UserProfileVM* weak = self;

        // Create a child viewModel, which has implemented network-part in itself
        UserProfileGalleryCellVM* photoGalleryCellViewModel = [UserProfileGalleryCellVM initWithUserID:self.userID offset:0 count:20];
        
        // Network operation initialization
        self.userPhotoNetOp =
        [photoGalleryCellViewModel photosOpRunItself:runOpItself onQueue:queue completion:^(NSError* error, NSArray<UserProfilePhotoCellVM*>* cellsVM, NSArray<NSIndexPath*>* indexPaths) {
            if (error){
                if (completion) completion(error);
                return;
            }
            // Add cell's viewModel to array
            [weak.cellsViewModel addObject:photoGalleryCellViewModel];
            if (completion) completion(error);
        }];
        //Set value in order to if you exit from current screen, the operation will be canceled
        self.userPhotoNetOp.owner = self.addressInMemory;
    }
    return self.userPhotoNetOp;
}


/*--------------------------------------------------------------------------------------------------------------
 Retrieves entries from the user's wall by 'self.userID' or by 'APIManager.token.userID'.
 Initializes the viewModel of the cell using the resulting model, and adds it to 'cellsViewModel'.
--------------------------------------------------------------------------------------------------------------*/
- (DTO*) wallOpRunItself:(BOOL)runOpItself
                 onQueue:(nullable NSOperationQueue*)queue
              completion:(nullable void(^)(NSError* _Nullable error,
                                           NSArray<WallPostCellVM*>* _Nullable viewModels,
                                           NSArray<NSIndexPath*>*    _Nullable indexPaths))completion
{   printMethod;
    // If the operation is currently being performed, then return the property to it.
    if ([self.userWallNetOp isWorkingOrInProcess]){
        return self.userWallNetOp;
    } else
    if (([self.userWallNetOp isFinishedOrCancelled]) || (!self.userWallNetOp)){
        
        __weak UserProfileVM* weak = self;
        
        // Network operation initialization
        self.userWallNetOp =
        [APIManager wallGet:self.userID
                     offset:(self.wallPostsCellViewModel.count > 1) ? self.wallPostsCellViewModel.count : 0
                      count:20
                     filter:nil
                 completion:^(NSArray<WallPost*>* wallPosts, BO* op) {
            
                     // Update property refrence on fresh operation
                     weak.userWallNetOp = (DTO*)op;
                   
                     // Handle error
                     if ([APIManager callCompletionWithThreeArg:completion ifOccuredErrorInOperation:op]){
                         return;
                     }
                    
                     // Prepare data for completion block
                     // 1. create VM for cels
                     // 2. Insert vm to self.cellViewModels
                     // 3. Call completion -> [reloadData]
                     
                    NSMutableArray<NSIndexPath*>*    _Nullable indexPaths = @[].mutableCopy;
                    NSMutableArray<WallPostCellVM*>* _Nullable viewModels = @[].mutableCopy;

                    for (WallPost* wallPost in wallPosts) {
                          WallPostCellVM* cellViewModel = [WallPostCellVM initWithModel:wallPost];
                          [weak.cellsViewModel         addObject:cellViewModel]; // This is a common array for all cells
                          [weak.wallPostsCellViewModel addObject:cellViewModel]; // ViewModels are stored here only for WallPostCell
                                                                                 // This is done for convenience, so that offset is not calculated.
                          [viewModels addObject:cellViewModel];
                          [indexPaths addObject:[NSIndexPath indexPathForRow:1
                                                                    inSection:[weak.cellsViewModel indexOfObject:cellViewModel]]];
                     }
                     op.result = wallPosts;
                     
                     // Call completion
                     if (completion) completion(nil, viewModels,indexPaths);
       }];
        //Set value in order to if you exit from current screen, the operation will be canceled
        self.userWallNetOp.owner = self.addressInMemory;
        
        // Decides whether to start the process of performing the operation at the moment or not.
        if ((runOpItself) && (self.userWallNetOp.state == RXNO_ReadyToStart)){
            [self.userWallNetOp start];
        }else if ((!runOpItself) && (queue) && (self.userWallNetOp.state == RXNO_ReadyToStart)){
            [queue addOperation:self.userWallNetOp];
        }
    }
    return self.userWallNetOp;
}

/*--------------------------------------------------------------------------------------------------------------
 Invokes a network operation that sends a logout request. Clear storage on device disk.
 --------------------------------------------------------------------------------------------------------------*/
- (DTO*) logoutOpRunItself:(BOOL)runOpItself
                   onQueue:(nullable NSOperationQueue*)queue
                completion:(nullable void(^)(void))completion
{
    self.logoutNetOp = [APIManager logout:^{
                          if (completion) completion();
                       }];
    // Decides whether to start the process of performing the operation at the moment or not.
    if ((runOpItself) && (self.logoutNetOp.state == RXNO_ReadyToStart)){
        [self.logoutNetOp start];
    }else if ((!runOpItself) && (queue) && (self.logoutNetOp.state == RXNO_ReadyToStart)){
        [queue addOperation:self.logoutNetOp];
    }
    return self.logoutNetOp;
}


/*--------------------------------------------------------------------------------------------------------------
 Performs three network operations in sequence (userInfoNetOp,userPhotoNetOp,userWallNetOp).
 Initiates the process of performing operations not directly through the property, but through the wrapper method,
 which take over obligations to independently transform and save data received from 'APIManager'.
 --------------------------------------------------------------------------------------------------------------*/
- (GO*) performNeededOperations:(void(^)(NSError* _Nullable error))completion
{
    printMethod;
    __weak UserProfileVM* weak = self;
    // Group operation initialization
    self.loadAllNeededConentOp = [GO groupOperation:^(GO * _Nonnull groupOp){
        
        // (!) If we do not access network operations through 'weak', but simply create them here
        //     Then they are removed from memory faster than when we access the property from the block.
        
        // UserInfoOp
        [weak userInfoOpRunItself:NO onQueue:nil completion:nil];
        // Supports cancellation of network operation if group operation was canceled
        weak.userInfoNetOp.downloadProgress = ^(DTO * _Nonnull op, DTODownProgress p) {
            if (groupOp.state == RXNO_Cancelled) { [op cancel]; }
        };
        [weak.userInfoNetOp syncStart];
        
        if (groupOp.state == RXNO_Cancelled) return;
        if ([APIManager callCompletion:completion ifOccuredErrorInOperation:weak.userInfoNetOp]){
            return;
        }
        
        // PhotoGalleryOp
        [weak photosOpRunItself:NO onQueue:nil completion:nil];
        weak.userPhotoNetOp.downloadProgress = ^(DTO * _Nonnull op, DTODownProgress p) {
            if (groupOp.state == RXNO_Cancelled) [op cancel];
        };
        [weak.userPhotoNetOp syncStart];
        
        if (groupOp.state == RXNO_Cancelled) return;
        if ([APIManager callCompletion:completion ifOccuredErrorInOperation:weak.userPhotoNetOp]){
            return;
        }

        // WallNetOp
        [weak wallOpRunItself:NO onQueue:nil completion:nil];
        weak.userWallNetOp.downloadProgress = ^(DTO * _Nonnull op, DTODownProgress p) {
            if (groupOp.state == RXNO_Cancelled) [op cancel];
        };
        [weak.userWallNetOp syncStart];

        if (groupOp.state == RXNO_Cancelled) return;
        if (completion) completion(weak.userWallNetOp.error);
    }];
    
    self.loadAllNeededConentOp.owner = self.addressInMemory;
    // Add a group operation to the queue for synchronous operations
    [APIManager.syncQueue addOperation:self.loadAllNeededConentOp];
    return self.loadAllNeededConentOp;
}

#pragma mark - Management of network operations
/*--------------------------------------------------------------------------------------------------------------
 Cancels all running network operations in the queue
 --------------------------------------------------------------------------------------------------------------*/
- (void) cancelAllNetworkOperations
{
    printMethod;
    // When creating operations, we make sure to assign a value in the 'owner' field, so that in the future,
    // if a situation arises when during the execution of a network operation the user leaves the screen,
    // and the operation is performed in the queue, we can cancel it.
    
    // The RXNO framework offers a choice of two helper methods.
    // 1) cancelAllNetworkOperationsByEqual it is needed when we pass the link to some object as the 'owner'.
    //   And we want to determine from it whether the operation needs to be canceled or not.
    
    // 2) cancelAllNetworkOperationsByEqualToString needed when we set the character set as 'owner',
    //    that is, if there is a possibility that when creating and setting a value in property, an object with one address was set,
    //    and it is already passed to the cancellation method with a different address, but in fact both the first and the second contain
    //    the same set of characters.
    
    // Canceling work on two queues at once
    [BO cancelAllNetworkOperationsByEqualToString:self.addressInMemory inQueue:APIManager.aSyncQueue];
    [BO cancelAllNetworkOperationsByEqualToString:self.addressInMemory inQueue:APIManager.syncQueue];
}



#pragma mark - Initialization

/*--------------------------------------------------------------------------------------------------------------
 Initializes the viewModel with 'userID'. (The data is obtained by the result of a network request in the future)
 --------------------------------------------------------------------------------------------------------------*/
+ (UserProfileVM*) initWithUserID:(nullable NSString*)userID
{
    UserProfileVM* viewModel = [[UserProfileVM alloc] init];
    if (viewModel){
        viewModel.userID = userID;
    }
    return viewModel;
}

#pragma mark - Life Cycle

- (void)dealloc
{
    printMethod;
    [self cancelAllNetworkOperations];
}


#pragma mark - Getters/Setters

/*--------------------------------------------------------------------------------------------------------------
  Stores absolutely all the viewModels of the cells presented in the table.
 --------------------------------------------------------------------------------------------------------------*/
- (NSMutableArray<id> *)cellsViewModel
{
    if (!_cellsViewModel){
         _cellsViewModel = [NSMutableArray new];
    }
    return _cellsViewModel;
}

/*--------------------------------------------------------------------------------------------------------------
  Stores only viewModels of 'WallPostCellVM' class
 --------------------------------------------------------------------------------------------------------------*/
- (NSMutableArray<WallPostCellVM *> *)wallPostsCellViewModel
{
    if (!_wallPostsCellViewModel){
         _wallPostsCellViewModel = [NSMutableArray new];
    }
    return _wallPostsCellViewModel;
}

/*--------------------------------------------------------------------------------------------------------------
 Stores user id
 --------------------------------------------------------------------------------------------------------------*/
- (NSString *)userID
{
    if (!_userID){
         _userID = APIManager.token.userID;
    }
    return _userID;
}

/*--------------------------------------------------------------------------------------------------------------
  Returns the username
 --------------------------------------------------------------------------------------------------------------*/
- (NSString *)userFirstName
{
    return self.userProfileModel.firstName;
}

@end
