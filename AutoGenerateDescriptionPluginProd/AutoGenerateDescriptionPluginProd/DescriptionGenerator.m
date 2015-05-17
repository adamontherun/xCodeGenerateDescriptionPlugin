//
//  DescriptionGenerator.m
//  AutoGenerateDescriptionPluginProd
//
//  Created by adam smith on 2/17/15.
//  Copyright (c) 2015 adam smith. All rights reserved.
//

#import "DescriptionGenerator.h"

@interface DescriptionGenerator ()

@property (nonatomic) NSString *currentClass;

@end

@implementation DescriptionGenerator

- (void)generateDescription {
    self.currentClass = [[DTXcodeUtils getCurrentClassNameByCurrentSelectedRange] lastObject];
    NSString *selectedString = [self selectedString];
    NSString *descriptionMethod = [self prepareDescriptionMethodWithSelectedString:selectedString];
    NSLog(@"%@", descriptionMethod);
    [self writeMethodToFileWithDescriptionMethod:descriptionMethod];
}

- (NSString *)selectedString {
    // This is a reference to the current source code editor.
    DVTSourceTextView *sourceTextView = [DTXcodeUtils currentSourceTextView];
    // Get the range of the selected text within the source code editor.
    NSRange selectedTextRange = [sourceTextView selectedRange];
    // Get the selected text using the range from above.
    NSString *selectedString = [sourceTextView.textStorage.string substringWithRange:selectedTextRange];

    return selectedString;
}

- (NSString *)prepareDescriptionMethodWithSelectedString:(NSString *)selectedString {
    NSArray *properties = [selectedString componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
    NSMutableString *leftSideString = [NSMutableString stringWithFormat:@"@\"%@ description:%%@\\n ", self.currentClass];
    NSMutableString *rightSideString = [NSMutableString stringWithString:@"[super description]"];

    for (NSString *property in properties) {
        if (property.length != 0) {
            if ([property hasPrefix:@"//"] || [property hasPrefix:@"/*"] || [property hasPrefix:@" *"] || [property hasPrefix:@" */"]) {
                continue;
            }

            NSRange rangeOfComment = [property rangeOfString:@"//"];
            NSMutableString *propertyStrippedOfTrailingCommentsAndSemiColon = nil;

            if (rangeOfComment.length > 0) {
                propertyStrippedOfTrailingCommentsAndSemiColon = [[property substringToIndex:rangeOfComment.location]copy];
                propertyStrippedOfTrailingCommentsAndSemiColon = [[propertyStrippedOfTrailingCommentsAndSemiColon stringByReplacingOccurrencesOfString:@" " withString:@""]copy];
            } else {
                propertyStrippedOfTrailingCommentsAndSemiColon = [property copy];
            }

            propertyStrippedOfTrailingCommentsAndSemiColon = [[propertyStrippedOfTrailingCommentsAndSemiColon stringByReplacingOccurrencesOfString:@";" withString:@""] copy];


            NSString *iVarWithOutPropertyPrefix = [RX(@"@property[ ]*\\(.+\\)[ ]*") replace:propertyStrippedOfTrailingCommentsAndSemiColon withBlock:^NSString *(NSString *match) {
                return @"";
            }];

            NSString *dataTypeOfProperty = [[RX(@"^\\w+") matches:iVarWithOutPropertyPrefix]firstObject];

            NSString *iVarRegex = nil;
            BOOL iVarIsPointer = [[RX(@"\\*") matches:iVarWithOutPropertyPrefix] count];

            if (iVarIsPointer) {
                iVarRegex = @"\\*\\w+";
            } else {
                iVarRegex = @"\\w+";
            }

            NSString *iVarWithOutPropertyAndTypePrefix = [RX(@"^\\w+") replace:iVarWithOutPropertyPrefix withBlock:^NSString *(NSString *match) {
                return @"";
            }];
            NSArray *iVarNameMatches = [RX(iVarRegex) matches:iVarWithOutPropertyAndTypePrefix];

            void (^ handleVarName)(NSString *) = ^(NSString *iVarName) {
                if (iVarIsPointer) {
                    iVarName = [iVarName substringFromIndex:1];//to remove prefix *
                }

                NSString *iVarNamePrependedWithSelf = [NSString stringWithFormat:@"self.%@", iVarName];
                NSString *dataTypeMatch = dataTypeOfProperty;
                NSString *formattedRightSide = [self formatRightSideWithDataType:dataTypeMatch iVar:iVarNamePrependedWithSelf ];
                NSString *token = [self matchTokenToDatatype:dataTypeMatch];
                [leftSideString appendString:[NSString stringWithFormat:@"%@: %@\\n", iVarName, token]];
                [rightSideString appendString:[NSString stringWithFormat:@", %@", formattedRightSide]];
            };

            if (iVarNameMatches.count) {
                [iVarNameMatches enumerateObjectsUsingBlock:^(NSString *obj, NSUInteger idx, BOOL *stop) {
                    handleVarName(obj);
                }];
            }
        }
    }

    [leftSideString appendString:@"\""];
    NSString *descriptionMethod = [NSString stringWithFormat:@"\n- (NSString *)description\n{\n    return [NSString stringWithFormat:%@,%@];\n}\n", leftSideString, rightSideString];
    return descriptionMethod;
}

- (void)writeMethodToFileWithDescriptionMethod:(NSString *)descriptionMethod {
    [DTXcodeUtils openFile:[DTXcodeUtils getDotMFilePathOfCurrentEditFile]];
    DVTSourceTextView *textView = [DTXcodeUtils currentSourceTextView];
    NSString *textViewText = [textView string];
    NSRange contentRange = [DTXcodeUtils getClassImplementContentRangeWithClassName:self.currentClass mFileText:textViewText];
    NSRange insertRange = [DTXcodeUtils getInsertRangeWithClassImplementContentRange:contentRange];
    [textView scrollRangeToVisible:insertRange];
    NSString *newLinesRemoved = [[textViewText componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]] componentsJoinedByString:@" "];
    NSString *textViewTextSpacesRemoved = [newLinesRemoved stringByReplacingOccurrencesOfString:@" " withString:@""];

    if ([textViewTextSpacesRemoved containsString:@")description"]) {
        NSAlert *alert = [[NSAlert alloc] init];
        [alert setMessageText:@"Description method NOT generated because you already have one. Please delete existing method and try again."];
        [alert runModal];
        return;
    } else {
        [textView insertText:descriptionMethod replacementRange:insertRange];
    }
}

- (NSString *)formatRightSideWithDataType:(NSString *)dataType iVar:(NSString *)iVar {
    NSDictionary *tableMethod = @{
        @"NSRange": [NSString stringWithFormat:@"NSStringFromRange(%@)", iVar],
        @"CGPoint": [NSString stringWithFormat:@"NSStringFromCGPoint(%@)", iVar],
        @"CGVector": [NSString stringWithFormat:@"NSStringFromCGVector(%@)", iVar],
        @"CGSize": [NSString stringWithFormat:@"NSStringFromCGSize(%@)", iVar],
        @"CGRect": [NSString stringWithFormat:@"NSStringFromCGRect(%@)", iVar],
        @"CGAffineTransform": [NSString stringWithFormat:@"NSStringFromCGAffineTransform(%@)", iVar],
        @"UIEdgeInsets": [NSString stringWithFormat:@"NSStringFromUIEdgeInsets(%@)", iVar],
        @"UIOffset": [NSString stringWithFormat:@"NSStringFromUIOffset(%@)", iVar],
        @"SEL": [NSString stringWithFormat:@"NSStringFromSelector(%@)", iVar],
        @"Class": [NSString stringWithFormat:@"NSStringFromClass(%@)", iVar],
        @"Protocol": [NSString stringWithFormat:@"NSStringFromProtocol(%@)", iVar]
    };
    NSString *formattedIVar = tableMethod[dataType];

    return (formattedIVar ? formattedIVar : iVar);
}

- (NSString *)matchTokenToDatatype:(NSString *)dataType {
    NSDictionary *tableMethod = @{
        @"int": @"%zd",
        @"unsignedint": @"%u",
        @"double": @"%f",
        @"float": @"%f",
        @"unsignedchar": @"%c",
        @"unichar": @"%C",
        @"NSInteger": @"%zd",
        @"NSUInteger": @"%zd",
        @"CGFloat": @"%f",
        @"CFIndex": @"%ld",
        @"pointer": @"%p",
        @"BOOL": @"%i"
    };

    NSString *token = tableMethod[dataType];

    return (token ? token : @"%@");
}

@end