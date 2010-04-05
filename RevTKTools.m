#import <Foundation/Foundation.h>



static NSString *kRTKZigFile = @"rtk1_data";
static NSString *kRTKZigFileType = @"utf8";
static NSString *kRTK3File = @"rtk3_keywords";
static NSString *kRTK3FileType = @"txt";
static NSString *kRTKKanjiDic2File = @"kanjidic2";
static NSString *kRTKKanjiDic2FileType = @"xml";

static NSString *kRTKSelectHeisigKanjiXPath = @"//kanjidic2/character[dic_number/dic_ref[@dr_type='heisig']]";
static NSString *kRTKSelectHeisigKanji3XPath = @"//kanjidic2/character[dic_number/dic_ref[@dr_type='heisig'] >= 2043]";
static NSString *kRTKSelectHeisigFrameXPath = @"dic_number/dic_ref[@dr_type='heisig']/text()";
static NSString *kRTKSelectOnYomiXPath = @"reading_meaning/rmgroup/reading[@r_type='ja_on']/text()";
static NSString *kRTKSelectStrokeCountXPath = @"misc/stroke_count/text()";
static NSString *kRTKSelectKanjiLiteralXPath = @"literal/text()";

void get_rtk1(NSMutableDictionary *dictionary, NSString *fileName, NSString *fileType);
void get_rtk3(NSMutableDictionary *dictionary, NSString *fileName, NSString *fileType);
void get_kanjidic2(NSMutableDictionary *dictionary, NSString *fileName, NSString *fileType);
NSString * getSingleNodeValueWithXPath(NSXMLNode *node, NSString *xpath);

int 
main (
	int argc, 
	const char * argv[]) 
{
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];

	NSMutableDictionary *heisig = [[NSMutableDictionary alloc] init];
	
	get_rtk1(heisig, kRTKZigFile, kRTKZigFileType);
	get_rtk3(heisig, kRTK3File, kRTK3FileType);
	get_kanjidic2(heisig, kRTKKanjiDic2File, kRTKKanjiDic2FileType);
	NSLog(@"%@", heisig);
	
    [pool drain];
    return 0;
}

void 
get_rtk1(
	NSMutableDictionary *dictionary,
	NSString *fileName, 
	NSString *fileType) 
{

	NSArray *keys = [[NSArray alloc] initWithObjects: @"heisigNumber", @"kanji", @"keyword", @"strokeCount", @"indexOrdinal", @"lessonNumber", nil];
	
	NSError *error;
	
	NSString *path = [[NSBundle mainBundle] pathForResource:fileName ofType:fileType ];
	
	NSString *string = [NSString stringWithContentsOfFile: path encoding:NSUTF8StringEncoding error: &error];
	
	NSArray *lines = [string componentsSeparatedByString:@"\n"];

	for(NSString *line in lines) {
		if ([line length] > 0) {
			NSString *firstCharacter = [line substringToIndex:1];
			if ([firstCharacter compare: @"#"] == 0) {
				NSLog(@"Comment - %@", line);
			} else {
				NSArray *components = [line componentsSeparatedByString:@":"];
				NSMutableDictionary *childDictionary = [[NSMutableDictionary alloc] initWithObjects: components forKeys:keys];
				[childDictionary removeObjectForKey: @"indexOrdinal"];
				NSString *heisigNumber = [childDictionary valueForKey: @"heisigNumber"];
				[dictionary setValue:childDictionary forKey:heisigNumber];
			}
		}
	}
	
}

void 
get_rtk3(
	NSMutableDictionary *dictionary, 
	NSString *fileName, 
	NSString *fileType) 
{
	NSError *error;
	
	NSString *path = [[NSBundle mainBundle] pathForResource:fileName ofType:fileType ];
	
	NSString *string = [NSString stringWithContentsOfFile: path encoding:NSASCIIStringEncoding error: &error];
	
	NSArray *lines = [string componentsSeparatedByString:@"\n"];

	for(NSString *line in lines) {
		if ([line length] > 0) {
			NSString *frameNumber = [line substringToIndex: 4];
			NSString *keyword = [line substringFromIndex: 6];
			keyword = [keyword stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceAndNewlineCharacterSet]];
			NSMutableDictionary *childDictionary = [[NSMutableDictionary alloc] initWithObjectsAndKeys:frameNumber, @"heisigNumber", keyword, @"keyword", nil];
			NSString *heisigNumber = [childDictionary valueForKey: @"heisigNumber"];
			[dictionary setValue:childDictionary forKey:heisigNumber];
		}
	}
}

void 
get_kanjidic2(
		 NSMutableDictionary *dictionary, 
		 NSString *fileName, 
		 NSString *fileType) 
{
	
	
	NSError *error;
	
	NSURL *url = [[NSBundle mainBundle] URLForResource:fileName withExtension:fileType ];
	
	NSXMLDocument *xmlDoc = [[NSXMLDocument alloc] initWithContentsOfURL:url options:NSUTF8StringEncoding error:&error];
	
	NSArray* nodes = [xmlDoc nodesForXPath: kRTKSelectHeisigKanjiXPath error:nil];
	for (NSXMLNode *node in nodes) {
		

		// find the referenced frame number in our dictionary
		NSMutableDictionary *characterDic;

		NSString *frameKey = getSingleNodeValueWithXPath(node, kRTKSelectHeisigFrameXPath);
		if (frameKey) {
			characterDic = [dictionary objectForKey: frameKey];
		} else {
			NSLog(@"Error, kanjidic2 node didn't contain a heisig number, but somehow passed the xpath");
			NSLog(@"%@", node);
			abort();
		}
				
		// if RTK 3 kanji
		if ([node nodesForXPath: kRTKSelectHeisigKanji3XPath error:nil]) {
			
		}
		
		
	}
}
	
NSString * 
getSingleNodeValueWithXPath(
	NSXMLNode *node, 
	NSString *xpath) 
{
	NSArray *_nodes = [node nodesForXPath: xpath error:nil];
	if ([_nodes count] > 0) {
		return [[_nodes lastObject] stringValue];
	} else {
		return nil;
	}
}
