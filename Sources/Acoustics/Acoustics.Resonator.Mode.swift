extension Acoustics.Resonator {
    public struct Mode: Hashable, Sendable {
        public var frequency: Double
        public var decay: Double
        public var mass: Double
        public var reach: Double
        public var stretch: Double
        public var heard: [Heard]

        public init(frequency: Double, decay: Double, mass: Double, reach: Double, stretch: Double = 0, heard: [Heard] = []) {
            self.frequency = frequency
            self.decay = decay
            self.mass = mass
            self.reach = reach
            self.stretch = stretch
            self.heard = heard
        }
    }
}
