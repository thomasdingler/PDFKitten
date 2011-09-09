#import <Foundation/Foundation.h>


typedef enum
{
    CMapTypeUnknown = 0,
    CMapTypeChar,
    CMapTypeRange   
    
} CMapType;



@interface CMap : NSObject {
	NSMutableArray *offsets;
}

/* Initialize with PDF stream containing a CMap */
- (id)initWithPDFStream:(CGPDFStreamRef)stream;

/* Unicode mapping for character ID */
- (unichar)characterWithCID:(unichar)cid;

- (NSString*) characterRangeInText: (NSString*) text 
                      detectedType: (CMapType*) outType;


- (void) extractOffsetsFromMapTypeChar:(NSString*) characterRange;
- (void) extractOffsetsFromMapTypeRange:(NSString*) characterRange;

@end
