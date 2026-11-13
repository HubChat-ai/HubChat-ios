# HubChat iOS SDK

ویجت چت پشتیبانی هاب‌چت برای اپ‌های iOS (UIKit و SwiftUI) با Swift Package Manager، با همان ظاهر و امکانات ویجت سایت. حداقل iOS 13.

## امکانات
- دکمه‌ی شناور با رنگ، آیکن، متن و جایگاهی که در پنل هاب‌چت تنظیم کرده‌اید
- پنل گفتگو با همان ظاهر و امکانات ویجت سایت: ارسال فایل و عکس، پایگاه دانش، ساعات کاری و نظرسنجی رضایت
- شمارنده‌ی پیام‌های خوانده‌نشده روی دکمه، حتی وقتی پنل بسته است
- تغییر ظاهر از پنل، بدون نیاز به انتشار نسخه‌ی جدید اپ
- پیام‌های کاربران در صندوق ورودی هاب‌چت، کنار تلگرام، بله، روبیکا و بقیه‌ی کانال‌ها

## کلید کانال
کلید را از پنل هاب‌چت بگیرید: «تنظیمات > کانال‌ها > افزودن کانال > اپلیکیشن موبایل». کلید با `hc_` شروع می‌شود و در صفحه‌ی همان کانال، کنار نمونه‌کد نصب، نمایش داده می‌شود.

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

## پشتیبانی
- مستندات: https://hubchat.ir/docs/connect-channel/mobile_sdk
- گزارش مشکل: بخش Issues همین مخزن
- وب‌سایت: https://hubchat.ir
