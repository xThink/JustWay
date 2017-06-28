//
//  HJNewsViewController.m
//  JustWay
//
//  Created by HeJun on 28/06/2017.
//  Copyright © 2017 HeJun. All rights reserved.
//

#import "HJNewsViewController.h"
#import "HJUploaderServer.h"

@interface HJNewsViewController ()<UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, weak)	  UITableView	 *tableView;

@property (nonatomic, strong) NSMutableArray *dataList;
/** 文件存储目录 */
@property (nonatomic, copy)	  NSString		 *fileDir;
/** 服务器监听端口 */
@property (nonatomic, assign) NSUInteger	 serverPort;
/** 服务器监听地址 */
@property (nonatomic, copy)	  NSString		 *serverUrl;

@end

@implementation HJNewsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
	
	self.serverPort = 80;
	
	[self setupViews];
	[self initData];
	[self.tableView reloadData];
	
	[[HJUploaderServer sharedInstance] addObserver:self forKeyPath:@"fileList" options:NSKeyValueObservingOptionNew context:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc {
	HJLog(@"%s", __func__);
	[[HJUploaderServer sharedInstance] removeObserver:self forKeyPath:@"fileList" context:nil];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
	NSMutableArray *fileList = change[NSKeyValueChangeNewKey];
	
//	HJLog(@"%@ : %@", change, fileList);
	self.dataList = [fileList mutableCopy];
	[self.tableView reloadData];
}

/**
 * 初始化数据
 */
- (void)initData {
	[HJUploaderServer sharedInstance].fileDir = self.fileDir;
	[[HJUploaderServer sharedInstance] getFileLists];
	self.dataList = [HJUploaderServer sharedInstance].fileList;
}

/**
 * 初始化控件
 */
- (void)setupViews {
	UIButton *serverButton = [UIButton buttonWithType:UIButtonTypeCustom];
	[serverButton setTitle:@"启动" forState:UIControlStateNormal];
	[serverButton setTitle:@"暂停" forState:UIControlStateSelected];
	[serverButton setTitleColor:HJRGB(4, 164, 255) forState:UIControlStateNormal];
	serverButton.titleLabel.font = [UIFont systemFontOfSize:15];
	CGRect serverButtonRect = [@"启动" boundingRectWithSize:CGSizeMake(CGFLOAT_MAX, CGFLOAT_MAX) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName : serverButton.titleLabel.font} context:nil];
	serverButton.frame = CGRectMake(0, 0, 44, serverButtonRect.size.width);
	[serverButton addTarget:self action:@selector(handleRightButton:) forControlEvents:UIControlEventTouchUpInside];
	UIBarButtonItem *rightButton = [[UIBarButtonItem alloc] initWithCustomView:serverButton];
	self.navigationItem.rightBarButtonItem = rightButton;
	
	UITableView *tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height) style:UITableViewStylePlain];
	tableView.delegate = self;
	tableView.dataSource = self;
	[self.view addSubview:tableView];
	self.tableView = tableView;
}

#pragma mark - user event
/**
 * 点击启动服务器按钮
 */
- (void)handleRightButton:(UIButton *)button {
	HJLog(@"启动服务器");
	if (!button.isSelected) {
		//启动
		HJWeakSelf;
		[[HJUploaderServer sharedInstance] startWithDir:self.fileDir port:self.serverPort block:^(NSObject *obj) {
			if ([obj isKindOfClass:[NSString class]]) {
				weakSelf.serverUrl = (NSString *)obj;
				self.title = weakSelf.serverUrl;
			} else {
				HJLog(@"启动失败");
			}
		}];
	} else {
		//暂停
		[[HJUploaderServer sharedInstance] stop];
		self.title = @"动态";
	}
	button.selected = !button.isSelected;
}

#pragma mark - UITableViewDelegate
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return self.dataList.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:NSStringFromClass([UITableViewCell class])];
	if (cell == nil) {
		cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:NSStringFromClass([UITableViewCell class])];
	}
	
	NSDictionary *dic = [self.dataList objectAtIndex:indexPath.row];
	cell.textLabel.text = dic[@"title"];
	cell.detailTextLabel.text = dic[@"detail"];
	return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - lazyload
- (NSMutableArray *)dataList {
	if (_dataList == nil) {
		_dataList = [NSMutableArray array];
	}
	return _dataList;
}

- (NSString *)fileDir {
	if (_fileDir == nil) {
		_fileDir = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
	}
	return _fileDir;
}

@end