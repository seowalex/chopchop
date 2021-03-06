import SwiftUI

extension CGPoint {
    static func + (lhs: CGPoint, rhs: CGVector) -> CGPoint {
        CGPoint(x: lhs.x + rhs.dx, y: lhs.y + rhs.dy)
    }

    static func - (lhs: CGPoint, rhs: CGVector) -> CGPoint {
        CGPoint(x: lhs.x - rhs.dx, y: lhs.y - rhs.dy)
    }

    static func - (lhs: CGPoint, rhs: CGPoint) -> CGVector {
        CGVector(dx: lhs.x - rhs.x, dy: lhs.y - rhs.y)
    }

    // swiftlint:disable shorthand_operator
    static func += (lhs: inout CGPoint, rhs: CGVector) {
        lhs = lhs + rhs
    }

    static func -= (lhs: inout CGPoint, rhs: CGVector) {
        lhs = lhs - rhs
    }
    // swiftlint:enable shorthand_operator
}

extension CGPoint {
    func rotate(around point: CGPoint, by angle: CGFloat) -> CGPoint {
        applying(.rotate(around: point, by: angle))
    }

    func rotate(around point: CGPoint, by angle: Angle) -> CGPoint {
        rotate(around: point, by: CGFloat(angle.radians))
    }

    func distance(to point: CGPoint) -> CGFloat {
        (point - self).magnitude()
    }

    func angle(to point: CGPoint) -> CGFloat {
        (point - self).angle()
    }
}
