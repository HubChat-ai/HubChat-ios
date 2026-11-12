import UIKit

/// Floating launcher button matching the website widget.
public final class HubChatLauncherButton: UIControl {
    private let gradient = CAGradientLayer()
    private let stack = UIStackView()
    private let icon = UIImageView()
    private let label = UILabel()
    private let badge = UILabel()
    private var sideConstraints: (left: NSLayoutConstraint, right: NSLayoutConstraint)?

    public override init(frame: CGRect) {
        super.init(frame: frame)
        isHidden = true
        accessibilityLabel = "گفتگوی آنلاین"
        accessibilityTraits = .button
        layer.insertSublayer(gradient, at: 0)
        gradient.startPoint = CGPoint(x: 0, y: 0)
        gradient.endPoint = CGPoint(x: 1, y: 1)
        gradient.cornerRadius = 30
        layer.shadowOpacity = 0.45
        layer.shadowRadius = 14
        layer.shadowOffset = CGSize(width: 0, height: 10)

        stack.axis = .horizontal
        stack.spacing = 10
        stack.alignment = .center
        stack.semanticContentAttribute = .forceRightToLeft
        stack.isUserInteractionEnabled = false
        stack.translatesAutoresizingMaskIntoConstraints = false
        icon.contentMode = .scaleAspectFit
        icon.image = UIImage(systemName: "bubble.left")?.withConfiguration(UIImage.SymbolConfiguration(pointSize: 24, weight: .semibold))
        label.font = .systemFont(ofSize: 15, weight: .bold)
        label.isHidden = true
        stack.addArrangedSubview(icon)
        stack.addArrangedSubview(label)
        addSubview(stack)

        badge.font = .systemFont(ofSize: 11, weight: .heavy)
        badge.textColor = .white
        badge.textAlignment = .center
        badge.backgroundColor = UIColor(red: 0.94, green: 0.27, blue: 0.27, alpha: 1)
        badge.layer.cornerRadius = 11
        badge.layer.borderWidth = 2.5
        badge.layer.borderColor = UIColor.white.cgColor
        badge.clipsToBounds = true
        badge.isHidden = true
        badge.translatesAutoresizingMaskIntoConstraints = false
        addSubview(badge)

        translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: 60),
            widthAnchor.constraint(greaterThanOrEqualToConstant: 60),
            stack.centerXAnchor.constraint(equalTo: centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: centerYAnchor),
            stack.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: 16),
            icon.widthAnchor.constraint(equalToConstant: 28),
            icon.heightAnchor.constraint(equalToConstant: 28),
            badge.topAnchor.constraint(equalTo: topAnchor, constant: -4),
            badge.heightAnchor.constraint(equalToConstant: 22),
            badge.widthAnchor.constraint(greaterThanOrEqualToConstant: 22),
        ])

        addTarget(self, action: #selector(tap), for: .touchUpInside)
        NotificationCenter.default.addObserver(self, selector: #selector(applySettings), name: .hubChatSettingsLoaded, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(updateBadge), name: .hubChatUnreadChanged, object: nil)
        applySettings()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

    func install(in view: UIView, bottomOffset: CGFloat) {
        view.addSubview(self)
        let left = leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor, constant: 20)
        let right = view.safeAreaLayoutGuide.rightAnchor.constraint(equalTo: rightAnchor, constant: 20)
        sideConstraints = (left, right)
        view.safeAreaLayoutGuide.bottomAnchor.constraint(equalTo: bottomAnchor, constant: 20 + bottomOffset).isActive = true
        applySettings()
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        gradient.frame = bounds
        layer.shadowPath = UIBezierPath(roundedRect: bounds, cornerRadius: 30).cgPath
    }

    public override var isHighlighted: Bool {
        didSet { UIView.animate(withDuration: 0.2) { self.transform = self.isHighlighted ? CGAffineTransform(scaleX: 0.96, y: 0.96) : .identity } }
    }

    @objc private func tap() { HubChat.open() }

    @objc private func applySettings() {
        guard let settings = HubChat.shared.settings else { return }
        let light = settings.color.blended(with: .white, ratio: 0.18)
        gradient.colors = [light.cgColor, settings.color.cgColor]
        layer.shadowColor = settings.color.cgColor
        icon.tintColor = settings.onColor
        label.textColor = settings.onColor
        label.text = settings.launcherText
        label.isHidden = settings.launcherText == nil
        badge.leadingAnchor.constraint(equalTo: settings.isRight ? leadingAnchor : trailingAnchor, constant: settings.isRight ? -4 : -18).isActive = true
        sideConstraints?.left.isActive = !settings.isRight
        sideConstraints?.right.isActive = settings.isRight
        if let url = settings.launcherImage { loadImage(url, small: settings.launcherText != nil) }

        if isHidden {
            isHidden = false
            transform = CGAffineTransform(scaleX: 0.6, y: 0.6)
            alpha = 0
            UIView.animate(withDuration: 0.6, delay: 0, usingSpringWithDamping: 0.6, initialSpringVelocity: 0.8) {
                self.transform = .identity
                self.alpha = 1
            }
        }
        updateBadge()
    }

    private func loadImage(_ url: URL, small: Bool) {
        URLSession.shared.dataTask(with: url) { data, _, _ in
            guard let data, let image = UIImage(data: data) else { return }
            DispatchQueue.main.async {
                let size: CGFloat = small ? 44 : 60
                self.icon.image = image
                self.icon.contentMode = .scaleAspectFill
                self.icon.layer.cornerRadius = size / 2
                self.icon.clipsToBounds = true
                self.icon.constraints.forEach { $0.constant = size }
            }
        }.resume()
    }

    @objc private func updateBadge() {
        let count = HubChat.shared.unread
        badge.text = " " + (count > 9 ? "۹+" : String(count).map(persian).joined()) + " "
        badge.isHidden = count == 0
    }

    private func persian(_ digit: Character) -> String {
        guard let value = digit.wholeNumberValue else { return String(digit) }
        return String(Array("۰۱۲۳۴۵۶۷۸۹")[value])
    }
}

extension UIColor {
    func blended(with other: UIColor, ratio: CGFloat) -> UIColor {
        var r1: CGFloat = 0, g1: CGFloat = 0, b1: CGFloat = 0, r2: CGFloat = 0, g2: CGFloat = 0, b2: CGFloat = 0
        getRed(&r1, green: &g1, blue: &b1, alpha: nil)
        other.getRed(&r2, green: &g2, blue: &b2, alpha: nil)
        return UIColor(red: r1 + (r2 - r1) * ratio, green: g1 + (g2 - g1) * ratio, blue: b1 + (b2 - b1) * ratio, alpha: 1)
    }
}
