#import "CMap.h"
#import "TrueTypeFont.h"

@implementation CMap


- (id)initWithPDFStream:(CGPDFStreamRef)stream
{
	if ((self = [super init]))
	{
		NSData *data = (NSData *) CGPDFStreamCopyData(stream, nil);
		NSString *text = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
				
        CMapType cmapType = CMapTypeUnknown;
        
        NSString *characterRange = [self characterRangeInText:text 
                                                 detectedType:&cmapType];
        
        if ((characterRange == nil) || (cmapType == CMapTypeUnknown))
        {
            return self;
        }
        
        offsets = [[NSMutableArray alloc] init];
        
        switch (cmapType) {
            case CMapTypeChar:
                [self extractOffsetsFromMapTypeChar:characterRange];
                break;
            case CMapTypeRange:
                [self extractOffsetsFromMapTypeRange:characterRange];
                break;
               
            default:
                break;
        }
        
        [data release];
        [text release];
	}
	return self;
}


- (void) extractOffsetsFromMapTypeChar:(NSString*) characterRange
{
    NSCharacterSet *newLineSet = [NSCharacterSet newlineCharacterSet];
    NSCharacterSet *tagSet = [NSCharacterSet characterSetWithCharactersInString:@"<>"];
    NSString *separatorString = @"> <";
    
    NSScanner *rangeScanner = [NSScanner scannerWithString:characterRange];
    while (![rangeScanner isAtEnd])
    {
        NSString *line = nil;
        [rangeScanner scanUpToCharactersFromSet:newLineSet intoString:&line];
        line = [line stringByTrimmingCharactersInSet:tagSet];
        NSArray *parts = [line componentsSeparatedByString:separatorString];
        if ([parts count] < 2) continue;
        
        NSUInteger pos, offset;
        NSScanner *scanner = [NSScanner scannerWithString:[parts objectAtIndex:0]];
        [scanner scanHexInt:&pos];
                
        scanner = [NSScanner scannerWithString:[parts objectAtIndex:1]];
        [scanner scanHexInt:&offset];
        
        NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:
                              [NSNumber numberWithInt:pos],	@"First",
                              [NSNumber numberWithInt:pos],	@"Last",
                              [NSNumber numberWithInt:offset],	@"Offset",
                              nil];
        
        [offsets addObject:dict];
    }
}


- (void) extractOffsetsFromMapTypeRange:(NSString*) characterRange
{
    NSCharacterSet *newLineSet = [NSCharacterSet newlineCharacterSet];
    NSCharacterSet *tagSet = [NSCharacterSet characterSetWithCharactersInString:@"<>"];
    NSString *separatorString = @"><";
    
    NSScanner *rangeScanner = [NSScanner scannerWithString:characterRange];
    while (![rangeScanner isAtEnd])
    {
        NSString *line = nil;
        [rangeScanner scanUpToCharactersFromSet:newLineSet intoString:&line];
        line = [line stringByTrimmingCharactersInSet:tagSet];
        NSArray *parts = [line componentsSeparatedByString:separatorString];
        if ([parts count] < 3) continue;
        
        NSUInteger from, to, offset;
        NSScanner *scanner = [NSScanner scannerWithString:[parts objectAtIndex:0]];
        [scanner scanHexInt:&from];
        
        scanner = [NSScanner scannerWithString:[parts objectAtIndex:1]];
        [scanner scanHexInt:&to];
        
        scanner = [NSScanner scannerWithString:[parts objectAtIndex:2]];
        [scanner scanHexInt:&offset];
        
        NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:
                              [NSNumber numberWithInt:from],	@"First",
                              [NSNumber numberWithInt:to],		@"Last",
                              [NSNumber numberWithInt:offset],	@"Offset",
                              nil];
        
        [offsets addObject:dict];
    }
}




- (NSString*) characterRangeInText:(NSString*) text
                      detectedType:(CMapType *)outType
{
    NSString *characterRange = nil;
    CMapType mapType = CMapTypeRange;

    NSScanner *scanner = [NSScanner scannerWithString:text];
    [scanner scanUpToString:@"beginbfrange" intoString:nil];
    [scanner scanUpToString:@"<" intoString:nil];
    [scanner scanUpToString:@"endbfrange" intoString:&characterRange];
    if (characterRange == nil)
    {
        /* try beginbfchar+endbfchar */
        scanner = [NSScanner scannerWithString:text];
        [scanner scanUpToString:@"beginbfchar" intoString:nil];
        [scanner scanUpToString:@"<" intoString:nil];
        [scanner scanUpToString:@"endbfchar" intoString:&characterRange];
        
        mapType = CMapTypeChar;
    }
    
    if (characterRange == nil)
    {
        NSLog(@"CMAP: Font not found (endbfrange|endbfchar)");
        return nil;
    }
    
    if (outType != NULL)
    {
        /* set map type */
        *outType = mapType;
    }

    return characterRange;
}

- (NSDictionary *)rangeWithCharacter:(unichar)character
{
	for (NSDictionary *dict in offsets)
	{
		if ([[dict objectForKey:@"First"] intValue] <= character && [[dict objectForKey:@"Last"] intValue] >= character)
		{
			return dict;
		}
	}
	return nil;
}

- (unichar)characterWithCID:(unichar)cid
{
	NSDictionary *dict = [self rangeWithCharacter:cid];
	NSUInteger internalOffset = cid - [[dict objectForKey:@"First"] intValue];
	return [[dict objectForKey:@"Offset"] intValue] + internalOffset;
}

- (void)dealloc
{
	[offsets release];
	[super dealloc];
}

@end
