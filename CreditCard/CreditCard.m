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

#import "CreditCard.h"

// See: http://www.regular-expressions.info/creditcard.html
#define VISA				@"^4[0-9]{15}?"						// VISA 16
#define MC					@"^5[1-5][0-9]{14}$"				// MC 16
#define AMEX_REG			@"^3[47][0-9]{13}$"					// AMEX 15
#define DISCOVER			@"^6(?:011|5[0-9]{2})[0-9]{12}$"	// Discover 16
#define DINERS_CLUB			@"^3(?:0[0-5]|[68][0-9])[0-9]{11}$"	// DinersClub 14 // 38812345678901

#define AMEX_REG_TYPE		@"^3[47][0-9]{2}$"					// AMEX 15
#define DINERS_CLUB_TYPE	@"^3(?:0[0-5]|[68][0-9])[0-9]$"		// DinersClub 14 // 38812345678901
#define VISA_TYPE			@"^4[0-9]{3}?"						// VISA 16
#define MC_TYPE				@"^5[1-5][0-9]{2}$"					// MC 16
#define DISCOVER_TYPE		@"^6(?:011|5[0-9]{2})$"				// Discover 16

#define		kID					@"id"
#define		kCCid				@"id"				// key for record (NSNumber)
#define		kCCnumber			@"card_number"		// key for obfuscated number (string)
#define		kCCtype				@"card_type"		// one of four strings: Master Card, Visa, American Express, Diners Club, and Discover
#define		kCCexpir			@"card_expiration"	// key for expDate in YYYY-MM format (string)
#define		kCCccv				@"card_cvv"			// key for CCV (NSNumber)
#define		kCCaddrID			@"address_id"		// key for Address ID (NSNumber)
#define		kCCdefault			@"default"			// key for is this the default address (NSNumber bool)


static NSRegularExpression *visaReg;
static NSRegularExpression *mcReg;
static NSRegularExpression *amexReg;
static NSRegularExpression *discoverReg;
static NSRegularExpression *dinersClubReg;

static NSRegularExpression *visaTypeReg;
static NSRegularExpression *mcTypeReg;
static NSRegularExpression *amexTypeReg;
static NSRegularExpression *discoverTypeReg;
static NSRegularExpression *dinersClubTypeReg;

@interface CreditCard ()

+ (NSString *)cleanNumber:(NSString *)str;

- (NSString *)obscuredNumber;
- (UIImage *)creditCardImage;

@end

@implementation CreditCard
{
	NSMutableDictionary *privateDict;
}
@synthesize dictionary;

+ (void)initialize
{
	if(self == [CreditCard class]) {
		__autoreleasing NSError *error;
		visaReg				= [NSRegularExpression regularExpressionWithPattern:VISA options:0 error:&error];
		mcReg				= [NSRegularExpression regularExpressionWithPattern:MC options:0 error:&error];
		amexReg				= [NSRegularExpression regularExpressionWithPattern:AMEX_REG options:0 error:&error];
		discoverReg			= [NSRegularExpression regularExpressionWithPattern:DISCOVER options:0 error:&error];
		dinersClubReg		= [NSRegularExpression regularExpressionWithPattern:DINERS_CLUB options:0 error:&error];
		
		visaTypeReg			= [NSRegularExpression regularExpressionWithPattern:VISA_TYPE options:0 error:&error];
		mcTypeReg			= [NSRegularExpression regularExpressionWithPattern:MC_TYPE options:0 error:&error];
		amexTypeReg			= [NSRegularExpression regularExpressionWithPattern:AMEX_REG_TYPE options:0 error:&error];
		discoverTypeReg		= [NSRegularExpression regularExpressionWithPattern:DISCOVER_TYPE options:0 error:&error];
		dinersClubTypeReg	= [NSRegularExpression regularExpressionWithPattern:DINERS_CLUB_TYPE options:0 error:&error];		
	}
}

+ (NSString *)cleanNumber:(NSString *)str
{
	return [str stringByReplacingOccurrencesOfString:@" " withString:@""];
}

// http://www.regular-expressions.info/creditcard.html
+ (creditCardType)ccType:(NSString *)proposedNumber
{
	NSRegularExpression *reg;

	if([proposedNumber length] < CC_LEN_FOR_TYPE) return InvalidCard;

	for(NSUInteger idx = 0; idx < InvalidCard; ++idx) {
		switch(idx) {
		case Visa:
			reg = visaTypeReg;
			break;
		case MasterCard:
			reg = mcTypeReg;
			break;
		case AMEX:
			reg = amexTypeReg;
			break;
		case Discover:
			reg = discoverTypeReg;
			break;
		case DinersClub:
			reg = dinersClubTypeReg;
			break;
		}
		NSUInteger matches = [reg numberOfMatchesInString:proposedNumber options:0 range:NSMakeRange(0, CC_LEN_FOR_TYPE)];
		if(matches == 1) return idx;
	}
	return InvalidCard;
}

// http://www.regular-expressions.info/creditcard.html
+ (BOOL)isValidNumber:(NSString *)number
{
	NSRegularExpression *reg;
	BOOL ret = NO;

	switch([CreditCard ccType:number]) {
	case Visa:
		reg = visaReg;
		break;
	case MasterCard:
		reg = mcReg;
		break;
	case AMEX:
		reg = amexReg;
		break;
	case Discover:
		reg = discoverReg;
		break;
	case DinersClub:
		reg = dinersClubReg;
		break;
		
	default:
		break;
	}
	if(reg) {
		NSUInteger matches = [reg numberOfMatchesInString:number options:0 range:NSMakeRange(0, [number length])];
		ret = matches == 1 ? YES : NO;
	}

	return ret;
}

// See: http://www.brainjar.com/js/validation/default2.asp
+ (BOOL)isLuhnValid:(NSString *)number
{
	NSString *baseNumber = [number stringByReplacingOccurrencesOfString:@" " withString:@""];
	NSUInteger total = 0;
	
	NSUInteger len = [baseNumber length];
	for(NSUInteger i=len; i > 0; ) {
		BOOL odd = (len-i)&1;
		--i;
		unichar c = [baseNumber characterAtIndex:i];
		if(c < '0' || c > '9') continue;
		c -= '0';
		if(odd) c *= 2;
		if(c >= 10) {
			total += 1;
			c -= 10;
		}
		total += c;
	}
	// NSLog(@"LUHN=%d for %@", total, baseNumber);

	return (total%10) == 0 ? YES : NO;
}


+ (NSString *)formatForViewing:(NSString *)enteredNumber
{
	NSString *cleaned = [CreditCard cleanNumber:enteredNumber];
	NSInteger len = [cleaned length];
	
	if(len <= CC_LEN_FOR_TYPE) return cleaned;

	NSRange r2; r2.location = NSNotFound;
	NSRange r3; r3.location = NSNotFound;
	NSRange r4; r4.location = NSNotFound;
	NSMutableArray *gaps = [NSMutableArray arrayWithObjects:@"", @"", @"", nil];

	NSUInteger segmentLengths[3] = { 0, 0, 0 };

	switch([CreditCard ccType:enteredNumber]) {
	case Visa:
	case MasterCard:
	case Discover:		// { 4-4-4-4}
		segmentLengths[0] = 4;
		segmentLengths[1] = 4;
		segmentLengths[2] = 4;
		break;
	case AMEX:			// {4-6-5}
		segmentLengths[0] = 6;
		segmentLengths[1] = 5;
		break;
	case DinersClub:	// {4-6-4}
		segmentLengths[0] = 6;
		segmentLengths[1] = 4;
		break;
	default:
		return enteredNumber;
	}

	len -= CC_LEN_FOR_TYPE;
	NSRange *r[3] = { &r2, &r3, &r4 };
	NSUInteger totalLen = CC_LEN_FOR_TYPE;
	for(NSUInteger idx=0; idx<3; ++idx) {
		NSInteger segLen = segmentLengths[idx];
		if(!segLen) break;

		r[idx]->location = totalLen;
		r[idx]->length = len >= segLen ? segLen : len;
		totalLen += segLen;
		len -= segLen;
		[gaps replaceObjectAtIndex:idx withObject:@" "];
		
		if(len <= 0) break;
	}
	//NSLog(@"Ranges: %@ %@ %@", NSStringFromRange(r2), NSStringFromRange(r3), NSStringFromRange(r4) );
 
	NSString *segment1 = [enteredNumber substringWithRange:NSMakeRange(0, CC_LEN_FOR_TYPE)];
	NSString *segment2 = r2.location == NSNotFound ? @"" : [enteredNumber substringWithRange:r2];
	NSString *segment3 = r3.location == NSNotFound ? @"" : [enteredNumber substringWithRange:r3];
	NSString *segment4 = r4.location == NSNotFound ? @"" : [enteredNumber substringWithRange:r4];

	NSString *ret = [NSString stringWithFormat:@"%@%@%@%@%@%@%@", 
		segment1, [gaps objectAtIndex:0],
		segment2, [gaps objectAtIndex:1],
		segment3, [gaps objectAtIndex:2],
		segment4 ];

	return ret;
}

+ (NSUInteger)lengthOfStringForType:(creditCardType)type
{
	NSUInteger idx;
	
	switch(type) {
	case Visa:
	case MasterCard:
	case Discover:		// { 4-4-4-4}
		idx = 16;
		break;
	case AMEX:			// {4-6-5}
		idx = 15;
		break;
	case DinersClub:	// {4-6-4}
		idx = 14;
		break;
	default:
		idx = 0;
	}
	return idx;
}

+ (NSUInteger)lengthOfFormattedStringForType:(creditCardType)type
{
	NSUInteger idx;
	
	switch(type) {
	case Visa:
	case MasterCard:
	case Discover:		// { 4-4-4-4}
		idx = 16 + 3;
		break;
	case AMEX:			// {4-6-5}
		idx = 15 + 2;
		break;
	case DinersClub:	// {4-6-4}
		idx = 14 + 2;
		break;
	default:
		idx = 0;
	}
	return idx;
}

+ (NSUInteger)lengthOfFormattedStringTilLastGroupForType:(creditCardType)type
{
	NSUInteger idx;
	
	switch(type) {
	case Visa:
	case MasterCard:
	case Discover:		// { 4-4-4-4}
		idx = 16 + 3 - 4;
		break;
	case AMEX:			// {4-6-5}
		idx = 15 + 2 - 5;
		break;
	case DinersClub:	// {4-6-4}
		idx = 14 + 2 - 4;
		break;
	default:
		idx = 0;
	}
	return idx;
}

+ (NSString *)ccvFormat:(creditCardType)type
{
	return type == AMEX ? @"%04.4u" : @"%03.3u";
}

+ (NSString *)promptStringForType:(creditCardType)type justNumber:(BOOL)justNumber
{
	NSString *number;
	NSString *additions;

	switch(type) {
	case Visa:
	case MasterCard:
	case Discover:		// { 4-4-4-4}
		number = @"XXXX XXXX XXXX XXXX";
		additions = @" MM/YY CCV";
		break;
	case AMEX:			// {4-6-5}
		number = @"XXXX XXXXXX XXXXX";
		additions = @" MM/YY CIDV";
		break;
	case DinersClub:	// {4-6-4}
		number = @"XXXX XXXXXX XXXX";
		additions = @" MM/YY CCV";
		break;
	default:
		break;
	}
	return justNumber ? number : [number stringByAppendingString:additions];
}
- (NSString *)editString
{
	NSString *format;

	switch([self ccType]) {
	case Visa:
	case MasterCard:
	case Discover:		// { 4-4-4-4}
		format = @"XXXX XXXX XXXX %@ %@/%@";
		break;
	case AMEX:			// {4-6-5}
		format = @"XXXX XXXXXX X%@ %@/%@";
		break;
	case DinersClub:	// {4-6-4}
		format = @"XXXX XXXXXX %@ %@/%@";
		break;
	default:
		break;
	}
	NSString *number = [[self.dictionary objectForKey:@"number"] stringByReplacingOccurrencesOfString:@"X" withString:@""];
	NSString *month	= [self month];
	NSString *year	= [self year];
	NSString *retStr = [NSString stringWithFormat:format, number, month, year];
NSLog(@"dict=%@ str=%@", self.dictionary, retStr);
	return retStr;
}
- (NSString *)month
{
	NSString *expir = [self.dictionary objectForKey:kCCexpir];
	assert([expir length] == 7);
	NSString *month	= [expir substringFromIndex:5];
	return month;
}
- (NSString *)year
{
	NSString *expir = [self.dictionary objectForKey:kCCexpir];
	assert([expir length] == 7);
	NSString *year	= [expir substringWithRange:NSMakeRange(2, 2)];
	return year;
}

+ (UIImage *)creditCardImage:(creditCardType)type
{
	NSString *name;
	
	switch(type) {
	case Visa:
		name = @"visa2.png";
		break;
	case MasterCard:
		name = @"masterCard2.png";
		break;
	case AMEX:
		name = @"amex2.png";
		break;
	case Discover:
		name = @"discover2.png";
		break;
	case DinersClub:
		name = @"dinersClub2.png";
		break;
	default:
		name = @"unknownCC2.png";
	}	
	return [UIImage imageNamed:name];
}

+ (UIImage *)creditCardBackImage:(creditCardType)type
{
	NSString *name;
	
	switch(type) {
	case AMEX:
		name = @"amexBack2.png";
		break;
	default:
		name = @"ccBack2.png";
	}	
	return [UIImage imageNamed:name];
}

#pragma mark Object Methods

- (id)initWithDictionary:(NSDictionary *)dict
{
	if((self = [super init])) {
		privateDict = [NSMutableDictionary dictionaryWithDictionary:dict];
	}
	return self;
}

- (creditCardType)ccType
{
	NSString *type = [privateDict objectForKey:kCCtype];

	     if([type isEqualToString:@"Masters Card"])		return MasterCard;
	else if([type isEqualToString:@"Visa"])				return Visa;
	else if([type isEqualToString:@"American Express"])	return AMEX;
	else if([type isEqualToString:@"Diners Club"])		return DinersClub;
	else if([type isEqualToString:@"Discover"])			return Discover;

	return InvalidCard;
}

- (NSString *)addrID
{
	return [privateDict objectForKey:kCCaddrID];
}

- (NSString *)obscuredNumber
{
	NSString *number;

	switch([self ccType]) {
	case Visa:
	case MasterCard:
	case Discover:		// { 4-4-4-4}
		number = @"XXXX XXXX XXXX %@";
		break;
	case AMEX:			// {4-6-5}
		number = @"XXXX XXXXXX %@";
		break;
	case DinersClub:	// {4-6-4}
		number = @"XXXX XXXXXX %@";
		break;
	default:
		break;
	}

	return [NSString stringWithFormat:number, [self last4digits]];	// 5 digits for AMEX
}

- (NSString *)last4digits
{
	NSString *str = [privateDict objectForKey:kCCnumber];
	str = [str stringByReplacingOccurrencesOfString:@"X" withString:@""];
	return str;
}

- (UIImage *)creditCardImage
{
	return [CreditCard creditCardImage:[self ccType]];
}

#define RIGHT_EDGE(a) (a.origin.x+a.size.width)
#define BOTTOM_EDGE(a) (a.origin.y+a.size.height)

#define SCREEN_WIDTH 320
#define kMoreHeight 36
#define kScrollingX 10
#define kScrollingY 4
#define kFinalX	96

// Billing address in our app goes above the credit card
#define kScrollRect(x)			CGRectMake(0, 0, SCREEN_WIDTH, (x)-kMoreHeight)
#define kBillingLabelRect		CGRectMake(kScrollingX, kScrollingY+4, kFinalX-kScrollingX, 14)
#define kBillingCCImageRect		CGRectMake(RIGHT_EDGE(kBillingLabelRect), kScrollingY+6, 16, 11)	// Images are 32 x 22
#define kBillingCCNumberRect	CGRectMake(RIGHT_EDGE(kBillingCCImageRect)+8, kScrollingY+4, SCREEN_WIDTH-(RIGHT_EDGE(kBillingCCImageRect)+8)-4, 14)

#define kBillingMimimalRect		CGRectMake(kScrollingX, 0, SCREEN_WIDTH, kScrollingY*3)			// special use when showing credit card in the editor
#define kCCheight				72	// Billing (CreditCard)


- (UIView *)viewForItem
{
	UIView *contentView = [[UIView alloc] initWithFrame:kScrollRect(kCCheight)];
	{	// Using Label
		UILabel *label = [[UILabel alloc] initWithFrame:kBillingLabelRect];
		label.text = @"Credit Card:";
		label.font = [UIFont systemFontOfSize:12];
		label.textColor = [UIColor greenColor]; // [UIColor colorWithHex:0xa8a8a8];
		label.textAlignment = NSTextAlignmentLeft;
		label.backgroundColor = [UIColor clearColor];
		label.tag = 1;
		[contentView addSubview:label];
	}
	{	// Credit Card Image
		UIImageView *image = [[UIImageView alloc] initWithImage:[self creditCardImage]];
		image.frame = kBillingCCImageRect;
		image.contentMode = UIViewContentModeScaleAspectFill;
		image.userInteractionEnabled = NO;
		image.opaque = YES;
		image.clipsToBounds = YES;
		image.autoresizesSubviews = NO;
		
		[contentView addSubview:image];
	}
	{	// Profile Name
		UILabel *label= [[UILabel alloc] initWithFrame:kBillingCCNumberRect];
		label.text = [self obscuredNumber];
		label.font = [UIFont systemFontOfSize:14];
		label.textColor = [UIColor greenColor]; // [UIColor colorWithHex:0xa8a8a8];
		label.textAlignment = NSTextAlignmentLeft;
		label.backgroundColor = [UIColor clearColor];
		label.tag = 2;
		
		[contentView addSubview:label];
	}
	return contentView;
}

- (void)resizeView:(UIView *)view
{
	CGFloat leftFudge, rightEdge;
	{
		UILabel *l = (UILabel *)[view viewWithTag:1];
		assert(l);
		CGSize oldSize = l.frame.size;
		CGSize newSize = [l sizeThatFits:oldSize];
		leftFudge = oldSize.width - newSize.width;
	}

	{
		UILabel *l = (UILabel *)[view viewWithTag:2];
		assert(l);
		CGSize oldSize = l.frame.size;
		CGSize newSize = [l sizeThatFits:oldSize];
		//rightFudge = oldSize.width - newSize.width;
		rightEdge = l.frame.origin.x + newSize.width + leftFudge;
	}

	CGRect frame = kBillingMimimalRect;
	frame.size.width = rightEdge;
	view.frame = frame;
}

- (NSString *)description	// also used for comparison purposes
{
	NSMutableString *str = [NSMutableString stringWithCapacity:256];

	[str appendFormat:@"Card ID=\"%@\"\n", [privateDict objectForKey:kID]];
	[str appendFormat:@"  card_type:  %@\n", [privateDict objectForKey:kCCtype]];
	[str appendFormat:@"  card_num   :%@\n", [privateDict objectForKey:kCCnumber]];
	[str appendFormat:@"  card_expir :%@\n", [privateDict objectForKey:kCCexpir]];
	[str appendFormat:@"  card_cvv:   %@\n", [privateDict objectForKey:kCCccv]];
	[str appendFormat:@"  address_id: %@\n", [privateDict objectForKey:kCCaddrID]];
	[str appendFormat:@"  default:    %@\n", [privateDict objectForKey:kCCdefault]];

	return str;
}

@end
