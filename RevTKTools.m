#import <Foundation/Foundation.h>



static NSString *kRTKZigFile = @"rtk1_data";
static NSString *kRTKZigFileType = @"utf8";
static NSString *kRTK3File = @"rtk3_keywords";
static NSString *kRTK3FileType = @"txt";
static NSString *kRTKKanjiDic2File = @"kanjidic2";
static NSString *kRTKKanjiDic2FileType = @"xml";

static NSString *kRTKSelectHeisigKanjiXPath = @"//kanjidic2/character[dic_number/dic_ref[@dr_type='heisig']]";
static NSString *kRTKSelectIsHeisigKanji3XPath = @".[dic_number/dic_ref[@dr_type='heisig'] > 2048]";
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

	NSData *xmlData = [NSPropertyListSerialization dataFromPropertyList:heisig format:NSPropertyListXMLFormat_v1_0 errorDescription: nil];
	[xmlData writeToFile:@"RTKData.plist" atomically:YES];
	
    [pool drain];
    return 0;
}

NSNumber *
getNumber(NSString *number) {
	NSNumberFormatter * f = [[NSNumberFormatter alloc] init];
	NSNumber * myNumber = [f numberFromString: number];
	[f release];
	return myNumber;
}

void 
get_rtk1(
	NSMutableDictionary *dictionary,
	NSString *fileName, 
	NSString *fileType) 
{
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
				int i = 0;
				NSMutableDictionary *childDictionary = [[NSMutableDictionary alloc] init];
				
				NSString *heisigNumberString = [components objectAtIndex: 0];
				
				[childDictionary setValue:getNumber([components objectAtIndex:i++]) forKey:@"heisigNumber"];
				[childDictionary setValue:[components objectAtIndex:i++]			forKey:@"kanji"];
				[childDictionary setValue:[components objectAtIndex:i++]			forKey:@"keyword"];
				[childDictionary setValue:getNumber([components objectAtIndex:i++]) forKey:@"strokeCount"];
				[childDictionary setValue:getNumber([components objectAtIndex:i++]) forKey:@"lessonNumber"];
				
				[dictionary setValue:childDictionary forKey:heisigNumberString];
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
			NSString *heisigNumberString = [line substringToIndex: 4];
			NSNumber *heisigNumber = getNumber(heisigNumberString);
			NSString *keyword = [line substringFromIndex: 6];
			keyword = [keyword stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceAndNewlineCharacterSet]];
			NSMutableDictionary *childDictionary = [[NSMutableDictionary alloc] initWithObjectsAndKeys:heisigNumber, @"heisigNumber", keyword, @"keyword", nil];
			[dictionary setValue:childDictionary forKey:heisigNumberString];
		}
	}
}


/*
 static NSString *kRTKSelectHeisigKanjiXPath = @"//kanjidic2/character[dic_number/dic_ref[@dr_type='heisig']]";
 static NSString *kRTKSelectHeisigKanji3XPath = @"//kanjidic2/character[dic_number/dic_ref[@dr_type='heisig'] >= 2043]";
 static NSString *kRTKSelectHeisigFrameXPath = @"dic_number/dic_ref[@dr_type='heisig']/text()";
 static NSString *kRTKSelectOnYomiXPath = @"reading_meaning/rmgroup/reading[@r_type='ja_on']/text()";
 static NSString *kRTKSelectStrokeCountXPath = @"misc/stroke_count/text()";
 static NSString *kRTKSelectKanjiLiteralXPath = @"literal/text()";
 
 NSArray *keys = [[NSArray alloc] initWithObjects: @"heisigNumber", @"kanji", @"keyword", @"strokeCount", @"indexOrdinal", @"lessonNumber", nil];
 */



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
		NSNumber *heisigNumber;
		NSString *heisigNumberString = getSingleNodeValueWithXPath(node, kRTKSelectHeisigFrameXPath);
		if (heisigNumberString) {
			characterDic = [dictionary objectForKey: heisigNumberString];
			heisigNumber = getNumber(heisigNumberString);
		} else {
			NSLog(@"Error, kanjidic2 node didn't contain a heisig number, but somehow passed the xpath");
			NSLog(@"%@", node);
			abort();
		}
				
		// if RTK 3 kanji
		
		if ([[node nodesForXPath: kRTKSelectIsHeisigKanji3XPath error:nil] count] > 0) {
			NSString *kanji = getSingleNodeValueWithXPath(node, kRTKSelectKanjiLiteralXPath);
			NSNumber *strokeCount = getNumber(getSingleNodeValueWithXPath(node, kRTKSelectStrokeCountXPath));
			NSNumber *lessonNumber = [NSNumber numberWithInt: 57];
			[characterDic setValue:kanji forKey:@"kanji"];
			[characterDic setValue:strokeCount forKey: @"strokeCount"];
			[characterDic setValue:lessonNumber forKey:@"lessonNumber"];
			[characterDic setValue:heisigNumber forKey:@"heisigNumber"];
		}
		
		NSString *onYomi = getSingleNodeValueWithXPath(node, kRTKSelectOnYomiXPath);
		[characterDic setValue:onYomi forKey:@"onYomi"];
		
		
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
