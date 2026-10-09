import SwiftUI
import Combine

// 8i6: @State replacement.
// In the macOS 27 SDK, @State is a macro whose plugin (SwiftUIMacros) only ships
// with full Xcode; with just the Command Line Tools the build fails.
// @LocalState does the same job on top of @StateObject, which is not a macro.

final class LocalStateBox<Value>: ObservableObject {
    @Published var value: Value
    init(_ value: Value) { self.value = value }
}

@propertyWrapper
struct LocalState<Value>: DynamicProperty {
    @StateObject private var box: LocalStateBox<Value>

    init(wrappedValue: Value) {
        _box = StateObject(wrappedValue: LocalStateBox(wrappedValue))
    }

    /// Allows `@LocalState private var x: Type?` without an initial value (like @State).
    init() where Value: ExpressibleByNilLiteral {
        self.init(wrappedValue: nil)
    }

    var wrappedValue: Value {
        get { box.value }
        nonmutating set { box.value = newValue }
    }

    var projectedValue: Binding<Value> {
        let box = self.box
        return Binding(get: { box.value }, set: { box.value = $0 })
    }
}
