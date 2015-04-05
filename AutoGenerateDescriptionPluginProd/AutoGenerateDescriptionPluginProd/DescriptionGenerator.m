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

- (void)generateDescription
{
    self.currentClass = [[DTXcodeUtils getCurrentClassNameByCurrentSelectedRange] lastObject];
    NSString *selectedString = [self selectedString];
    NSString *descriptionMethod = [self prepareDescriptionMethodWithSelectedString:selectedString];
    NSLog(@"%@", descriptionMethod);
    [self writeMethodToFileWithDescriptionMethod:descriptionMethod];
}

- (NSString *)selectedString
{
    // This is a reference to the current source code editor.
    DVTSourceTextView *sourceTextView = [DTXcodeUtils currentSourceTextView];
    // Get the range of the selected text within the source code editor.
    NSRange selectedTextRange = [sourceTextView selectedRange];
    // Get the selected text using the range from above.
    NSString *selectedString = [sourceTextView.textStorage.string substringWithRange:selectedTextRange];
    return selectedString;
}

- (NSString *)prepareDescriptionMethodWithSelectedString:(NSString *)selectedString
{
    NSArray *properties = [selectedString componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
    NSMutableString *leftSideString = [NSMutableString stringWithFormat:@"@\"%@ description:\\n%%@ ", self.currentClass];
    NSMutableString *rightSideString = [NSMutableString stringWithString:@"[super description]"];
    
    for (NSString *property in properties)
    {
        if (property.length != 0)
        {
            NSRange rangeOfComment = [property rangeOfString:@"//"];
            NSMutableString *propertyStrippedOfTrailingCommentsAndSemiColon = nil;
            if (rangeOfComment.length >0) {
                propertyStrippedOfTrailingCommentsAndSemiColon = [[property substringToIndex:rangeOfComment.location]copy];
                propertyStrippedOfTrailingCommentsAndSemiColon = [[propertyStrippedOfTrailingCommentsAndSemiColon stringByReplacingOccurrencesOfString:@" " withString:@""]copy];
            }
            else
            {
             propertyStrippedOfTrailingCommentsAndSemiColon = [property copy];
            }
            propertyStrippedOfTrailingCommentsAndSemiColon = [[propertyStrippedOfTrailingCommentsAndSemiColon stringByReplacingOccurrencesOfString:@";" withString:@""] copy];
            NSArray* iVarNameMatches = [RX(@"\\w+$") matches:propertyStrippedOfTrailingCommentsAndSemiColon];
            NSString *iVarName = [iVarNameMatches firstObject];
            NSString *iVarNamePrependedWithSelf = [NSString stringWithFormat:@"self.%@", iVarName];
            NSString *propertyStrippedOfiVar = [propertyStrippedOfTrailingCommentsAndSemiColon stringByReplacingOccurrencesOfString:iVarName withString:@""];
            NSString *propertyStrippedOfPunctuation = [propertyStrippedOfiVar stringByTrimmingCharactersInSet:[NSCharacterSet punctuationCharacterSet]];
            NSString *propertyStrippedOfWhiteSpace = [propertyStrippedOfPunctuation stringByReplacingOccurrencesOfString:@" " withString:@""];
            NSArray* dataTypeMatches = [RX(@"\\w+$") matches:propertyStrippedOfWhiteSpace];
            NSString* dataTypeMatch = [dataTypeMatches firstObject];
            NSString *formattedRightSide = [self formatRightSideWithDataType:dataTypeMatch iVar:iVarNamePrependedWithSelf ];
            NSString *token = [self matchTokenToDatatype:dataTypeMatch];
            [leftSideString appendString:[NSString stringWithFormat:@"%@: %@\\n", iVarName, token]];
            [rightSideString appendString:[NSString stringWithFormat:@", %@", formattedRightSide]];
        }
    }
    [leftSideString appendString:@"\""];
    NSString *descriptionMethod = [NSString stringWithFormat:@"\n- (NSString *)description\n{\n    return [NSString stringWithFormat:%@,%@];\n}\n", leftSideString, rightSideString];
    return descriptionMethod;
}

- (void)writeMethodToFileWithDescriptionMethod:(NSString *)descriptionMethod
{
    [DTXcodeUtils openFile:[DTXcodeUtils getDotMFilePathOfCurrentEditFile]];
    DVTSourceTextView *textView = [DTXcodeUtils currentSourceTextView];
    NSString *textViewText = [textView string];
    NSRange contentRange = [DTXcodeUtils getClassImplementContentRangeWithClassName:self.currentClass mFileText:textViewText];
    NSRange insertRange  = [DTXcodeUtils getInsertRangeWithClassImplementContentRange:contentRange];
    [textView scrollRangeToVisible:insertRange];
    
    NSString *textViewTextSpacesRemoved = [textViewText stringByReplacingOccurrencesOfString:@" " withString:@""];
    if ([textViewTextSpacesRemoved containsString:@")description"])
    {
        NSAlert *alert = [[NSAlert alloc] init];
        [alert setMessageText:@"Description method NOT generated because you already have one. Please delete existing method and try again."];
        [alert runModal];
        return;
    }
    else
    {
        [textView insertText:descriptionMethod replacementRange:insertRange];
    }
}

- (NSString *)formatRightSideWithDataType:(NSString *)dataType iVar:(NSString *)iVar
{
    NSString *formattedIVar;
    if ([dataType isEqualToString:@"NSRange"])
    {
        formattedIVar = [NSString stringWithFormat:@"NSStringFromRange(%@)", iVar];
    }
    else if ([dataType isEqualToString:@"CGPoint"])
    {
        formattedIVar = [NSString stringWithFormat:@"NSStringFromCGPoint(%@)", iVar];
    }
    else if ([dataType isEqualToString:@"CGVector"])
    {
        formattedIVar = [NSString stringWithFormat:@"NSStringFromCGVector(%@)", iVar];
    }
    else if ([dataType isEqualToString:@"CGSize"])
    {
        formattedIVar = [NSString stringWithFormat:@"NSStringFromCGSize(%@)", iVar];
    }
    else if ([dataType isEqualToString:@"CGRect"])
    {
        formattedIVar = [NSString stringWithFormat:@"NSStringFromCGRect(%@)", iVar];
    }
    else if ([dataType isEqualToString:@"CGAffineTransform"])
    {
        formattedIVar = [NSString stringWithFormat:@"NSStringFromCGAffineTransform(%@)", iVar];
    }
    else if ([dataType isEqualToString:@"UIEdgeInsets"])
    {
        formattedIVar = [NSString stringWithFormat:@"NSStringFromUIEdgeInsets(%@)", iVar];
    }
    else if ([dataType isEqualToString:@"UIOffset"])
    {
        formattedIVar = [NSString stringWithFormat:@"NSStringFromUIOffset(%@)", iVar];
    }
    else if ([dataType isEqualToString:@"SEL"])
    {
        formattedIVar = [NSString stringWithFormat:@"NSStringFromSelector(%@)", iVar];
    }
    else if ([dataType isEqualToString:@"Class"])
    {
        formattedIVar = [NSString stringWithFormat:@"NSStringFromClass(%@)", iVar];
    }
    else if ([dataType isEqualToString:@"Protocol"])
    {
        formattedIVar = [NSString stringWithFormat:@"NSStringFromProtocol(%@)", iVar];
    }
    else
    {
        formattedIVar = iVar;
    }
    return formattedIVar;
}

- (NSString *)matchTokenToDatatype:(NSString *)dataType
{
    NSString *token;
    if ([dataType isEqualToString:@"int"])
    {
        token = @"%zd";
    }
    else if ([dataType isEqualToString:@"unsignedint"])
    {
        token = @"%u";
    }
    else if ([dataType isEqualToString:@"double"])
    {
        token = @"%f";
    }
    else if ([dataType isEqualToString:@"float"])
    {
        token = @"%f";
    }
    else if ([dataType isEqualToString:@"unsignedchar"])
    {
        token = @"%c";
    }
    else if ([dataType isEqualToString:@"unichar"])
    {
        token = @"%C";
    }
    else if ([dataType isEqualToString:@"NSInteger"])
    {
        token = @"%zd";
    }
    else if ([dataType isEqualToString:@"NSUInteger"])
    {
        token = @"%zd";
    }
    else if ([dataType isEqualToString:@"CGFloat"])
    {
        token = @"%f";
    }
    else if ([dataType isEqualToString:@"CFIndex"])
    {
        token = @"%ld";
    }
    else if ([dataType isEqualToString:@"pointer"])
    {
        token = @"%p";
    }
    else if ([dataType isEqualToString:@"BOOL"])
    {
        token = @"%i";
    }
    else
    {
        token = @"%@";
    }
    return token;
}
@end