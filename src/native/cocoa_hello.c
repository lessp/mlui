#include <caml/alloc.h>
#include <caml/memory.h>
#include <caml/mlvalues.h>

#ifdef __APPLE__
#import <Cocoa/Cocoa.h>

CAMLprim value mlui_show_alert(value vMessage) {
    CAMLparam1(vMessage);
    
    @autoreleasepool {
        // Convert OCaml string to NSString
        const char *message = String_val(vMessage);
        NSString *nsMessage = [NSString stringWithUTF8String:message];
        
        // Create and show alert
        NSAlert *alert = [[NSAlert alloc] init];
        [alert setMessageText:@"Hello from Cocoa!"];
        [alert setInformativeText:nsMessage];
        [alert addButtonWithTitle:@"OK"];
        [alert runModal];
    }
    
    CAMLreturn(Val_unit);
}

#else
// Non-macOS stub
CAMLprim value mlui_show_alert(value vMessage) {
    CAMLparam1(vMessage);
    printf("Alert (not on macOS): %s\n", String_val(vMessage));
    CAMLreturn(Val_unit);
}
#endif