//
//  DoImagePickerController.m
//  DoImagePickerController
//
//  Created by Donobono on 2014. 1. 23..
//

#import "DoImagePickerController.h"
#import "AssetHelper.h"

#import "DoAlbumCell.h"
#import "DoPhotoCell.h"

@implementation DoImagePickerController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self initControls];
    
    UINib *nib = [UINib nibWithNibName:@"DoPhotoCell" bundle:nil];
    [_cvPhotoList registerNib:nib forCellWithReuseIdentifier:@"DoPhotoCell"];

    [self readAlbumList:YES];

    // new photo is located at the first of array
    ASSETHELPER.bReverse = YES;
	
	if (_nMaxCount != 1)
	{
		// init gesture for multiple selection with panning
		UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(onPanForSelection:)];
		[self.view addGestureRecognizer:pan];
	}

    // init gesture for preview
    UILongPressGestureRecognizer *longTap = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(onLongTapForPreview:)];
    longTap.minimumPressDuration = 0.3;
    [self.view addGestureRecognizer:longTap];
    
    // add observer for refresh asset data
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(handleEnterForeground:)
                                                 name: UIApplicationWillEnterForegroundNotification
                                               object: nil];
}

- (void)viewDidDisappear:(BOOL)animated
{
    if (_nResultType == DO_PICKER_RESULT_UIIMAGE)
        [ASSETHELPER clearData];
    
	[[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillEnterForegroundNotification object:nil];
}

- (void)handleEnterForeground:(NSNotification*)notification
{
    [self readAlbumList:NO];
}

#pragma mark - for init
- (void)initControls
{
    // dimmed view
    _vDimmed.alpha = 0.0;
    _vDimmed.frame = self.view.frame;
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onTapOnDimmedView:)];
    [_vDimmed addGestureRecognizer:tap];
}

- (void)readAlbumList:(BOOL)bFirst
{
    [ASSETHELPER getGroupList:^(NSArray *aGroups) {
        
        NSInteger nIndex = 0;
#ifdef DO_SAVE_SELECTED_ALBUM
        nIndex = [self getSelectedGroupIndex:aGroups];
        if (nIndex < 0)
            nIndex = 0;
#endif
        [self showPhotosInGroup:nIndex];
    }];
}

#pragma mark - for bottom menu
/*
- (IBAction)onSelectPhoto:(id)sender
{
    NSMutableArray *aResult = [[NSMutableArray alloc] initWithCapacity:_dSelected.count];
    NSArray *aKeys = [_dSelected keysSortedByValueUsingSelector:@selector(compare:)];

    if (_nResultType == DO_PICKER_RESULT_UIIMAGE)
    {
        for (int i = 0; i < _dSelected.count; i++)
        {
            UIImage *iSelected = [ASSETHELPER getImageAtIndex:[aKeys[i] integerValue] type:ASSET_PHOTO_SCREEN_SIZE];
            if (iSelected != nil)
                [aResult addObject:iSelected];
        }
    }
    else
    {
        for (int i = 0; i < _dSelected.count; i++)
            [aResult addObject:[ASSETHELPER getAssetAtIndex:[aKeys[i] integerValue]]];
    }

    [_delegate didSelectPhotosFromDoImagePickerController:self result:aResult];
}

- (IBAction)onCancel:(id)sender
{
    [_delegate didCancelDoImagePickerController];
}
*/

#pragma mark - for side buttons
- (void)onTapOnDimmedView:(UITapGestureRecognizer *)tap
{
    if (tap.state == UIGestureRecognizerStateEnded)
    {
        if (_ivPreview != nil)
            [self hidePreview];
    }
}

#pragma mark - UICollectionViewDelegates for photos
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return [ASSETHELPER getPhotoCountOfCurrentGroup];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    DoPhotoCell *cell = (DoPhotoCell *)[_cvPhotoList dequeueReusableCellWithReuseIdentifier:@"DoPhotoCell" forIndexPath:indexPath];

    if (_nColumnCount == 4)
        cell.ivPhoto.image = [ASSETHELPER getImageAtIndex:indexPath.row type:ASSET_PHOTO_THUMBNAIL];
    else
        cell.ivPhoto.image = [ASSETHELPER getImageAtIndex:indexPath.row type:ASSET_PHOTO_ASPECT_THUMBNAIL];
    

	if (_dSelected[@(indexPath.row)] == nil)
		[cell setSelectMode:NO];
    else
		[cell setSelectMode:YES];
	
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (_nMaxCount > 1 || _nMaxCount == DO_NO_LIMIT_SELECT)
    {
		DoPhotoCell *cell = (DoPhotoCell *)[collectionView cellForItemAtIndexPath:indexPath];
        
		if ((_dSelected[@(indexPath.row)] == nil) && (_nMaxCount > _dSelected.count))
		{
			// select
			_dSelected[@(indexPath.row)] = @(_dSelected.count);
			[cell setSelectMode:YES];
		}
		else
		{
			// unselect
			[_dSelected removeObjectForKey:@(indexPath.row)];
			[cell setSelectMode:NO];
		}
        
        /*
        if (_nMaxCount == DO_NO_LIMIT_SELECT)
            _lbSelectCount.text = [NSString stringWithFormat:@"(%d)", (int)_dSelected.count];
        else
            _lbSelectCount.text = [NSString stringWithFormat:@"(%d/%d)", (int)_dSelected.count, (int)_nMaxCount];
         */
    }
    else
    {
        if (_nResultType == DO_PICKER_RESULT_UIIMAGE)
            [_delegate didSelectPhotosFromDoImagePickerController:self result:@[[ASSETHELPER getImageAtIndex:indexPath.row type:ASSET_PHOTO_SCREEN_SIZE]]];
        else
            [_delegate didSelectPhotosFromDoImagePickerController:self result:@[[ASSETHELPER getAssetAtIndex:indexPath.row]]];
    }
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (_nColumnCount == 2)
        return CGSizeMake(158, 158);
    else if (_nColumnCount == 3)
        return CGSizeMake(104, 104);
    else if (_nColumnCount == 4)
        return CGSizeMake(77, 77);

    return CGSizeZero;
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if (scrollView == _cvPhotoList)
    {
        [UIView animateWithDuration:0.2 animations:^(void) {
        }];
    }
}

// for multiple selection with panning
- (void)onPanForSelection:(UIPanGestureRecognizer *)gestureRecognizer
{
    if (_ivPreview != nil)
        return;
    
    double fX = [gestureRecognizer locationInView:_cvPhotoList].x;
    double fY = [gestureRecognizer locationInView:_cvPhotoList].y;
	
    for (UICollectionViewCell *cell in _cvPhotoList.visibleCells)
	{
        float fSX = cell.frame.origin.x;
        float fEX = cell.frame.origin.x + cell.frame.size.width;
        float fSY = cell.frame.origin.y;
        float fEY = cell.frame.origin.y + cell.frame.size.height;
        
        if (fX >= fSX && fX <= fEX && fY >= fSY && fY <= fEY)
        {
            NSIndexPath *indexPath = [_cvPhotoList indexPathForCell:cell];
            
            if (_lastAccessed != indexPath)
            {
				[self collectionView:_cvPhotoList didSelectItemAtIndexPath:indexPath];
            }
            
            _lastAccessed = indexPath;
        }
    }
    
    if (gestureRecognizer.state == UIGestureRecognizerStateEnded)
    {
        _lastAccessed = nil;
        _cvPhotoList.scrollEnabled = YES;
    }
}

// for preview
- (void)onLongTapForPreview:(UILongPressGestureRecognizer *)gestureRecognizer
{
    if (_ivPreview != nil)
        return;
    
    if (gestureRecognizer.state == UIGestureRecognizerStateBegan)
    {
        double fX = [gestureRecognizer locationInView:_cvPhotoList].x;
        double fY = [gestureRecognizer locationInView:_cvPhotoList].y;
        
        NSIndexPath *indexPath = nil;
        for (UICollectionViewCell *cell in _cvPhotoList.visibleCells)
        {
            float fSX = cell.frame.origin.x;
            float fEX = cell.frame.origin.x + cell.frame.size.width;
            float fSY = cell.frame.origin.y;
            float fEY = cell.frame.origin.y + cell.frame.size.height;
            
            if (fX >= fSX && fX <= fEX && fY >= fSY && fY <= fEY)
            {
                indexPath = [_cvPhotoList indexPathForCell:cell];
                break;
            }
        }
        
        if (indexPath != nil)
            [self showPreview:indexPath.row];
    }
}

#pragma mark - for photos
- (void)showPhotosInGroup:(NSInteger)nIndex
{
    if (_nMaxCount == DO_NO_LIMIT_SELECT)
    {
        _dSelected = [[NSMutableDictionary alloc] init];
    }
    else if (_nMaxCount > 1)
    {
        _dSelected = [[NSMutableDictionary alloc] initWithCapacity:_nMaxCount];
    }
    
    [ASSETHELPER getPhotoListOfGroupByIndex:nIndex result:^(NSArray *aPhotos) {
        
        [_cvPhotoList reloadData];
        
        _cvPhotoList.alpha = 0.3;
        [UIView animateWithDuration:0.2 animations:^(void) {
            [UIView setAnimationDelay:0.1];
            _cvPhotoList.alpha = 1.0;
        }];
        
		if (aPhotos.count > 0)
		{
			[_cvPhotoList scrollToItemAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] atScrollPosition:UICollectionViewScrollPositionTop animated:NO];
        }
    }];
    
#ifdef DO_SAVE_SELECTED_ALBUM
    // save selected album
    [self saveSelectedGroup:nIndex];
#endif
    
}

- (void)showPreview:(NSInteger)nIndex
{
    [self.view bringSubviewToFront:_vDimmed];
    
    _ivPreview = [[UIImageView alloc] initWithFrame:_vDimmed.frame];
    _ivPreview.contentMode = UIViewContentModeScaleAspectFit;
    _ivPreview.autoresizingMask = _vDimmed.autoresizingMask;
    [_vDimmed addSubview:_ivPreview];
    
    _ivPreview.image = [ASSETHELPER getImageAtIndex:nIndex type:ASSET_PHOTO_SCREEN_SIZE];
    
    // add gesture for close preview
    UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(onPanToClosePreview:)];
    [_vDimmed addGestureRecognizer:pan];
    
    [UIView animateWithDuration:0.2 animations:^(void) {
        _vDimmed.alpha = 1.0;
    }];
}

- (void)hidePreview
{
    [_ivPreview removeFromSuperview];
    _ivPreview = nil;

    _vDimmed.alpha = 0.0;
    [_vDimmed removeGestureRecognizer:[_vDimmed.gestureRecognizers lastObject]];
}

- (void)onPanToClosePreview:(UIPanGestureRecognizer *)gestureRecognizer
{
    CGPoint translation = [gestureRecognizer translationInView:self.view];

    if (gestureRecognizer.state == UIGestureRecognizerStateEnded)
    {
        [UIView animateWithDuration:0.2 animations:^(void) {
            
            if (_vDimmed.alpha < 0.7)   // close preview
            {
                CGPoint pt = _ivPreview.center;
                if (_ivPreview.center.y > _vDimmed.center.y)
                    pt.y = self.view.frame.size.height * 1.5;
                else if (_ivPreview.center.y < _vDimmed.center.y)
                    pt.y = -self.view.frame.size.height * 1.5;

                _ivPreview.center = pt;

                [self hidePreview];
            }
            else
            {
                _vDimmed.alpha = 1.0;
                _ivPreview.center = _vDimmed.center;
            }
            
        }];
    }
    else
    {
		_ivPreview.center = CGPointMake(_ivPreview.center.x, _ivPreview.center.y + translation.y);
		[gestureRecognizer setTranslation:CGPointMake(0, 0) inView:self.view];
        
        _vDimmed.alpha = 1 - ABS(_ivPreview.center.y - _vDimmed.center.y) / (self.view.frame.size.height / 2.0);
    }
}

#pragma mark - save selected album
- (void)saveSelectedGroup:(NSInteger)nIndex
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	
	[defaults setObject:[[ASSETHELPER getGroupAtIndex:nIndex] valueForProperty:ALAssetsGroupPropertyName] forKey:@"DO_SELECTED_ALBUM"];
	[defaults synchronize];
    
    NSLog(@"[[ASSETHELPER getGroupAtIndex:nIndex] valueForProperty:ALAssetsGroupPropertyName] : %@", [[ASSETHELPER getGroupAtIndex:nIndex] valueForProperty:ALAssetsGroupPropertyName]);
}

- (NSString *)loadSelectedGroup
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	
    NSLog(@"---------> %@", [defaults objectForKey:@"DO_SELECTED_ALBUM"]);
    
    return [defaults objectForKey:@"DO_SELECTED_ALBUM"];
}

- (NSInteger)getSelectedGroupIndex:(NSArray *)aGroups
{
    NSString *strOldAlbumName = [self loadSelectedGroup];
    for (int i = 0; i < aGroups.count; i++)
    {
        NSDictionary *d = [ASSETHELPER getGroupInfo:i];
        if ([d[@"name"] isEqualToString:strOldAlbumName])
            return i;
    }
    
    return -1;
}

#pragma mark - Others
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (BOOL)prefersStatusBarHidden
{
    return YES;
}

@end
