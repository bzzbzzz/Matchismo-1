//
//  CardGameViewController.m
//  Matchismo
//
//  Created by Nikita Kukushkin on 30/01/2013.
//  Copyright (c) 2013 Nikita Kukushkin. All rights reserved.
//

#import "CardGameViewController.h"
#import "PlayingCardDeck.h"
#import "CardMatchingGame.h"
#import "PlayingCard.h" 
#import "Utilities.h"

@interface CardGameViewController () <UIAlertViewDelegate>

@property (weak, nonatomic) IBOutlet UISlider *historySlider;
@property (nonatomic, strong) CardMatchingGame *game;
@property (nonatomic) enum GameMode gameMode;
@property (weak, nonatomic) IBOutlet UISegmentedControl *gameModeSegmentControl;
@property (weak, nonatomic) IBOutlet UILabel *flipsLabel;
@property (weak, nonatomic) IBOutlet UILabel *statusLabel;
@property (weak, nonatomic) IBOutlet UILabel *scoreLabel;
@property (strong, nonatomic) IBOutletCollection(UIButton) NSArray *cardButtons;

@end

@implementation CardGameViewController

// Synchronises Model with the View
- (void)updateUI
{    
    self.statusLabel.text = [self.game.history lastObject];
    self.flipsLabel.text = [NSString stringWithFormat:@"Flips: %d", self.game.flipCount];
    
    self.historySlider.maximumValue = [self.game.history count] - 1;
    self.historySlider.value = self.historySlider.maximumValue;
    
    for (UIButton *cardButton in self.cardButtons) {
        
        // We assume that the cards in the model are PlayingCards,
        // because we need card.faceImage from PlayingCard
        PlayingCard *card = (PlayingCard *)[self.game cardAtIndex:[self.cardButtons indexOfObject:cardButton]];
        
        [cardButton setTitle:card.contents forState:UIControlStateSelected];
        [cardButton setTitle:card.contents forState:UIControlStateSelected|UIControlStateDisabled];
        
        cardButton.selected = card.isFaceUp;
        cardButton.enabled = !card.isUnplayable;
        cardButton.alpha = card.isUnplayable ? 0.3 : 0.97;
        
        if (card.isFaceUp) {
            // Shrinking cardFaceImage to the size of the button
            UIImage *cardFaceImage = [Utilities imageWithImage:card.faceImage convertToSize:[self.cardButtons[0] size]];
            // and then settings it as an image for the button
            // *makes it look a bit better
            [cardButton setImage:cardFaceImage forState:UIControlStateNormal];
        }
        else {
            UIImage *cardBackImage = [Utilities imageWithImage:[UIImage imageNamed:@"card-back.png"] convertToSize:[self.cardButtons[0] size]];
            [cardButton setImage:cardBackImage forState:UIControlStateNormal];
        }

    }
    self.scoreLabel.text = [NSString stringWithFormat:@"Score: %d", self.game.score];
}

- (void)newGame
{
    // Move parts of UI to appropriate state
    self.gameModeSegmentControl.enabled = YES;
    self.gameModeSegmentControl.alpha = 1.0;
    self.historySlider.enabled = NO;
    self.historySlider.alpha = 0.0;
    
    // Discard current game
    self.game = nil; // note: new game will be created @ accessor for self.game
    [self updateUI];
}

#pragma mark - Actions

- (IBAction)deal:(id)sender {
    
    // If game is over or hasn't started yet, 
    // then just we just start a new game
    // note: every game starts with one item in history (intro text)
    if ([self.game isGameOver] || [[self.game history] count] == 1) {
        [self newGame];
    }
    
    // If game wasn't over we promt user
    // if he agrees to lose current games data
    else {
        // note: code below just pops the alert
        // logic is in UIAlertViewDelegate method (it's same as above)
        // (#pragma mark - UIAlertViewDelegate)
        UIAlertView *alert = [[UIAlertView alloc]
                              initWithTitle:@"Deal new cards?"
                              message:@"Current score will be lost!"
                              delegate:self
                              cancelButtonTitle:@"No"
                              otherButtonTitles:@"Yes", nil];
        [alert show];
    }
}

- (IBAction)slideThruHistory:(UISlider *)sender {
    self.statusLabel.text = self.game.history[(int)sender.value];
}

- (IBAction)flipCard:(UIButton *)sender
{
    // Animating the flip
    [UIView beginAnimations:@"flipCard" context:nil];
    [UIView setAnimationTransition:UIViewAnimationTransitionFlipFromRight
                           forView:sender
                             cache:YES];
    [UIView setAnimationDuration:0.23];
    [UIView commitAnimations];
    
    self.historySlider.enabled = YES;
    self.historySlider.alpha = 1.0;
    self.gameModeSegmentControl.enabled = NO;
    self.gameModeSegmentControl.alpha = 0.0;
    
    // Updating the Model
    [self.game flipCardAtIndex:[self.cardButtons indexOfObject:sender]];
    // and syncing it with the View
    [self updateUI];
}

#pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    // If user clicks "Yes" (no = 0, yes = 1)
    if (buttonIndex == 1)
    {
        [self newGame];
    }
    // Dismissing alert window
    [alertView dismissWithClickedButtonIndex:buttonIndex animated:YES];
}

#pragma mark - Accessors

- (IBAction)changeGameMode:(UISegmentedControl *)sender {
    // Just gets rid of an old game
    // so it can crate a new one
    // with desired game mode
    self.game = nil; // note: new game creates @ accessor for game
}

- (enum GameMode)gameMode
{
    // gameMode returns value according to the
    // segmentControl's selected index
    // 0 - twoCard game (default)
    // 1 - threeCard game
    if (self.gameModeSegmentControl.selectedSegmentIndex == 1) {
        return threeCards;
    }
    else {
        return twoCards;
    }
}

- (CardMatchingGame *)game
{
    if (!_game) {
        _game = [[CardMatchingGame alloc] initWithCardCount:[self.cardButtons count] andGameMode:self.gameMode usingDeck:[[PlayingCardDeck alloc] init]];
    }
    return _game;
}

- (void)setCardButtons:(NSArray *)cardButtons
{
    _cardButtons = cardButtons;
    [self updateUI];
}

#pragma mark - Lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Settings initial parameters for Views
    self.gameModeSegmentControl.enabled = YES;
    self.gameModeSegmentControl.alpha = 1.0;
    self.historySlider.enabled = NO;
    self.historySlider.alpha = 0.0;
    self.historySlider.minimumValue = 0.0;
    self.statusLabel.text = @"match cards for rank or suit";
    
    // Settings background
    self.view.backgroundColor = [[UIColor alloc] initWithPatternImage:[UIImage imageNamed:@"table-background"]];
}

@end
