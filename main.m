#import <Foundation/Foundation.h>
#include <mach/mach_time.h>

@interface MyClass : NSObject
- (void)sayHello;
@end

@implementation MyClass
- (void)sayHello {
    // Một hành động đơn giản để kiểm tra thời gian
    NSLog(@"Hello, World!"); // Giữ lại NSLog trong phương thức sayHello
}
@end

uint64_t getTime() {
    return mach_absolute_time();
}

double calculateElapsed(uint64_t start, uint64_t end) {
    mach_timebase_info_data_t info;
    mach_timebase_info(&info);
    uint64_t elapsed = end - start;
    return (double)elapsed * info.numer / info.denom / 1e6; // Trả về thời gian tính bằng ms
}

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        MyClass *obj = [[MyClass alloc] init];

        // 1. Cache SEL và IMP trước khi thực hiện các vòng lặp
        SEL selector = @selector(sayHello);
        IMP imp = [obj methodForSelector:selector];

        // 2. Đo thời gian cho dynamic dispatch (tối ưu hóa)
        uint64_t startDynamic = getTime();
        for (int i = 0; i < 100000; i++) {
            // Sử dụng IMP đã cache để gọi trực tiếp phương thức
            ((void (*)(id, SEL))imp)(obj, selector);
        }
        uint64_t endDynamic = getTime();
        double timeDynamic = calculateElapsed(startDynamic, endDynamic);

        // 3. Đo thời gian cho direct call với IMP (Không thay đổi so với trước)
        uint64_t startDirect = getTime();
        for (int i = 0; i < 100000; i++) {
            // Gọi trực tiếp thông qua IMP đã cache
            ((void (*)(id, SEL))imp)(obj, selector);
        }
        uint64_t endDirect = getTime();
        double timeDirect = calculateElapsed(startDirect, endDirect);

        // In kết quả sau khi vòng lặp (Chỉ in kết quả khi kết thúc thử nghiệm)
        NSLog(@"Dynamic Dispatch (Optimized with cached SEL & IMP): %.2f ms", timeDynamic);
        NSLog(@"Direct Call (IMP): %.2f ms", timeDirect);
    }
    return 0;
}
