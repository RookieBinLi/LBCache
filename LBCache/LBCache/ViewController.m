//
//  ViewController.m
//  LBCache
//
//  Created by LB on 2017/9/15.
//  Copyright © 2017年 LB. All rights reserved.
//

#import "ViewController.h"
#import "LBCacheManager.h"
#import "Person.h"

@interface ViewController ()
@property (weak, nonatomic) IBOutlet UIImageView *imageView;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    
}


- (IBAction)cacheObject:(UIButton *)sender {
    Person *person = [[Person alloc] init];
    person.name = @"Tom";
    person.grade = @"3";
    person.age = 8;
    [[LBCacheManager sharedManager] setObectValue:person forKey:@"Person"];
}

- (IBAction)readObejct:(UIButton *)sender {
    
    id person = [[LBCacheManager sharedManager] readObjectForkey:@"Person"];
    if (person && [person isKindOfClass:[Person class]]) {
        Person *newPerson = (Person *)person;
        
        NSLog(@"name == %@ grade == %@ age == %d",newPerson.name,newPerson.grade,newPerson.age);
    }
    
    
}

- (IBAction)cacheImage:(UIButton *)sender {
    UIImage *image = [UIImage imageNamed:@"1122.jpg"];
    [[LBCacheManager sharedManager] setImage:image forKey:@"IMAGE"];
}

- (IBAction)readImage:(id)sender {
    UIImage *image = [[LBCacheManager sharedManager]readImageObjectForKey:@"IMAGE"];
    self.imageView.image = image;
}

- (IBAction)deleteImage:(id)sender {
    
    [[LBCacheManager sharedManager] removeCacheForKey:@"IMAGE" complete:^{
        [self readImage:nil];
    }];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
