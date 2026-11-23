import Acoustics
import Foundation
import Testing

extension `Acoustics Tests` {
    @Suite struct String {}

    fileprivate static let interval = 1 / 96_000.0

    fileprivate static func string(
        decay: Acoustics.String.Decay = .none,
        board: Acoustics.String.Board? = nil
    ) -> Acoustics.String {
        Acoustics.String(
            length: 1.06, tension: 290, density: 0.0062, stiffness: 0.004, decay: decay, board: board, every: interval)
    }

    fileprivate static func board(friction: Double = 0, damping: Double = 0) -> Acoustics.String.Board {
        Acoustics.String.Board(
            reach: 0.86, contact: .init(stiffness: 4e9, exponent: 1.5), friction: friction, damping: damping
        ) { 0.0008 + 0.006 * $0 / 0.86 }
    }

    fileprivate static func pulled(_ depth: Acoustics.String.Offset, at place: Double) -> (Double) -> Acoustics.String.Offset {
        { along in
            let share = along < place ? along / place : (1.06 - along) / (1.06 - place)
            return .init(up: depth.up * share, across: depth.across * share)
        }
    }

    fileprivate static func drift(_ string: inout Acoustics.String, steps: Int) -> (least: Double, most: Double, start: Double) {
        let start = string.energy
        var least = start
        var most = start
        (0..<steps).forEach { _ in
            string.advance()
            let energy = string.energy
            least = min(least, energy)
            most = max(most, energy)
        }
        return (least, most, start)
    }
}

extension `Acoustics Tests`.String {
    @Test func `The bare string's partials are the stiff string's own: a tenth of a cent low down, five cents at 2 kHz`() {
        var worst = 0.0
        for partial in [1.0, 2, 3, 5, 8, 13, 21] {
            var string = `Acoustics Tests`.string()
            string.displace { .init(up: 0.001 * sin(partial * Double.pi * $0 / 1.06)) }
            let middle = string.count / (2 * Int(partial)) + 1
            string.advance()
            let before = string.shape[middle].up
            string.advance()
            let now = string.shape[middle].up
            string.advance()
            let after = string.shape[middle].up
            let heard = acos((after + before) / (2 * now)) / (2 * Double.pi * `Acoustics Tests`.interval)
            let wavenumber = partial * Double.pi / 1.06
            let wanted = (290 / 0.0062 * wavenumber * wavenumber + 0.004 / 0.0062 * pow(wavenumber, 4)).squareRoot() / (2 * Double.pi)
            worst = max(worst, abs(1_200 * log2(heard / wanted)))
            if partial <= 3 { #expect(abs(1_200 * log2(heard / wanted)) < 0.1) }
        }
        #expect(worst < 5)
    }

    @Test func `Without loss a released string keeps its energy`() {
        var string = `Acoustics Tests`.string()
        string.displace(`Acoustics Tests`.pulled(.init(up: 0.004, across: 0.007), at: 0.86))
        let energy = `Acoustics Tests`.drift(&string, steps: 20_000)
        #expect(energy.start > 0)
        #expect((energy.most - energy.least) / energy.start < 1e-10)
    }

    @Test func `Without loss a string that rattles on the fingerboard keeps its energy`() {
        var string = `Acoustics Tests`.string(board: `Acoustics Tests`.board())
        string.displace(`Acoustics Tests`.pulled(.init(up: 0.009, across: 0.004), at: 0.86))
        var touched = false
        let start = string.energy
        var worst = 0.0
        (0..<30_000).forEach { _ in
            string.advance()
            worst = max(worst, abs(string.energy - start))
            if !touched {
                touched = string.shape.indices.contains { string.shape[$0].up < -(0.0008 + 0.006 * Double($0) * string.spacing / 0.86) && Double($0) * string.spacing <= 0.86 }
            }
        }
        #expect(touched)
        #expect(worst / start < 1e-9)
    }

    @Test func `Without loss a string held down by a still fingertip keeps its energy`() {
        var string = `Acoustics Tests`.string(board: `Acoustics Tests`.board())
        string.fingers = [
            .init(place: 0.30, width: 0.014, radius: 0.007, centre: .init(up: 0.0035, across: 0.0005), contact: .init(stiffness: 4e5, exponent: 1.5))
        ]
        string.displace(`Acoustics Tests`.pulled(.init(up: 0.002, across: 0.006), at: 0.86))
        let energy = `Acoustics Tests`.drift(&string, steps: 30_000)
        #expect(string.shape[Int(0.30 / string.spacing)].up < -0.001)
        #expect((energy.most - energy.least) / energy.start < 1e-9)
    }

    @Test func `With loss, friction and a damping fingertip the energy only falls`() {
        var string = `Acoustics Tests`.string(
            decay: .init(steady: 0.8, rising: 0.0004), board: `Acoustics Tests`.board(friction: 0.3, damping: 20))
        string.fingers = [
            .init(
                place: 0.30, width: 0.014, radius: 0.007, centre: .init(up: 0.0035, across: 0.0005),
                contact: .init(stiffness: 4e5, exponent: 1.5), friction: 0.6, damping: 30)
        ]
        string.displace(`Acoustics Tests`.pulled(.init(up: 0.002, across: 0.006), at: 0.86))
        var last = string.energy
        let start = last
        var rise = 0.0
        (0..<30_000).forEach { _ in
            string.advance()
            let energy = string.energy
            rise = max(rise, energy - last)
            last = energy
        }
        #expect(rise < 1e-6 * start)
        #expect(last < 0.9 * start)
    }

    @Test func `A string and the body it pulls on keep their energy together`() {
        var string = `Acoustics Tests`.string()
        var body = Acoustics.Resonator(
            [(98.0, 1.0, 0.3), (183.0, -0.8, 0.9), (412.0, 0.5, -0.7), (1_530.0, 0.9, 0.4)].map {
                .init(frequency: $0.0, decay: 0, mass: 0.4, reach: 0, driven: [$0.1, $0.2])
            }, every: `Acoustics Tests`.interval)
        string.displace(`Acoustics Tests`.pulled(.init(up: 0.004, across: 0.007), at: 0.86))
        let start = string.energy + body.energy
        var worst = 0.0
        var moved = 0.0
        (0..<40_000).forEach { _ in
            let pull = string.pull
            body.advance(driven: [pull.up, pull.across])
            string.advance(end: .init(up: body.felt[0], across: body.felt[1]))
            worst = max(worst, abs(string.energy + body.energy - start))
            moved = max(moved, abs(body.felt[0]))
        }
        #expect(moved > 1e-6)
        #expect(worst / start < 1e-9)
    }
}
