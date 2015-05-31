//
//  S1MahjongFacePageView.m
//  Stage1st
//
//  Created by Zheng Li on 5/30/15.
//  Copyright (c) 2015 Renaissance. All rights reserved.
//

#import "S1MahjongFacePageView.h"
#import "S1MahjongFaceButton.h"
#import "UIButton+AFNetworking.h"
#import "S1MahjongFaceViewController.h"

@implementation S1MahjongFacePageView

-(instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        _buttons = [[NSMutableArray alloc] init];
    }
    return self;
}

-(void)setMahjongFaceList:(NSArray *)list withRows:(NSInteger)rows andColumns:(NSInteger)columns {
    NSInteger rowIndex = 0;
    NSInteger columnIndex = 0;
    NSInteger buttonIndex = 0;
    for(S1MahjongFaceButton *button in self.buttons) {
        buttonIndex = rowIndex * columns + columnIndex;
        if (buttonIndex < [list count] && buttonIndex < rows * columns) {
            button.mahjongFaceKey = [[list objectAtIndex:buttonIndex] firstObject];
            [self setImageURL:[[list objectAtIndex:buttonIndex] lastObject] forButton:button];
            [button setFrame:CGRectMake(columnIndex * 50 + 10,rowIndex * 50 , 50, 50)];
            button.hidden = NO;
        } else {
            button.hidden = YES;
        }
        columnIndex += 1;
        if (columnIndex == columns) {
            rowIndex += 1;
            columnIndex = 0;
        }
    }
    buttonIndex = rowIndex * columns + columnIndex;
    while (buttonIndex < [list count] && buttonIndex < rows * columns) {
        NSString *key = [[list objectAtIndex:buttonIndex] firstObject];
        NSURL *URL = [[list objectAtIndex:buttonIndex] lastObject];
        S1MahjongFaceButton *button = [self mahjongFaceButtonForKey:key andURL:URL];
        [button setFrame:CGRectMake(columnIndex * 50 + 10,rowIndex * 50 , 50, 50)];
        columnIndex += 1;
        if (columnIndex == columns) {
            rowIndex += 1;
            columnIndex = 0;
        }
        buttonIndex = rowIndex * columns + columnIndex;
    }
}

- (NSMutableURLRequest *)requestForURL:(NSURL *)URL {
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:URL];
    [request addValue:@"image/*" forHTTPHeaderField:@"Accept"];
    return  request;
}

- (S1MahjongFaceButton *)mahjongFaceButtonForKey:(NSString *)key andURL:(NSURL *)URL {
    S1MahjongFaceButton *button = [[S1MahjongFaceButton alloc] init];
    button.contentMode = UIViewContentModeCenter;
    [button addTarget:self action:@selector(mahjongFacePressed:) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:button];
    [self.buttons addObject:button];
    
    button.mahjongFaceKey = key;
    [self setImageURL:URL forButton:button];
    
    return button;
}

- (void)setImageURL:(NSURL *)URL forButton:(S1MahjongFaceButton *)button {
    [button setImage:nil forState:UIControlStateNormal];
    __weak S1MahjongFaceButton *weakButton = button;
    [button setImageForState:UIControlStateNormal withURLRequest:[self requestForURL:URL] placeholderImage:nil success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
        __strong S1MahjongFaceButton *strongButton = weakButton;
        UIImage * theImage = [UIImage imageWithCGImage:image.CGImage scale:1.0 orientation:UIImageOrientationUp];
        [strongButton setImage:theImage forState:UIControlStateNormal];
    } failure:^(NSError *error) {
        NSLog(@"Unexpected failure when request mahjong face image");
    }];
}
- (void)mahjongFacePressed:(S1MahjongFaceButton *)button {
    if (self.viewController) {
        [self.viewController mahjongFacePressed:button];
    }
}
@end
