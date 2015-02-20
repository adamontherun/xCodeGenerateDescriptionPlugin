#import "DTXcodeUtils.h"

#import "DTXcodeHeaders.h"

@implementation DTXcodeUtils

+ (NSWindow *)currentWindow {
  return [[NSApplication sharedApplication] keyWindow];
}

+ (NSResponder *)currentWindowResponder {
  return [[self currentWindow] firstResponder];
}

+ (NSMenu *)mainMenu {
  return [NSApp mainMenu];
}

+ (NSMenuItem *)getMainMenuItemWithTitle:(NSString *)title {
  return [[self mainMenu] itemWithTitle:title];
}

+ (IDEWorkspaceWindowController *)currentWorkspaceWindowController {
  NSLog(@"getting window controller");
  NSWindowController *result = [self currentWindow].windowController;
  if ([result isKindOfClass:NSClassFromString(@"IDEWorkspaceWindowController")]) {
    return (IDEWorkspaceWindowController *)result;
  }
  return nil;
}

+ (IDEEditorArea *)currentEditorArea {
  return [self currentWorkspaceWindowController].editorArea;
}

+ (IDEEditorContext *)currentEditorContext {
  return [self currentEditorArea].lastActiveEditorContext;
}

+ (IDEEditor *)currentEditor {
  return [self currentEditorContext].editor;
}

+ (IDESourceCodeDocument *)currentSourceCodeDocument {
  if ([[self currentEditor] isKindOfClass:NSClassFromString(@"IDESourceCodeEditor")]) {
    return ((IDESourceCodeEditor *)[self currentEditor]).sourceCodeDocument;
  } else if ([[self currentEditor] isKindOfClass:
      NSClassFromString(@"IDESourceCodeComparisonEditor")]) {
    IDEEditorDocument *document =
        ((IDESourceCodeComparisonEditor *)[self currentEditor]).primaryDocument;
    if ([document isKindOfClass:NSClassFromString(@"IDESourceCodeDocument")]) {
      return (IDESourceCodeDocument *)document;
    }
  }
  return nil;
}

+ (DVTSourceTextView *)currentSourceTextView {
  if ([[self currentEditor] isKindOfClass:NSClassFromString(@"IDESourceCodeEditor")]) {
    return ((IDESourceCodeEditor *)[self currentEditor]).textView;
  } else if ([[self currentEditor] isKindOfClass:
      NSClassFromString(@"IDESourceCodeComparisonEditor")]) {
    return ((IDESourceCodeComparisonEditor *)[self currentEditor]).keyTextView;
  }
  return nil;
}

+ (DVTTextStorage *)currentTextStorage {
  NSTextView *textView = [self currentSourceTextView];
  if ([textView.textStorage isKindOfClass:NSClassFromString(@"DVTTextStorage")]) {
    return (DVTTextStorage *)textView.textStorage;
  }
  return nil;
}

+ (NSArray *)getCurrentClassNameByCurrentSelectedRange
{
    NSTextView *textView = [self currentSourceTextView];
    NSArray* selectedRanges = [textView selectedRanges];
    if (selectedRanges.count >= 1) {
        NSRange selectedRange = [[selectedRanges objectAtIndex:0] rangeValue];
        NSString *text = textView.textStorage.string;
        NSRange lineRange = [text lineRangeForRange:selectedRange];
        ;
        NSRegularExpression *regex = [NSRegularExpression
                                      regularExpressionWithPattern:@"(?<=@interface)\\s+(\\w+)\\s*\\(?(\\w*)\\)?"
                                      options:0
                                      error:NULL];
        NSArray *results = [regex matchesInString:textView.textStorage.string options:0 range:NSMakeRange(0, lineRange.location)];
        if (results.count > 0) {
            NSTextCheckingResult *textCheckingResult = results[results.count - 1];
            NSRange classNameRange = textCheckingResult.range;
            if (classNameRange.location != NSNotFound) {
                NSMutableArray *array = [NSMutableArray array];
                for (int i = 0; i < textCheckingResult.numberOfRanges; i++) {
                    NSString *item = [text substringWithRange:[textCheckingResult rangeAtIndex:i]];
                    if (item.length > 0) {
                        [array addObject:item];
                       // NSLog(@"%@", item);
                    }
                }
                return array;
            }
        }
    }
    return nil;
}

+ (NSScrollView *)currentScrollView {
  NSView *view = [self currentSourceTextView];
  return [view enclosingScrollView];
}

+ (NSString *)getDotMFilePathOfCurrentEditFile {
  NSString *filePath =  [[[self currentSourceCodeDocument] fileURL]path];
    if ([filePath rangeOfString:@".h"].length > 0) {
        NSString *mFilePath = [filePath stringByReplacingOccurrencesOfString:@".h" withString:@".m"];
        if ([[NSFileManager defaultManager] fileExistsAtPath:mFilePath]) {
            return mFilePath;
        }
        
        mFilePath = [filePath stringByReplacingOccurrencesOfString:@".h" withString:@".mm"];
        if ([[NSFileManager defaultManager] fileExistsAtPath:mFilePath]) {
            return mFilePath;
        }
        
    }
    return filePath;
}

+ (BOOL)openFile:(NSString *)filePath
{
    NSWindowController *currentWindowController = [[NSApp mainWindow] windowController];
    NSLog(@"currentWindowController %@",[currentWindowController description]);
    if ([currentWindowController isKindOfClass:NSClassFromString(@"IDEWorkspaceWindowController")]) {
        NSLog(@"Open in current Xocde");
        id<NSApplicationDelegate> appDelegate = (id<NSApplicationDelegate>)[NSApp delegate];
        if ([appDelegate application:NSApp openFile:filePath]) {
            return YES;
        }
    }
    return NO;
}

+ (NSRange)getInsertRangeWithClassImplementContentRange:(NSRange)range
{
    if (range.location != NSNotFound) {
        return NSMakeRange(range.location+range.length, 1);
    }
    
    return NSMakeRange(NSNotFound, 0);
}

+ (NSRange)getClassImplementContentRangeWithClassName:(NSString *)className mFileText:(NSString *)mFileText
{
    
        NSString *regexPattern = [NSString stringWithFormat:@"@implementation\\s+%@.+?(?=\\s{0,1000}@end)", className];
    
        NSLog(@"%@",regexPattern);
        
        NSRegularExpression *regex = [NSRegularExpression
                                      regularExpressionWithPattern:regexPattern
                                      options:NSRegularExpressionDotMatchesLineSeparators
                                      error:NULL];
        
        NSTextCheckingResult *textCheckingResult = [regex firstMatchInString:mFileText
                                                                     options:0
                                                                       range:NSMakeRange(0, mFileText.length)];
        
        //        NSLog(@"%@", [mFileText substringWithRange:textCheckingResult.range]);
        if (textCheckingResult.range.location != NSNotFound)
        {
            return textCheckingResult.range;
        }
    else
    {
        return NSMakeRange(NSNotFound, 0);
    }
    
}

@end
