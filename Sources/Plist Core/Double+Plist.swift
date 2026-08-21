extension Double {

    @inlinable
    public init?(_ plist: Plist) {
        switch plist.raw {
        case .real(let value):
            self = value

        case .integer(let value):
            self = Double(value)

        default:
            return nil
        }
    }
}

extension Float {

    @inlinable
    public init?(_ plist: Plist) {
        switch plist.raw {
        case .real(let value):
            self = Float(value)

        case .integer(let value):
            self = Float(value)

        default:
            return nil
        }
    }
}
