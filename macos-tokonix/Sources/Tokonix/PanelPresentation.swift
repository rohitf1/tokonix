enum PanelPresentation {
    case standalone
    case embedded

    var isEmbedded: Bool {
        self == .embedded
    }
}
