import SwiftUI

/// SwiftUI launcher: `.overlay(alignment: .bottomLeading) { HubChatLauncher() }`
@available(iOS 14.0, *)
public struct HubChatLauncher: UIViewRepresentable {
    public init() {}
    public func makeUIView(context: Context) -> HubChatLauncherButton { HubChatLauncherButton() }
    public func updateUIView(_ uiView: HubChatLauncherButton, context: Context) {}
}
