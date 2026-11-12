# HubChat iOS SDK

ویجت چت پشتیبانی هاب‌چت برای اپ‌های iOS (UIKit و SwiftUI) با Swift Package Manager، با همان ظاهر و امکانات ویجت سایت. حداقل iOS 13.

## نصب
- **Swift Package Manager:** در Xcode «File > Add Package Dependencies» آدرس `https://github.com/HubChat-ai/HubChat-ios.git` را با نسخه‌ی `1.0.1` اضافه کنید.
  در Package.swift: `.package(url: "https://github.com/HubChat-ai/HubChat-ios.git", from: "1.0.1")`

## استفاده
```swift
import HubChat

// AppDelegate / App init
HubChat.configure(widgetKey: "hc_xxxxxxxxxxxxxxxxxxxxxxxx")

// UIKit: دکمه‌ی شناور
HubChat.showLauncher(in: window!, bottomOffset: 49)

// SwiftUI
ContentView().overlay(alignment: .bottomLeading) { HubChatLauncher().padding(20) }

// باز کردن از دکمه‌ی خودتان
HubChat.open()

// تعداد خوانده‌نشده
NotificationCenter.default.addObserver(forName: .hubChatUnreadChanged, object: nil, queue: .main) { _ in
    print(HubChat.shared.unread)
}
```

برای آپلود عکس و ضبط صدا در `Info.plist`: `NSCameraUsageDescription`، `NSPhotoLibraryUsageDescription`، `NSMicrophoneUsageDescription`.

## نحوه‌ی کار
تنظیمات دکمه از `GET https://widget.hubchat.ir/widget/{key}/config` خوانده و دکمه‌ی شناور به‌صورت نیتیو ساخته می‌شود. خود صفحه‌ی ویجت (`/widget/{key}`)، همان صفحه‌ای که روی سایت در iframe باز می‌شود، در WebView بارگذاری می‌شود؛ پس ظاهر و امکانات پنل دقیقاً مثل سایت است. SDK پیش از بارگذاری صفحه `window.HubChatBridge.postMessage` را تعریف می‌کند و ویجت رویدادهای `ready`، `close` و `unread` را از آن می‌فرستد.
