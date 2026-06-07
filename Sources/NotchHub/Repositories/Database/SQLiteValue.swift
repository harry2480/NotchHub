import Foundation

/// A typed SQLite cell value used for binding parameters and reading columns.
/// Keeping the bridge explicit avoids leaking raw C pointers above the
/// Repository layer (リポジトリ層設計規約.md).
enum SQLiteValue: Equatable {
    case integer(Int64)
    case real(Double)
    case text(String)
    case blob(Data)
    case null
}

extension SQLiteValue {
    init(_ value: Int) {
        self = .integer(Int64(value))
    }

    init(_ value: Int64) {
        self = .integer(value)
    }

    init(_ value: Double) {
        self = .real(value)
    }

    init(_ value: String) {
        self = .text(value)
    }

    init(_ value: Bool) {
        self = .integer(value ? 1 : 0)
    }

    init(_ value: Data) {
        self = .blob(value)
    }

    /// Maps an optional to its value or `.null`.
    static func optional(_ value: String?) -> SQLiteValue {
        value.map(SQLiteValue.text) ?? .null
    }

    static func optional(_ value: Data?) -> SQLiteValue {
        value.map(SQLiteValue.blob) ?? .null
    }
}

/// One row returned by a query, addressed by column name with typed accessors.
struct SQLiteRow {
    private let columns: [String: SQLiteValue]

    init(_ columns: [String: SQLiteValue]) {
        self.columns = columns
    }

    subscript(_ name: String) -> SQLiteValue? {
        columns[name]
    }

    func int(_ name: String) -> Int64? {
        if case let .integer(value)? = columns[name] { return value }
        return nil
    }

    func double(_ name: String) -> Double? {
        if case let .real(value)? = columns[name] { return value }
        return nil
    }

    func string(_ name: String) -> String? {
        if case let .text(value)? = columns[name] { return value }
        return nil
    }

    func data(_ name: String) -> Data? {
        if case let .blob(value)? = columns[name] { return value }
        return nil
    }

    func bool(_ name: String) -> Bool? {
        int(name).map { $0 != 0 }
    }
}
