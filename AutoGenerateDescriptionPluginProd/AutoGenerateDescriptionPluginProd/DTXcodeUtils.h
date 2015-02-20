#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>

@class DVTSourceTextView;
@class DVTTextStorage;
@class IDEEditor;
@class IDEEditorArea;
@class IDESourceCodeDocument;
@class IDEEditorContext;
@class IDEWorkspaceWindowController;

@interface DTXcodeUtils : NSObject
+ (NSWindow *)currentWindow;
+ (NSResponder *)currentWindowResponder;
+ (NSMenu *)mainMenu;
+ (IDEWorkspaceWindowController *)currentWorkspaceWindowController;
+ (IDEEditorArea *)currentEditorArea;
+ (IDEEditorContext *)currentEditorContext;
+ (IDEEditor *)currentEditor;
+ (IDESourceCodeDocument *)currentSourceCodeDocument;
+ (DVTSourceTextView *)currentSourceTextView;
+ (DVTTextStorage *)currentTextStorage;
+ (NSScrollView *)currentScrollView;
+ (NSArray *)getCurrentClassNameByCurrentSelectedRange;
+ (NSString *)getDotMFilePathOfCurrentEditFile;
+ (BOOL)openFile:(NSString *)filePath;
+ (NSRange)getClassImplementContentRangeWithClassName:(NSString *)className mFileText:(NSString *)mFileText;

+ (NSMenuItem *)getMainMenuItemWithTitle:(NSString *)title;
+ (NSRange)getInsertRangeWithClassImplementContentRange:(NSRange)range;
@end
