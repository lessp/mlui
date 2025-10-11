#include <caml/alloc.h>
#include <caml/callback.h>
#include <caml/memory.h>
#include <caml/mlvalues.h>

#ifdef __APPLE__
#import <Cocoa/Cocoa.h>

// Forward declaration
@interface TrayTarget : NSObject {
    @public
    value callback;
}
- (void)handleClick:(id)sender;
@end

@implementation TrayTarget
- (id)init {
    self = [super init];
    if (self) {
        callback = 0;
    }
    return self;
}
- (void)handleClick:(id)sender {
    if (callback != 0) {
        // Call the OCaml callback
        caml_callback(callback, Val_unit);
    }
}
@end

// Wrapper to track if tray has been removed
typedef struct {
    NSStatusItem* statusItem;
    TrayTarget* target;
    int removed;
} TrayHandle;

// Pointer wrapping utilities
static inline value mlui_wrap_pointer(void* ptr) {
    CAMLparam0();
    CAMLlocal1(wrapped);
    wrapped = caml_alloc(1, Abstract_tag);
    *((void**)Data_abstract_val(wrapped)) = ptr;
    CAMLreturn(wrapped);
}

static inline void* mlui_unwrap_pointer(value wrapped) {
    return *((void**)Data_abstract_val(wrapped));
}

// Image loading helper
void* mlui_make_image_from_path(const char* image_path) {
    @autoreleasepool {
        NSString *nsImagePath = 
            [NSString stringWithCString:image_path encoding:NSUTF8StringEncoding];
        NSImage *nsImage = [[NSImage alloc] initWithContentsOfFile:nsImagePath];
        return nsImage;
    }
}

// Create tray item
CAMLprim value mlui_tray_make(value vImagePath) {
    CAMLparam1(vImagePath);
    CAMLlocal1(result);

    @autoreleasepool {
        NSLog(@"[Tray] Creating tray item...");
        // Initialize NSApplication if needed (only if not already initialized)
        if (NSApp == nil) {
            [NSApplication sharedApplication];
            [NSApp setActivationPolicy:NSApplicationActivationPolicyAccessory];
        } else {
            // NSApp already exists (probably SDL initialized it)
            // Don't change the activation policy
            [NSApplication sharedApplication];
        }
        
        NSStatusItem *statusItem = [[NSStatusBar systemStatusBar]
            statusItemWithLength:NSVariableStatusItemLength];
        [statusItem retain];
        
        NSLog(@"[Tray] Status item created: %@", statusItem);
        NSLog(@"[Tray] Button: %@", statusItem.button);
        
        // Make sure the status item is visible
        statusItem.visible = YES;

        // Set image if provided (optional parameter from OCaml)
        if (Is_block(vImagePath)) {  // Check if Some(_)
            const char *imagePath = String_val(Field(vImagePath, 0));
            NSImage *nsImage = mlui_make_image_from_path(imagePath);
            if (nsImage) {
                statusItem.button.image = nsImage;
                [statusItem.button sizeToFit];
            }
        } else {
            // No image provided - set a default space to make it visible
            // This will be replaced when set_title is called
            statusItem.button.title = @" ";
            [statusItem.button sizeToFit];
        }

        // Wrap in a handle that tracks removal state
        TrayHandle* handle = malloc(sizeof(TrayHandle));
        handle->statusItem = statusItem;
        handle->target = nil;
        handle->removed = 0;
        
        NSLog(@"[Tray] Handle created: %p", handle);
        
        result = mlui_wrap_pointer(handle);
    }

    CAMLreturn(result);
}

// Set title
CAMLprim value mlui_tray_set_title(value vTrayHandle, value vTitle) {
    CAMLparam2(vTrayHandle, vTitle);
    CAMLlocal1(result);

    @autoreleasepool {
        TrayHandle* handle = mlui_unwrap_pointer(vTrayHandle);
        
        NSLog(@"[Tray] set_title called, handle: %p", handle);
        
        if (handle && !handle->removed && handle->statusItem) {
            const char *title = String_val(vTitle);
            
            NSString *nsTitle = 
                [NSString stringWithCString:title encoding:NSUTF8StringEncoding];
            
            NSLog(@"[Tray] Setting title to: %@", nsTitle);
            NSLog(@"[Tray] Button before: %@", handle->statusItem.button);
            
            // Clear image and set title
            handle->statusItem.button.image = nil;
            handle->statusItem.button.title = nsTitle;
            [handle->statusItem.button setHidden:NO];
            handle->statusItem.visible = YES;
            
            // Force the button to recalculate its size
            [handle->statusItem.button sizeToFit];
            
            NSLog(@"[Tray] Button after: %@, title: %@", handle->statusItem.button, handle->statusItem.button.title);
        } else {
            NSLog(@"[Tray] set_title failed - handle: %p, removed: %d, statusItem: %@", 
                  handle, handle ? handle->removed : -1, handle ? handle->statusItem : nil);
        }
        
        result = vTrayHandle;
    }

    CAMLreturn(result);
}

// Remove tray item
CAMLprim value mlui_tray_remove(value vTrayHandle) {
    CAMLparam1(vTrayHandle);
    
    @autoreleasepool {
        TrayHandle* handle = mlui_unwrap_pointer(vTrayHandle);
        
        if (handle && !handle->removed && handle->statusItem) {
            [[NSStatusBar systemStatusBar] removeStatusItem:handle->statusItem];
            [handle->statusItem release];
            if (handle->target) {
                // Unregister the callback from global roots before releasing
                if (handle->target->callback != 0) {
                    caml_remove_global_root(&handle->target->callback);
                    handle->target->callback = 0;
                }
                [handle->target release];
                handle->target = nil;
            }
            handle->statusItem = nil;
            handle->removed = 1;
        }
    }
    
    CAMLreturn(Val_unit);
}

// Set click handler
CAMLprim value mlui_tray_set_on_click(value vTrayHandle, value vCallback) {
    CAMLparam2(vTrayHandle, vCallback);
    
    @autoreleasepool {
        TrayHandle* handle = mlui_unwrap_pointer(vTrayHandle);
        
        if (handle && !handle->removed && handle->statusItem) {
            // Create target if it doesn't exist
            if (!handle->target) {
                handle->target = [[TrayTarget alloc] init];
            }
            
            // Store the callback (register as global root so GC doesn't collect it)
            if (handle->target->callback != 0) {
                caml_remove_global_root(&handle->target->callback);
            }
            handle->target->callback = vCallback;
            caml_register_global_root(&handle->target->callback);
            
            // Set the action
            handle->statusItem.button.target = handle->target;
            handle->statusItem.button.action = @selector(handleClick:);
            
            NSLog(@"[Tray] Click handler set");
        }
    }
    
    CAMLreturn(Val_unit);
}

#else
// Stub implementations for non-macOS platforms
CAMLprim value mlui_tray_make(value vImagePath) {
    CAMLparam1(vImagePath);
    CAMLlocal1(result);
    // Return a dummy abstract value
    result = caml_alloc(1, Abstract_tag);
    CAMLreturn(result);
}

CAMLprim value mlui_tray_set_title(value vTrayHandle, value vTitle) {
    CAMLparam2(vTrayHandle, vTitle);
    CAMLreturn(vTrayHandle);
}

CAMLprim value mlui_tray_remove(value vTrayHandle) {
    CAMLparam1(vTrayHandle);
    CAMLreturn(Val_unit);
}

CAMLprim value mlui_tray_set_on_click(value vTrayHandle, value vCallback) {
    CAMLparam2(vTrayHandle, vCallback);
    CAMLreturn(Val_unit);
}
#endif