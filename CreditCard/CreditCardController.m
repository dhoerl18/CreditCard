/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
 *
 * This file is part of CreditCard -- an iOS project that provides a smooth and elegant 
 * means to enter or edit credit cards. It was inspired by  a similar form created from 
 * scratch by Square (https://squareup.com/). To see this form in action visit:
 * 
 *   http://functionsource.com/post/beautiful-forms)
 *
 * Copyright 2012 Lot18 Holdings, Inc. All Rights Reserved.
 *
 *
 * Redistribution and use in source and binary forms, with or without modification, are
 * permitted provided that the following conditions are met:
 *
 *    1. Redistributions of source code must retain the above copyright notice, this list of
 *       conditions and the following disclaimer.
 *
 *    2. Redistributions in binary form must reproduce the above copyright notice, this list
 *       of conditions and the following disclaimer in the documentation and/or other materials
 *       provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY Lot18 Holdings ''AS IS'' AND ANY EXPRESS OR IMPLIED
 * WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
 * FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL David Hoerl OR
 * CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
 * ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
 * NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
 * ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

#import <QuartzCore/QuartzCore.h>

#import "CreditCardController.h"

#import "CreditCard.h"
#import "PlaceHolderTextView.h"

#define DELETE_TAG 99

enum { reallyQuitSheet };

@interface CreditCardController () <UITextViewDelegate, UIActionSheetDelegate>

- (IBAction)saveAction:(id)sender;
- (IBAction)editCard:(id)sender;				// edit card

- (void)flashScroller;
- (CGFloat)widthToLastGroup;
- (void)scrollForward:(BOOL)animated;
- (void)updateCCimageWithTransitionTime:(CGFloat)ttime;

- (void)updateUI;

@end

@interface CreditCardController (UIScrollViewDelegate) <UIScrollViewDelegate>
@end

@implementation CreditCardController
{
//	IBOutlet InfiniteScrollView *addressScroller;
//	IBOutlet UIPageControl *addressPager;

	IBOutlet UIImageView *creditCardImage;	// needs to be updated in dispatched block
	IBOutlet UIView *containerView;
	// Text Hierarchy
	IBOutlet UIScrollView *textScroller;
	IBOutlet UIView *warningView;
	IBOutlet PlaceHolderTextView *placeView;
	IBOutlet UITextView *ccText;
	IBOutlet UIButton *updateCard;
	IBOutlet UITextView *dummyTextView;

	UIImageView *ccImage;
	UIImageView *ccBackImage;

	CGFloat oldX;
	NSInteger currentYear;
	
	// CreditCard Info
	creditCardType type;		// brand
	NSUInteger numberLength;	// length of formatted number only
	NSString *creditCardNum;	// real number not the formatted one
	NSInteger month;			// two digits
	NSInteger year;				// two digits
	NSInteger ccv;				// three or 4 digits
	
	// States
	BOOL haveFullNumber;		// got a full number
	BOOL completelyDone;
	
	NSString *successMsg;
}
@synthesize creditCard;		

- (void)viewDidLoad
{
    [super viewDidLoad];

	//NSLog(@"delegate %@", self.navigationController.navigationBar.delegate);

	NSNotificationCenter *defaultCenter = [NSNotificationCenter defaultCenter];
	[defaultCenter addObserver:self selector:@selector(keyboardMoving:) name:UIKeyboardWillShowNotification object:nil];	// dummyTV
	[defaultCenter addObserver:self selector:@selector(keyboardMoving:) name:UIKeyboardDidShowNotification object:nil];		// dummyTV
	[defaultCenter addObserver:self selector:@selector(keyboardMoving:) name:UIKeyboardWillHideNotification object:nil];	// passwordTextField

	UIBarButtonItem *button = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(done:)];
	self.navigationItem.rightBarButtonItem = button;

	if(creditCard) {
		self.navigationItem.title = @"Edit Card";
		button.enabled = YES;
	} else {
		self.navigationItem.title = @"Add Card";
		button.enabled = NO;
	}
	[self editCard:nil];
	
	{
#ifdef LED_FONT
		ccText.font = [UIFont fontWithName:@"LCDMono2" size:23]; // LCDMono2
#endif
		CGRect r = ccText.frame;
		r.size.height = 36;	// 32 in NIB for Courier
		ccText.frame = r;
	}

	creditCardImage.tag = InvalidCard;

	NSDateFormatter *dateFormatter = [NSDateFormatter new];
    [dateFormatter setDateFormat:@"yyyy"];
    currentYear = [[dateFormatter stringFromDate:[NSDate date]] integerValue] - 2000;

	CALayer *layer = containerView.layer;
	layer.cornerRadius = 4.0;
	layer.masksToBounds = YES;
	layer.borderColor = [[UIColor TEXT_COLOR] CGColor];
	layer.borderWidth = 1;

	layer = textScroller.layer;
	layer.cornerRadius = 4.0;
	layer.masksToBounds = YES;
	layer.borderColor = [[UIColor TEXT_COLOR] CGColor];
	layer.borderWidth = 2;

	textScroller.scrollEnabled = NO;
	{	
		ccText.text = @"000011112222333344445555";	// need something to get the size

		UITextPosition *start	= [ccText beginningOfDocument];
		UITextPosition *end		= [ccText positionFromPosition:start offset:24];
		UITextRange	*range		= [ccText textRangeFromPosition:start toPosition:end];
		CGRect r = [ccText firstRectForRange:range];
		r.size.width /= 24.0f;
		//NSLog(@"First Rect=%@", NSStringFromCGRect(r) );
		ccText.text = @"";

		placeView.font = ccText.font;
		//placeView.text = @"∎∎∎∎"; // Unicode not fixed width!!!
		placeView.text = @"XXXX ";
		placeView.showTextOffset = 0;
		placeView.offset = r;
		//placeView.backgroundColor = [UIColor clearColor];
		
		[textScroller insertSubview:placeView atIndex:0];
	}	

	type = InvalidCard;
	
	ccText.inputAccessoryView = containerView;
	dummyTextView.inputAccessoryView = containerView;
	[containerView removeFromSuperview];

	if(creditCard) {
		UIView *v = [creditCard viewForItem];
		[creditCard resizeView:v]; // shrink width
	} else {
		[dummyTextView becomeFirstResponder];
	}
}
- (void)viewDidUnload
{
	// BEWARE: may not be complete or correct!
	dummyTextView = nil;
	creditCardImage = nil;
	containerView = nil;
	textScroller = nil;
	warningView = nil;
	placeView = nil;
	ccText = nil;
	updateCard = nil;
}
- (void)dealloc
{
 	[[NSNotificationCenter defaultCenter] removeObserver:self];
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

- (void)scrubForm
{

}

- (NSNumber *)shouldPop
{
	NSString *msg = @"Do you really want to go back? If you do the numbers you entered will be lost.";

	BOOL ret = YES;
	if([ccText.text length]) {
		UIActionSheet *sheet = [[UIActionSheet alloc] initWithTitle:msg  delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:@"Go Back" otherButtonTitles:nil];
		sheet.tag = reallyQuitSheet;
		[sheet showInView:self.view];
		ret = NO;
	}
	return [NSNumber numberWithBool:ret];
}

- (void)keyboardMoving:(NSNotification *)note
{
	NSString *msg			= [note name];	

	if(!dummyTextView.tag) {
		if([msg isEqualToString:UIKeyboardWillShowNotification]) {
			;
		} else
		if([msg isEqualToString:UIKeyboardDidShowNotification]) {
			dummyTextView.tag = YES;
			BOOL ret = [ccText becomeFirstResponder];
			assert(ret);
		}
	}
}

#if 0
- (BOOL)textViewShouldBeginEditing:(UITextView *)textView
{
	return YES;
}

- (void)textViewDidBeginEditing:(UITextView *)textView 
{
}
#endif

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{
	NSString *formattedText;
	BOOL flashForError = NO;
	BOOL updateText = NO;
	BOOL scrollForward = NO;
	BOOL deleting = NO;
	BOOL ret = NO;
	BOOL deletedSpace = NO;

	// NSLog(@"RANGE=%@", NSStringFromRange(range) );
	completelyDone = NO;
	if([text length] == 0) {
		updateText = YES;
		deleting = YES;
		if([textView.text length]) {	// handle case of delete when there are no characters left to delete
			unichar c = [textView.text characterAtIndex:range.location];
			if(range.location && range.length == 1 && (c == ' ' || c == '/')) {
				--range.location;
				++range.length;
				deletedSpace = YES;
			}
		} else {
			return NO;
		}
	}
	
	NSString *newTextOrig = [textView.text stringByReplacingCharactersInRange:range withString:text];
	NSUInteger newTextLen = [newTextOrig length];

	if(haveFullNumber) {
		if(range.location <= numberLength) {	// <= account for space after last cc digit
			updateText = NO;
			flashForError = YES;
			goto eND;
		}
		// Test for delete of a space or /
		if(deleting) {
			formattedText = [newTextOrig substringToIndex:range.location];	// handles case of deletion interior to the string
			updateText = YES;
			goto eND;
		}
	
		if(newTextLen > [placeView.text length]) {
			flashForError = YES;
			goto eND;
		}

		formattedText = newTextOrig;
		
		NSRange monthRange = [placeView.text rangeOfString:@"MM"];
		if(newTextLen > monthRange.location) {
			if([newTextOrig characterAtIndex:monthRange.location] > '1') {
				// support short cut - we prepend a '0' for them
				formattedText = newTextOrig = [textView.text stringByReplacingCharactersInRange:range withString:[@"0" stringByAppendingString:text]];
				newTextLen = [newTextOrig length];
				NSLog(@"CHANGED IT");
			}
			if(newTextLen >= (monthRange.location + monthRange.length)) {
				month = [[newTextOrig substringWithRange:monthRange] integerValue];
				if(month < 1 || month > 12) {
					flashForError = YES;
					goto eND;
				}
			}
		}

		NSRange yearRange = [placeView.text rangeOfString:@"YY"];
		if(newTextLen > yearRange.location) {
			NSInteger proposedDecade = ([newTextOrig characterAtIndex:yearRange.location] - '0') * 10;
			NSInteger yearDecade = currentYear - (currentYear % 10);
			// NSLog(@"proposedDecade=%u yearDecade=%u", proposedDecade, yearDecade);
			if(proposedDecade < yearDecade) {
				flashForError = YES;
				goto eND;
			}
			if(newTextLen >= (yearRange.location + yearRange.length)) {
				year = [[newTextOrig substringWithRange:yearRange] integerValue];
				NSInteger diff = year - currentYear;
				if(diff < 0/* || diff > 10*/) {	// blogs on internet suggest some CCs have dates 50 yeras in the future
					flashForError = YES;
					goto eND;
				}
				if(creditCardImage != ccBackImage) {
#if __IPHONE_5_0 <= __IPHONE_OS_VERSION_MAX_ALLOWED
					UIViewAnimationOptions transType = type == AMEX ? UIViewAnimationOptionTransitionCrossDissolve : UIViewAnimationOptionTransitionFlipFromBottom;
#else
					UIViewAnimationOptions transType = type == AMEX ? UIViewAnimationOptionTransitionNone : UIViewAnimationOptionTransitionFlipFromLeft;
#endif
					[UIView transitionFromView:creditCardImage toView:ccBackImage duration:0.25f options:transType completion:NULL];
					creditCardImage = ccBackImage;
				}
			}
		}

		if(newTextLen == [placeView.text length]) {
			completelyDone = YES;
			NSRange ccvRange = [placeView.text rangeOfString:@"C"]; // first one
			ccvRange.length = type == AMEX ? 4 : 3;
			ccv = [[newTextOrig substringWithRange:ccvRange] integerValue];
		}
		
		updateText = YES;
	} else {
		NSString *newText = [newTextOrig stringByReplacingOccurrencesOfString:@" " withString:@""];
		NSUInteger len = [newText length];
		if(len < CC_LEN_FOR_TYPE) {
			updateText = YES;
			formattedText = newTextOrig;
			// NSLog(@"NEWLEN=%d CC_LEN=%d formattedText=%@", len, CC_LEN_FOR_TYPE, formattedText);
			type = InvalidCard;
		} else {
			type = [CreditCard ccType:newText];
			if(type == InvalidCard) {
				flashForError = YES;
				goto eND;
			}
			if(len == CC_LEN_FOR_TYPE) {
				placeView.text = [CreditCard promptStringForType:type justNumber:YES];
			}
			formattedText = [CreditCard formatForViewing:newText];
			NSUInteger lenForCard = [CreditCard lengthOfStringForType:type];

			// NSLog(@"FT=%@ len=%d", formattedText, lenForCard);
			
			if(len < lenForCard) {
				updateText = YES;
			} else
			if(len == lenForCard) {
				if([CreditCard isValidNumber:newText]) {
					if([CreditCard isLuhnValid:newText]) {
						numberLength = [CreditCard lengthOfFormattedStringForType:type];
						creditCardNum = newText;

						updateText = YES;
						scrollForward = YES;
						haveFullNumber = YES;
					} else {
						//flashForError = YES;
						
						NSString *oldText = [NSString stringWithString:ccText.text];
						NSUInteger oldShowOffset = placeView.showTextOffset;
					
						//ccText.editable = NO;
						ccText.text = @"  Recheck Number            ";	// center it (left padding) and push cursor offscreen
						placeView.showTextOffset = [placeView.text length];
						warningView.backgroundColor = [UIColor redColor];

						dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (long long)2*NSEC_PER_SEC), dispatch_get_main_queue(), ^
							{ 
								ccText.editable = YES;
								ccText.text = oldText;
								placeView.showTextOffset = oldShowOffset;
								warningView.backgroundColor = [UIColor clearColor];
							} );
					}
				} else {
					flashForError = YES;
				}				
			}
		}
		[self updateCCimageWithTransitionTime:0.25f];
	}
  eND:

	// Order of these blocks important!
	if(scrollForward) {
		[self scrollForward:YES];
		dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (long long)250*NSEC_PER_MSEC), dispatch_get_main_queue(), ^{ [textScroller flashScrollIndicators]; } );
	}
	if(updateText) {
		NSUInteger textViewLen = [formattedText length];
		NSUInteger formattedLen = [placeView.text length];
		placeView.showTextOffset = MIN(textViewLen, formattedLen);
	
		if((formattedLen > textViewLen) && !deleting) {
			unichar c = [placeView.text characterAtIndex:textViewLen];
			if(c == ' ') formattedText = [formattedText stringByAppendingString:@" "];
			else
			if(c == '/') formattedText = [formattedText stringByAppendingString:@"/"];
		}
		if(!deleting || haveFullNumber || deletedSpace) {
			textView.text = formattedText;
		} else {
			ret = YES; // let textView do it to preserve the cursor location. User updating an incorrect number
		}
		// NSLog(@"formattedText=%@ PLACEVIEW=%@ showTextOffset=%u offset=%@ ret=%d", formattedText, placeView.text, placeView.showTextOffset, NSStringFromCGRect(placeView.offset), ret );

	}
	if(flashForError) {
		[self flashScroller];
	}

	dispatch_async(dispatch_get_main_queue(), ^{ [self updateUI]; });
	//NSLog(@"placeholder=%@ text=%@", placeView.text, ccText.text);

	return ret;
}

- (void)scrollForward:(BOOL)animated
{
	CGFloat width = [self widthToLastGroup];

	CGRect frame = ccText.frame;
	frame.size.width = width + textScroller.frame.size.width;
	ccText.frame = frame;
	placeView.frame = frame;
	textScroller.contentSize = CGSizeMake(frame.size.width, textScroller.contentSize.height);

	placeView.text = [CreditCard promptStringForType:type justNumber:NO];
	textScroller.scrollEnabled = YES;
	[textScroller setContentOffset:CGPointMake(width, 0) animated:animated];
}

- (void)updateCCimageWithTransitionTime:(CGFloat)ttime
{
	if(creditCardImage.tag != type) {
		ccImage = [[UIImageView alloc] initWithImage:[CreditCard creditCardImage:type]];
		ccImage.frame = creditCardImage.frame;
		ccImage.tag = type;
		ccBackImage = [[UIImageView alloc] initWithImage:[CreditCard creditCardBackImage:type]];
		ccBackImage.frame = creditCardImage.frame;
		ccBackImage.tag = type;
		// UIViewAnimationOptionTransitionFlipFromLeft UIViewAnimationOptionTransitionFlipFromBottom

		[UIView transitionFromView:creditCardImage toView:ccImage duration:ttime options:UIViewAnimationOptionTransitionFlipFromLeft completion:NULL];

		//NSLog(@"GOT TO TYPE CHECK old=%d new=%d ccimage=%@ newImage=%@", imageType, type, creditCardImage, ccImage);
		creditCardImage = ccImage;
	}
}

- (BOOL)textViewShouldEndEditing:(UITextView *)textView
{
	return YES;
}

- (void)textViewDidEndEditing:(UITextView *)textView
{
}

- (void)textViewDidChangeSelection:(UITextView *)textView
{
	if(haveFullNumber) {
		//textView.selectedRange = NSMakeRange([textView.text length], 0);
	}
}

- (void)textViewDidChange:(UITextView *)textView
{
}

- (void)flashScroller
{
	warningView.backgroundColor = [UIColor redColor];
	dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (long long)250*NSEC_PER_MSEC), dispatch_get_main_queue(), ^{ warningView.backgroundColor = [UIColor clearColor]; } );
}

- (CGFloat)widthToLastGroup
{
	NSUInteger oldOffset = placeView.showTextOffset;
	NSUInteger offsetToLastGroup = [CreditCard lengthOfFormattedStringTilLastGroupForType:type];
	placeView.showTextOffset = offsetToLastGroup;
	CGFloat width = [placeView widthToOffset];
	placeView.showTextOffset = oldOffset;
	return width;
}

- (void)updateUI
{	
	if(creditCard) {
		[self editCard:nil];
	} else {
		BOOL enable = NO;
		if(creditCard) {
			enable |= month != [[creditCard month] integerValue];
			enable |= year != [[creditCard year] integerValue];
		} else {
			enable = completelyDone;
		}
		self.navigationItem.rightBarButtonItem.enabled = enable;
	}
//NSLog(@"ADDR_ID=%d completelyDone=%d", self.addressID, completelyDone);

}
		
- (IBAction)saveAction:(id)sender
{
	NSLog(@"Number = %@ month=%d year=%d ccv=%d", creditCardNum, month, year, ccv);
	//	[ccText resignFirstResponder];
}

// Contacts category uses didDismissWithButtonIndex: and the first two enum values (this comment probably out of date)

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
	BOOL quit = NO;

	switch(actionSheet.tag) {
#if 0 // our code
	case saveSuccessSheet:
		quit = YES;
		break;

	case saveFailSheet:
		// if(buttonIndex == actionSheet.cancelButtonIndex) ; else // has no affect
		if(buttonIndex == actionSheet.destructiveButtonIndex) {
			quit = YES;
		} 
		break;
	
	case reallyDeleteSheet:
		if(buttonIndex == actionSheet.destructiveButtonIndex) {
			LTCreditCardFetcher *fetcher = [LTCreditCardFetcher new];
			fetcher.tag = kCreditCardSetter;
			fetcher.creditCard = creditCard;
			fetcher.action = jsonDelete;
			NSString *msg = @"Deleting CreditCard…";
			[self runOperation:fetcher withMsg:msg];
			[self showActivityWithMessage:msg];

			[self deleteSavedProfiles];
		}	
		break;
#endif
	case reallyQuitSheet:
		if(buttonIndex == actionSheet.destructiveButtonIndex) {
			quit = YES;
		}
		break;

	default:
		return;
	}

	if(quit) {
		[self.navigationController popViewControllerAnimated:YES];
	}
}

- (void)finishedRefresh
{
	[self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)editCard:(id)sender
{
	NSInteger tag = 0;
	NSString *title;
	BOOL enabled = NO;
	BOOL update = YES;
	if(sender) {
		title = @"Update";
		type = [creditCard ccType];
		ccText.text = [creditCard editString];
		placeView.showTextOffset = [ccText.text length];
		//placeView.text = [CreditCard promptStringForType:[creditCard ccType] justNumber:NO];
		
		[self updateCCimageWithTransitionTime:0];
		[self scrollForward:NO];
		textScroller.scrollEnabled = NO;
		haveFullNumber = YES;

		[dummyTextView becomeFirstResponder];
	} else
	if(creditCard) {
		//NSUInteger oldAddressID = [[creditCard addrID] integerValue];
		BOOL addrChanged = NO; // (self.addressID != oldAddressID);
		tag = self.navigationItem.rightBarButtonItem.tag;
		
		if(addrChanged) {
			if(tag == 0) return;
			title = @"Update";
			tag = 0;
		} else {
			if(tag == DELETE_TAG) return;
			tag = DELETE_TAG;
			title = @"Delete";
		}
	
		enabled = YES;
		update = NO;
	} else {
		title = @"Add";
	}
	//self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave target:self action:@selector(saveAction:)];
	UIBarButtonItem *item = [[UIBarButtonItem alloc] initWithTitle:title style:UIBarButtonItemStyleDone target:self action:@selector(saveAction:)];
	item.tag = tag;
	self.navigationItem.rightBarButtonItem = item;
	self.navigationItem.rightBarButtonItem.enabled = enabled;
	
	if(update) dispatch_async(dispatch_get_main_queue(), ^{ [self updateUI]; });
}

@end

@implementation CreditCardController (UIScrollViewDelegate)

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
	CGFloat x = scrollView.contentOffset.x;
	CGFloat xOff = x - oldX;
	//NSLog(@"xOFF=%f decel=%d", xOff, decelerate);
	if(decelerate) {
		[scrollView setContentOffset:CGPointMake(xOff>0 ? [self widthToLastGroup] : 0, 0) animated:YES];
	}
}

@end
