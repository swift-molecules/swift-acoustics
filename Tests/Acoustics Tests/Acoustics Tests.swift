import Acoustics
import Foundation
import Testing

enum `Acoustics Tests` {}

extension `Acoustics Tests` {
    @Suite struct Resonator {}
    @Suite struct Striker {}
    @Suite struct Membrane {}

    fileprivate static func few(decay: Double = 0, stretch: Double = 0) -> [Acoustics.Resonator.Mode] {
        [(131.0, 0.9, 1.0), (207.0, 1.3, -0.7), (333.0, 0.6, 0.5), (1210.0, 1.1, 0.4), (4070.0, 0.8, -0.3)].map {
            Acoustics.Resonator.Mode(frequency: $0.0, decay: decay, mass: $0.1 * 0.01, reach: $0.2, stretch: stretch * $0.1)
        }
    }
}

extension `Acoustics Tests`.Resonator {
    @Test func `A resonance rings at its own frequency, to the sample`() {
        let interval = 1 / 48_000.0
        var resonator = Acoustics.Resonator([.init(frequency: 4_321, decay: 0, mass: 1, reach: 1)], every: interval)
        resonator.displace(to: [1])
        var worst = 0.0
        var tick = 1
        while tick <= 48_000 {
            resonator.advance()
            let expected = cos(2 * Double.pi * 4_321 * (Double(tick) + 0.5) * interval) / cos(2 * Double.pi * 4_321 * interval / 2)
            worst = max(worst, abs(resonator.displacements[0] - expected))
            tick += 1
        }
        #expect(worst < 1e-8)
    }

    @Test func `A resonance dies at its decay rate`() {
        let interval = 1 / 48_000.0
        var resonator = Acoustics.Resonator([.init(frequency: 300, decay: 4, mass: 1, reach: 1)], every: interval)
        resonator.displace(to: [1])
        let start = resonator.energy
        (0..<48_000).forEach { _ in resonator.advance() }
        #expect(abs(log(resonator.energy / start) / -8 - 1) < 0.01)
    }

    @Test func `Without loss the energy stays through a stroke`() {
        var resonator = Acoustics.Resonator(`Acoustics Tests`.few(), every: 1 / 48_000.0)
        resonator.strike(with: Acoustics.Striker(mass: 0.012, stiffness: 1.5e9, exponent: 2.5), at: 2)
        let start = resonator.energy
        var worst = 0.0
        var touched = 0
        var tick = 0
        while tick < 4_800, resonator.struck {
            resonator.advance()
            if resonator.struck { worst = max(worst, abs(resonator.energy / start - 1)) }
            if resonator.touching { touched += 1 }
            tick += 1
        }
        #expect(touched > 20)
        #expect(worst < 1e-9)
    }

    @Test func `With loss the energy never grows`() {
        var resonator = Acoustics.Resonator(`Acoustics Tests`.few(decay: 3), every: 1 / 48_000.0)
        resonator.strike(with: Acoustics.Striker(mass: 0.012, stiffness: 1.5e9, exponent: 2.5), at: 2)
        var last = resonator.energy
        var grew = 0
        (0..<9_600).forEach { _ in
            resonator.advance()
            let energy = resonator.energy
            if energy > last * (1 + 1e-12) { grew += 1 }
            last = energy
        }
        #expect(grew == 0)
        #expect(!resonator.struck)
    }

    @Test func `A head that stiffens keeps its energy and rings sharper when it moves far`() {
        func crossings(_ size: Double) -> (count: Int, drift: Double) {
            var resonator = Acoustics.Resonator(`Acoustics Tests`.few(stretch: 1), stiffening: 4e8, every: 1 / 48_000.0)
            resonator.displace(to: [size])
            let start = resonator.energy
            var count = 0
            var worst = 0.0
            var last = size
            (0..<48_000).forEach { _ in
                resonator.advance()
                let here = resonator.displacements[0]
                if (here < 0) != (last < 0) { count += 1 }
                last = here
                worst = max(worst, abs(resonator.energy / start - 1))
            }
            return (count, worst)
        }
        let small = crossings(1e-5)
        let large = crossings(3e-3)
        #expect(small.count == 262)
        #expect(large.count > small.count)
        #expect(small.drift < 1e-9 && large.drift < 1e-9)
    }

    @Test func `What is heard is each resonance's quickening times its gain`() {
        let interval = 1 / 48_000.0
        let mode = Acoustics.Resonator.Mode(frequency: 500, decay: 0, mass: 1, reach: 1, heard: [.init(moving: 3), .init(moving: 0, turning: 2)])
        var resonator = Acoustics.Resonator([mode], every: interval)
        resonator.displace(to: [1])
        var worstMoving = 0.0
        var worstTurning = 0.0
        var tick = 1
        let angular = 2 * Double.pi * 500
        let lead = 1 / cos(angular * interval / 2)
        while tick < 4_800 {
            resonator.advance()
            let time = (Double(tick) - 0.5) * interval
            let warped = 4 * pow(sin(angular * interval / 2), 2) / (interval * interval)
            worstMoving = max(worstMoving, abs(resonator.heard[0] / 3 + warped * lead * cos(angular * time)))
            worstTurning = max(worstTurning, abs(resonator.heard[1] / 2 - angular * lead * sin(angular * time) * sin(angular * interval) / interval))
            tick += 1
        }
        #expect(resonator.ears == 2)
        #expect(worstMoving < 1e-3)
        #expect(worstTurning < 1e-3)
    }
}

extension `Acoustics Tests`.Striker {
    @Test func `On something that does not move a linear striker touches for half its own period`() {
        let interval = 1 / 192_000.0
        var wall = Acoustics.Resonator([.init(frequency: 50, decay: 0, mass: 1e9, reach: 1)], every: interval)
        wall.strike(with: Acoustics.Striker(mass: 0.02, stiffness: 8_000, exponent: 1), at: 1)
        var touched = 0
        var peak = 0.0
        while wall.struck {
            wall.advance()
            if wall.touching { touched += 1 }
            peak = max(peak, wall.force)
        }
        let expected = Double.pi * (0.02 / 8_000).squareRoot()
        #expect(abs(Double(touched) * interval - expected) < 3 * interval)
        #expect(abs(peak - (0.02 * 8_000).squareRoot()) < 0.01)
    }

    @Test func `A felt that stiffens touches for a shorter time when it strikes harder`() {
        func touch(_ speed: Double) -> Int {
            var resonator = Acoustics.Resonator(`Acoustics Tests`.few(decay: 2), every: 1 / 48_000.0)
            resonator.strike(with: Acoustics.Striker(mass: 0.012, stiffness: 1.5e9, exponent: 3), at: speed)
            var touched = 0
            var tick = 0
            while resonator.struck, tick < 48_000 {
                resonator.advance()
                if resonator.touching { touched += 1 }
                tick += 1
            }
            return touched
        }
        #expect(touch(4) < touch(0.5))
    }

    @Test func `Force is the slope of the stored energy and nothing is stored apart`() {
        let felt = Acoustics.Striker(mass: 0.012, stiffness: 2e8, exponent: 2.5)
        #expect(felt.force(pressed: -0.001) == 0 && felt.energy(pressed: -0.001) == 0)
        let slope = (felt.energy(pressed: 0.002 + 1e-8) - felt.energy(pressed: 0.002 - 1e-8)) / 2e-8
        #expect(abs(slope / felt.force(pressed: 0.002) - 1) < 1e-6)
    }
}

extension `Acoustics Tests`.Membrane {
    fileprivate static let head = Acoustics.Membrane(radius: 0.32, tension: 5_360, density: 0.262, load: 3.95)

    @Test func `In a vacuum a mode sounds at its zero times the wave speed over the rim`() {
        let bare = Acoustics.Membrane(radius: 0.3, tension: 3_000, density: 0.25)
        let modes = bare.modes(below: 700)
        let first = modes.first { $0.diameters == 0 && $0.circles == 1 }!
        #expect(abs(first.zero - 2.404825557695773) < 1e-12)
        #expect(abs(bare.frequency(of: first) - 2.404825557695773 * (3_000 / 0.25).squareRoot() / (2 * Double.pi * 0.3)) < 1e-9)
        #expect(modes.allSatisfy { bare.frequency(of: $0) < 700 })
        #expect(modes.count == Set(modes).count && modes.count > 10)
    }

    @Test func `The air's load brings the measured head near the fifth, octave and beyond`() {
        let head = `Acoustics Tests`.Membrane.head
        let modes = head.modes(below: 600)
        func frequency(_ diameters: Cardinal, _ circles: Cardinal) -> Double {
            head.frequency(of: modes.first { $0.diameters == diameters && $0.circles == circles }!)
        }
        let principal = frequency(1, 1)
        #expect(abs(principal - 172) < 2)
        #expect(abs(frequency(2, 1) / principal / 1.50 - 1) < 0.035)
        #expect(abs(frequency(3, 1) / principal / 1.97 - 1) < 0.035)
        #expect(abs(frequency(4, 1) / principal / 2.44 - 1) < 0.035)
    }

    @Test func `A mode's mass is its moved mass per area times the integral of its squared shape`() {
        let head = `Acoustics Tests`.Membrane.head
        for mode in head.modes(below: 500) {
            let rings = 4_000
            let sum = (0..<rings).reduce(0.0) { sum, ring in
                let distance = (Double(ring) + 0.5) * head.radius / Double(rings)
                let shape = head.shape(of: mode, at: distance)
                return sum + shape * shape * distance * head.radius / Double(rings)
            }
            let around = mode.diameters == 0 ? 2 * Double.pi : Double.pi
            #expect(abs(head.mass(of: mode) / (head.moved(by: mode) * sum * around) - 1) < 1e-5)
        }
    }

    @Test func `What a mode radiates gives ring times near the calculated ones of the measured drum`() {
        let head = `Acoustics Tests`.Membrane.head
        let modes = head.modes(below: 600)
        let calculated: [(UInt, UInt, Double)] = [(1, 1, 0.8), (2, 1, 1.8), (0, 2, 0.2), (1, 2, 0.2)]
        for (diameters, circles, seconds) in calculated {
            let mode = modes.first { $0.diameters == Cardinal(diameters) && $0.circles == Cardinal(circles) }!
            let ring = 6.908 / head.radiated(by: mode, at: head.frequency(of: mode))
            #expect(ring > seconds / 2 && ring < seconds * 2)
        }
    }

    @Test func `Straight above, only modes without diameters are heard, and a patch hears less of fine modes`() {
        let head = `Acoustics Tests`.Membrane.head
        let modes = head.modes(below: 3_000)
        for mode in modes where mode.diameters != 0 {
            #expect(head.beam(of: mode, at: head.frequency(of: mode), tilted: 0) == 0)
        }
        let round = modes.first { $0.diameters == 0 && $0.circles == 1 }!
        #expect(head.beam(of: round, at: 100, tilted: 0) != 0)
        let coarse = modes.min { $0.zero < $1.zero }!
        let fine = modes.max { $0.zero < $1.zero }!
        #expect(head.patch(of: fine, across: 0.015).magnitude < head.patch(of: coarse, across: 0.015))
        #expect(head.patch(of: coarse, across: 0) == 1)
    }
}
