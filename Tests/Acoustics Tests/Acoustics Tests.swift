import Acoustics
import Testing

enum `Acoustics Tests` {}

extension `Acoustics Tests` {
    @Suite struct Air {}
}

extension `Acoustics Tests`.Air {
    @Test func `Air in a room is 1.204 kilograms a cubic metre and carries sound at 343.2 metres a second`() {
        #expect(Acoustics.Air.room.density == 1.204)
        #expect(Acoustics.Air.room.speed == 343.2)
    }
}
