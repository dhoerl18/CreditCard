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

#import "PlaceHolderTextView.h"


@implementation PlaceHolderTextView
{
	// BOOL recomputeOffset;
}
@synthesize text;
@synthesize font;
@synthesize showTextOffset;
@synthesize offset;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)setText:(NSString *)newText
{
	if(newText == text) return;

	BOOL animate = (text && [newText length] > [text length]);
	text = newText;
	
	if(animate) {
		self.alpha = 0.0;
		[UIView animateWithDuration:0.25 animations:^{ self.alpha = 1; } ];
	}
	[self setNeedsDisplay];
}

- (void)setShowTextOffset:(NSUInteger)newOffset
{
	showTextOffset = newOffset;
	[self setNeedsDisplay];
}

- (void)drawRect:(CGRect)rect
{
	CGRect r = offset;
	
	// We know that this strings begins with a series of 'X' and ' ' characters before using others
	// So we render the X's as boxes and the others as real characters

	NSString *clearText = [text substringToIndex:showTextOffset];
	NSString *grayText = [text substringWithRange:NSMakeRange(showTextOffset, [text length] - showTextOffset)];
	
    CGContextRef context = UIGraphicsGetCurrentContext();

	CGColorRef clearColor = [[UIColor clearColor] CGColor];
	CGContextSetStrokeColorWithColor(context, clearColor);
	CGContextSetFillColorWithColor(context, clearColor);
	CGContextFillRect(context, rect);

#if 0	
	if(!recomputeOffset) {
		recomputeOffset = YES;
		offset.size.width = [@"1234" drawAtPoint:offset.origin withFont:font].width / 4.0f;
		NSLog(@"NEW WIDTH=%f", offset.size.width);
	}
#endif

//NSLog(@"PLACE: rect=%@", NSStringFromCGRect(self.frame));	
//NSLog(@"origin: origin=%@", NSStringFromCGPoint(r.origin));	
	if([clearText length]) {
//NSLog(@"ORIGIN=%@ DRAWSIZE=%@ SIZESIZE=%@", NSStringFromCGPoint(offset.origin), NSStringFromCGSize([clearText drawAtPoint:offset.origin withFont:font]), NSStringFromCGSize([clearText sizeWithFont:font]) );
		r.origin.x += [clearText drawAtPoint:offset.origin withFont:font].width;
	}
//NSLog(@"origin: origin=%@", NSStringFromCGPoint(r.origin));	
	
	NSRange charsToDraw = NSMakeRange(0, [grayText length]);
	if(charsToDraw.length) {
		CGColorRef grayColor = [[UIColor TEXT_COLOR] CGColor];
		CGContextSetStrokeColorWithColor(context, grayColor);
		CGContextSetFillColorWithColor(context, grayColor);

		NSUInteger idx;
		for(idx = 0; idx < charsToDraw.length; ++idx) {
//NSLog(@"origin: origin=%@", NSStringFromCGPoint(r.origin));	
			unichar c = [grayText characterAtIndex:idx];
			if(c == ' ') {
				r.origin.x += offset.size.width;
				continue;
			}
			if(c == 'X') {
#ifdef LED_FONT
				CGRect box = CGRectInset(r, 2, 1);
				box.size.height -= 3; // visual appeal
#else
				CGRect box = CGRectInset(r, 3, 3);
				box.size.height -= 2; // visual appeal
#endif
				//CGContextStrokeRectWithWidth(context, box, 2);
#if 0
				CGContextFillRect(context, box);
#else
				const CGFloat radius = 3;
				CGContextBeginPath(context);
				CGContextMoveToPoint(context, CGRectGetMinX(box) + radius, CGRectGetMinY(box));
				CGContextAddArc(context, CGRectGetMaxX(box) - radius, CGRectGetMinY(box) + radius, radius, (CGFloat)(3 * M_PI / 2), 0, 0);
				CGContextAddArc(context, CGRectGetMaxX(box) - radius, CGRectGetMaxY(box) - radius, radius, 0, (CGFloat)(M_PI / 2), 0);
				CGContextAddArc(context, CGRectGetMinX(box) + radius, CGRectGetMaxY(box) - radius, radius, (CGFloat)(M_PI / 2), (CGFloat)M_PI, 0);
				CGContextAddArc(context, CGRectGetMinX(box) + radius, CGRectGetMinY(box) + radius, radius, (CGFloat)(M_PI), (CGFloat)(3 * M_PI / 2), 0);	
				CGContextClosePath(context);
				CGContextFillPath(context);
#endif
				r.origin.x += offset.size.width;
				continue;
			}
			// something else!
			break;
		}
		charsToDraw.location += idx;
		charsToDraw.length -= idx;
		if(charsToDraw.length) {
			[[grayText substringWithRange:charsToDraw] drawAtPoint:r.origin withFont:font];
		}
	}
}

- (CGFloat)widthToOffset
{
	NSString *startText = [text substringToIndex:showTextOffset];
	return [startText sizeWithFont:font].width;
}

- (CGFloat)widthfromOffset
{
	NSString *endText = [text substringWithRange:NSMakeRange(showTextOffset, [text length] - showTextOffset)];
	return [endText sizeWithFont:font].width;

}

@end
