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
 (🗃⚖️📱) 'UserProfileVM' - viewModel табличного контроллера 'UserProfileTVC'.
 --------------------------------------------------------------------------------------------------------------*/

@interface UserProfileVM ()
// Ссылка на viewModel ячейки которая имеет горизонтальный collectionView с фото пользователя
@property (nonatomic, strong, readwrite) UserProfileGalleryCellVM* photoGalleryVM;
// Models
@property (nonatomic, strong) UserProfile* userProfileModel;
@end



@implementation UserProfileVM

#pragma mark - NetworkOperations

/*--------------------------------------------------------------------------------------------------------------
 Получает расширенную информацию о пользователе по 'self.userID' или по 'APIManager.token.userID'.
 Инициализирует viewModel ячейки с помощью полученной модели, и добавляет ее в 'cellsViewModel'.
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
 Получает коллекцию фотографий пользователя по его 'self.userID' или по 'APIManager.token.userID'.
 Инициализирует viewModel ячейки с помощью полученной модели, и добавляет ее в 'cellsViewModel'.
 -------
 (⚠️) В этом методе имеется особое обстоятельство:
  Данная вьюМодель ('UserProfileVM') содержит в себе еще одну вьюМодель ('UserProfileGalleryCellVM'), которая обслуживает
  горизонтальный 'UICollectionView' с фотографиями пользователя.
  По факту получается, что проперти на сетевую операцию содержит дочерняя вьюМодель.
  Так что если нам экстренно потребуется отменить выполнение операции, нужно обращаться через дочернюю вьюМодель.
 --------------------------------------------------------------------------------------------------------------*/
- (DTO*) photosOpRunItself:(BOOL)runOpItself
                   onQueue:(nullable NSOperationQueue*)queue
                completion:(nullable void(^)(NSError* _Nullable error))completion
{   printMethod;
    // Если операция выполняется в данный момент то возвращаем проперти на нее.
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
 Получает записи со стены пользователя по 'self.userID' или по 'APIManager.token.userID'.
 Инициализирует viewModel ячейки с помощью полученной модели, и добавляет ее в 'cellsViewModel'.
--------------------------------------------------------------------------------------------------------------*/
- (DTO*) wallOpRunItself:(BOOL)runOpItself
                 onQueue:(nullable NSOperationQueue*)queue
              completion:(nullable void(^)(NSError* _Nullable error,
                                           NSArray<WallPostCellVM*>* _Nullable viewModels,
                                           NSArray<NSIndexPath*>*    _Nullable indexPaths))completion
{   printMethod;
    // Если операция выполняется в данный момент то возвращаем проперти на нее.
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
                          [weak.cellsViewModel         addObject:cellViewModel]; // Это общий массив под все ячейки
                          [weak.wallPostsCellViewModel addObject:cellViewModel]; // Тут храниться viewModels только для WallPostCell
                                                                                 // Сделано это для удобства, чтобы offset не рассчитывать.
                          [viewModels addObject:cellViewModel];
                          [indexPaths addObject:[NSIndexPath indexPathForRow:1//[weak.cellsViewModel indexOfObject:cellViewModel]
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
 Вызывает сетевую операцию которая посылает запрос о разлогирование. Отчищает хранилище на диске устройства.
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
 Последовательно выполняет три сетевых операции (userInfoNetOp,userPhotoNetOp,userWallNetOp).
 Инициирует процесс выполнения операций не на прямую через проперти, а через метод обертки, которые берут на себя
 обязательства самостоятельно преобразовывать и сохранять полученные от 'APIManager' данные.
 --------------------------------------------------------------------------------------------------------------*/
- (GO*) performNeededOperations:(void(^)(NSError* _Nullable error))completion
{
    printMethod;
    __weak UserProfileVM* weak = self;
    // Group operation initialization
    self.loadAllNeededConentOp = [GO groupOperation:^(GO * _Nonnull groupOp){
        
        // (!) Если мы не обращаемся к сетевым операциям через 'weak', а просто создаем их тут
        //     То так они удаляются из памяти быстрее, нежеле чем когда мы обращаемся из блока к проперти
        
        // UserInfoOp
        [weak userInfoOpRunItself:NO onQueue:nil completion:nil];
        // Поддержка отмены сетевой операции, если была отмененна групповая операция
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
    // Добавляем групповую операцию в очередь для синхронных операций
    [APIManager.syncQueue addOperation:self.loadAllNeededConentOp];
    return self.loadAllNeededConentOp;
}

#pragma mark - Management of network operations
/*--------------------------------------------------------------------------------------------------------------
 Отменяет все запущенные сетевые операции которые выполняются в очереди
 --------------------------------------------------------------------------------------------------------------*/
- (void) cancelAllNetworkOperations
{
    printMethod;
    // Во время создания операций мы обязательно присваиваем значение в поле 'owner', чтобы в будущем, если возникнет
    // ситуация когда во время выполнения сетевой операции пользователь покинет экран, а операция будет выполняться в
    // очереди, мы могли ее отменить.
    
    // Фраемворк RXNO предлагает на выбор два метода помощника.
    // 1) cancelAllNetworkOperationsByEqual нужен когда мы в качестве 'owner' передаем именно ссылку на какой-то объект.
    //    И по нему хотим определять, нужно ли отменять операцию или нет.
    
    // 2) cancelAllNetworkOperationsByEqualToString нужен когда в качестве 'owner' мы устанавливаем именно набор символов,
    //    то есть если есть вероятность, что при создании и установки значения в проперти был установлен объект с одним
    //    адресом, а в метод отмены уже передается с другим адресом, но по факту и первый и второй содержат один и тот же
    //    набор символов.
    
    // Отменяем работу сразу на двух очередях
    [BO cancelAllNetworkOperationsByEqualToString:self.addressInMemory inQueue:APIManager.aSyncQueue];
    [BO cancelAllNetworkOperationsByEqualToString:self.addressInMemory inQueue:APIManager.syncQueue];
}



#pragma mark - Initialization

/*--------------------------------------------------------------------------------------------------------------
 Инициализирует viewModel с 'userID'. (Данные получает по результату выполнения сетевого запроса в будущем)
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
  Хранит абсолютно все вьюМодели ячеек представленных в таблице.
 --------------------------------------------------------------------------------------------------------------*/
- (NSMutableArray<id> *)cellsViewModel
{
    if (!_cellsViewModel){
         _cellsViewModel = [NSMutableArray new];
    }
    return _cellsViewModel;
}

/*--------------------------------------------------------------------------------------------------------------
  Хранит только вьюМодели класса 'WallPostCellVM'
 --------------------------------------------------------------------------------------------------------------*/
- (NSMutableArray<WallPostCellVM *> *)wallPostsCellViewModel
{
    if (!_wallPostsCellViewModel){
         _wallPostsCellViewModel = [NSMutableArray new];
    }
    return _wallPostsCellViewModel;
}

/*--------------------------------------------------------------------------------------------------------------
  Хранит id пользователя
 --------------------------------------------------------------------------------------------------------------*/
- (NSString *)userID
{
    if (!_userID){
         _userID = APIManager.token.userID;
    }
    return _userID;
}

/*--------------------------------------------------------------------------------------------------------------
 Возвращает имя пользователя
 --------------------------------------------------------------------------------------------------------------*/
- (NSString *)userFirstName
{
    return self.userProfileModel.firstName;
}

@end
