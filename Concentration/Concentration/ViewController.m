//
//  ViewController.m
//  Concentration
//
//  Created by Alessi Patrick on 9/14/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "ViewController.h"

@implementation ViewController

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    [self createCards];
    
    firstTappedView = nil;
    isAnimating = NO;
    
}
-(void) createCards
{
    // 16 * 4 cards
    // Create cards 生成64个card，card的对象为有1-16NSNumber，四组
    NSMutableArray *cards = [[NSMutableArray alloc] initWithCapacity:64];
    
    for (int i=1; i<=16; i++) {
        for (int j=1; j<=4; j++) {
            [cards addObject:[NSNumber numberWithInt:i]];
        }
    }
    
    // Shuffle cards  洗牌，这样放在数组第一个1位置中card的对象值可能就不是1.
    srandom( time( NULL ) );
    int swapA, swapB;
    
    for (int i=0; i<100000; i++) {
        
        swapA = (random() % 64);
        swapB = (random() % 64);
        
        NSNumber *tempNumber = [cards objectAtIndex:swapA];
        [cards replaceObjectAtIndex:swapA 
                         withObject:[cards objectAtIndex:swapB]];
        [cards replaceObjectAtIndex:swapB
                         withObject:tempNumber];
    }
    
    [self addCardsToView:cards];  //cards添加到view中，同时用动画发牌。
    
}

-(void) addCardsToView:(NSMutableArray*) cards
{
    
    CardImageView* card;   //一个临时card
    CGRect cardFrame;    //用于当前临时card的Rect
    CGRect cardOrigin = CGRectMake(0,0, 40, 60);//牌的初始位置和牌大小
    
    cardFrame.size = CGSizeMake(40, 60); //  牌大小
    CGPoint origin;   //
    int cardIndex = 0; //cards 的索引
    
    NSTimeInterval timeDelay = 0.0;   //每张card的动画延迟，时间递增，就有牌不是同一时刻发的效果。就像连续的。
    
    //将card放成8*8的矩阵。逐个初始化，再移动到目的位置。
    for (int i=0; i<8; i++) {
        for (int j=0; j<8; j++) {
            origin.y = i*70 + 100;
            origin.x = j * 50 + 100;
            cardFrame.origin = origin;   //指定一个card的目的位置Frame
            
            // Create the card at the origin，用原点cardOrigin，初始化一个card，索引初始为0的value，后++，
            card = [[CardImageView alloc] initWithFrame:cardOrigin 
                                                  value:[[cards objectAtIndex:cardIndex] intValue]];
            
            // Configure gesture recognizer给UIImage增加单击手势。
            UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] 
                                           initWithTarget:self 
                                           action:@selector(handletap:)];
            tap.numberOfTapsRequired = 1;
            
            [card addGestureRecognizer:tap]; //给当前card添加单击手势。
            
            
            [self.view addSubview:card];   //f当前card添加到view
            
            // Animate moving the cards into position
            // In iOS 4 and later, use the Block-based animation methods.
            //通过UIView属性动画，发牌，（修改card的frame为目的Rect-cardFrame,就会有动画，牌移动到指定位置。
            [UIView animateWithDuration:0.5 
                                  delay:timeDelay 
                                options:UIViewAnimationOptionCurveLinear 
                             animations: ^{
                                 card.frame = cardFrame;
                             } 
                             completion:NULL];
            
            timeDelay += 0.1;  //每个card的动画延迟，看起来向一个一个的发
            cardIndex++;  //cards索引递增。
            
        }
        
    }
}

//添加单击时，指定的方法
- (void)handletap:(UIGestureRecognizer *)gestureRecognizer
{
    
    // If an animation is running, ignore taps，如果在执行反转或消失动画时，不响应单击。初始为NO。
    if (isAnimating)
        return;
    
    //从参数获得单击的view
    CardImageView *tappedCard = (CardImageView*) gestureRecognizer.view;
    
    
    // Has a card already been tapped?
//    如果没有一个card正面朝上，初始为nil
    if (firstTappedView == nil)
    {
        // Flip the tapped card翻转当前card动画执行，执行当前card的flipCard方法。filpCard方法会改card的背景图。
        [UIView transitionWithView:tappedCard
                          duration:0.5
                           options:UIViewAnimationOptionTransitionFlipFromLeft
                        animations:^{ 
                            [tappedCard flipCard];
                        }
         
                        completion:NULL];
        // This is the first card, so just set it
        firstTappedView = tappedCard;  //并将第一张card设置为当前card
    }
    //如果点击的不是第一张card
    else if (firstTappedView != tappedCard)
    {
        // If the player didn't tap the same card again...
        
        // Ignore taps because we are animating
        isAnimating = YES;
        //第二个card在反转一次
        [UIView transitionWithView:tappedCard
                          duration:0.5
                           options:UIViewAnimationOptionTransitionFlipFromLeft
                        animations:^{ 
                            [tappedCard flipCard];
                        }
         
                        completion:NULL];
        // A card has already been tapped, so test for a match
        //如果两个值相等
        if (firstTappedView.value == tappedCard.value)
        {
            // Player found a mat
            // Remove the cards添加一个alpha到0的渐变，这样card消失。，在移除响应view和释放动画，并设置isAnimating
            [UIView animateWithDuration:1 delay:1
                                options:UIViewAnimationOptionTransitionNone
                             animations:^{
                                 firstTappedView.alpha = 0; 
                                 tappedCard.alpha=0;
                             }
                             completion:^(BOOL finished) { 
                                 [firstTappedView removeFromSuperview];
                                 [tappedCard removeFromSuperview];
                                 // Stop ignoring taps because animation is done
                                 isAnimating=NO;
                             }
             ];
            
            
            // Reset the first tapped card to nil匹配后，把第一个card设为nil
            firstTappedView = nil;
        }
        
        else
        {
            // Flip both cards back over如果不匹配，执行filpCard把两个card都反转
            secondTappedView = tappedCard;
            [self performSelector:@selector(flipCards) withObject:nil
                       afterDelay:2];
            
        }
    }
}

//上面两个card不匹配时执行的动画
-(void) flipCards
{
    [UIView transitionWithView:firstTappedView
                      duration:1
                       options:UIViewAnimationOptionTransitionFlipFromRight
                    animations:^{ 
                        [firstTappedView flipCard];
                    }
                    completion:NULL
     ];
    [UIView transitionWithView:secondTappedView
                      duration:1
                       options:UIViewAnimationOptionTransitionFlipFromRight
                    animations:^{ 
                        [secondTappedView flipCard];
                    }
                    completion:^(BOOL finished) { 
                        // Stop ignoring events because animation is done
                        isAnimating=NO;
                        
                    }
     ];
    
    // Reset the first tapped cards to nil
    firstTappedView = nil;
    secondTappedView = nil;
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
	[super viewDidDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

@end
