#import <Foundation/Foundation.h>
#import "StringDetector.h"
#import "FontCollection.h"
#import "RenderingState.h"
#import "Selection.h"

@interface Scanner : NSObject <StringDetectorDelegate> {
	NSURL *documentURL;
	NSString *keyword;
	CGPDFDocumentRef pdfDocument;
	CGPDFOperatorTableRef operatorTable;
	StringDetector *stringDetector;
	FontCollection *fontCollection;
	RenderingStateStack *renderingStateStack;
	Selection *currentSelection;
	NSMutableArray *selections;
}

/* Initialize with a file path */
- (id)initWithContentsOfFile:(NSString *)path;

/* Initialize with a PDF document */
- (id)initWithDocument:(CGPDFDocumentRef)document;

/* Start scanning (synchronous) */
- (void)scanPage:(NSUInteger)page;

@property (nonatomic, retain) NSMutableArray *selections;
@property (nonatomic, retain) RenderingStateStack *renderingStateStack;
@property (nonatomic, retain) FontCollection *fontCollection;
@property (nonatomic, retain) StringDetector *stringDetector;
@property (nonatomic, retain) NSString *keyword;
@end
