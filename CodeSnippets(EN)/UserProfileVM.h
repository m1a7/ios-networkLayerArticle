#import <Foundation/Foundation.h>
// Network Operation
#import <RXNetworkOperation/RXNetworkOperation.h>
// Consts
#import "FoundationConsts.h"

NS_ASSUME_NONNULL_BEGIN

// ViewModel для контроллера UserProfileTVC
@class WallPostCellVM;
@class UserProfileCellVM;
@class UserProfileGalleryCellVM;

/*--------------------------------------------------------------------------------------------------------------
 (🗃⚖️📱) 'UserProfileVM' - viewModel табличного контроллера 'UserProfileTVC'.
 --------------------------------------------------------------------------------------------------------------*/

@interface UserProfileVM : NSObject

// Пользовательские данные
@property (nonatomic, strong) NSString* userID;

// Данные для UI
/*--------------------------------------------------------------------------------------------------------------
 ViewModel сложно составных таблиц имеют следующие разделение в хранении вьюМоделей ячеек:
 Один общий массив для всех вьюМоделей, и доп.массив/ы для каждого из классов вьюМоделей ячеек.
 1) 'cellsViewModel'         - хранит абсолютно все вьюМодели ячеек представленных в таблице.
 2) 'wallPostsCellViewModel' - хранит только вьюМодели класса 'WallPostCellVM'.
 --------------------------------------------------------------------------------------------------------------*/
@property (nonatomic, strong) NSMutableArray<id>* cellsViewModel;
@property (nonatomic, strong) NSMutableArray<WallPostCellVM*>* wallPostsCellViewModel;

// Ссылка на viewModel для горизонтального 'UICollectionView' с фотографиями пользователя
@property (nonatomic, strong, readonly) UserProfileGalleryCellVM* photoGalleryVM;

@property (nonatomic, weak, nullable) NSString* userFirstName;

// Сетевые операции
@property (nonatomic, strong) GO* loadAllNeededConentOp;

@property (nonatomic, strong) __block DTO* userInfoNetOp;
@property (nonatomic, strong) __block DTO* userPhotoNetOp;
@property (nonatomic, strong) __block DTO* userWallNetOp;
@property (nonatomic, strong)  DTO* logoutNetOp;

#pragma mark - Work with Network operations
/*--------------------------------------------------------------------------------------------------------------
  Получает расширенную информацию о пользователе по 'self.userID' или по 'APIManager.token.userID'.
  Инициализирует viewModel ячейки с помощью полученной модели, и добавляет ее в 'cellsViewModel'.
 --------------------------------------------------------------------------------------------------------------*/
- (DTO*) userInfoOpRunItself:(BOOL)runOpItself
                     onQueue:(nullable NSOperationQueue*)queue
                  completion:(nullable void(^)(NSError* _Nullable error, UserProfileCellVM* _Nullable cellVM))completion;


/*--------------------------------------------------------------------------------------------------------------
 Получает коллекцию фотографий пользователя по его 'self.userID' или по 'APIManager.token.userID'.
 Инициализирует viewModel ячейки с помощью полученной модели, и добавляет ее в 'cellsViewModel'.
 --------------------------------------------------------------------------------------------------------------*/
- (DTO*) photosOpRunItself:(BOOL)runOpItself
                   onQueue:(nullable NSOperationQueue*)queue
                completion:(nullable void(^)(NSError* _Nullable error))completion;


/*--------------------------------------------------------------------------------------------------------------
 Получает записи со стены пользователя по 'self.userID' или по 'APIManager.token.userID'.
 Инициализирует viewModel ячейки с помощью полученной модели, и добавляет ее в 'cellsViewModel'.
 --------------------------------------------------------------------------------------------------------------*/
- (DTO*) wallOpRunItself:(BOOL)runOpItself
                 onQueue:(nullable NSOperationQueue*)queue
              completion:(nullable void(^)(NSError* _Nullable error,
                                           NSArray<WallPostCellVM*>* _Nullable viewModels,
                                           NSArray<NSIndexPath*>*    _Nullable indexPaths))completion;

/*--------------------------------------------------------------------------------------------------------------
 Вызывает сетевую операцию которая посылает запрос о разлогирование. Отчищает хранилище на диске устройства.
 --------------------------------------------------------------------------------------------------------------*/
- (DTO*) logoutOpRunItself:(BOOL)runOpItself
                   onQueue:(nullable NSOperationQueue*)queue
                completion:(nullable void(^)(void))completion;

/*--------------------------------------------------------------------------------------------------------------
 Последовательно выполняет три сетевых операции (userInfoNetOp,userPhotoNetOp,userWallNetOp)
 --------------------------------------------------------------------------------------------------------------*/
- (GO*) performNeededOperations:(void(^)(NSError* _Nullable error))completion;


#pragma mark - Management of network operations
/*--------------------------------------------------------------------------------------------------------------
 Отменяет все запущенные сетевые операции которые выполняются в очереди
 --------------------------------------------------------------------------------------------------------------*/
- (void) cancelAllNetworkOperations;


#pragma mark - Initialization

/*--------------------------------------------------------------------------------------------------------------
 Инициализирует viewModel с 'userID'. (Данные получает по результату выполнения сетевого запроса в будущем)
 --------------------------------------------------------------------------------------------------------------*/
+ (UserProfileVM*) initWithUserID:(nullable NSString*)userID;

@end

NS_ASSUME_NONNULL_END
