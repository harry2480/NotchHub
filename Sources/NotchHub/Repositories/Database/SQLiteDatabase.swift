import Foundation
import SQLite3

/// SQLite requires that text/blob bindings be copied because the Swift buffer
/// may be freed before the statement executes. `SQLITE_TRANSIENT` instructs
/// SQLite to make its own copy.
private let sqliteTransient = unsafeBitCast(-1, to: sqlite3_destructor_type.self)

/// A thin, throwing wrapper around the system SQLite3 C library.
///
/// Creation of the connection is intentionally confined to the Repository layer
/// (リポジトリ層設計規約.md); Service / ViewModel code never touches this type
/// directly. The wrapper offers parameterised `run`/`query`, transactions and
/// `user_version` access used by ``MigrationRunner``.
final class SQLiteDatabase {
    enum DatabaseError: Error, Equatable {
        case open(code: Int32, message: String)
        case prepare(code: Int32, message: String, sql: String)
        case step(code: Int32, message: String)
    }

    private var handle: OpaquePointer?

    /// Opens (creating if necessary) the database at `path`.
    init(path: String) throws {
        var connection: OpaquePointer?
        let flags = SQLITE_OPEN_READWRITE | SQLITE_OPEN_CREATE | SQLITE_OPEN_FULLMUTEX
        let result = sqlite3_open_v2(path, &connection, flags, nil)
        guard result == SQLITE_OK, let connection else {
            let message = connection.map { String(cString: sqlite3_errmsg($0)) } ?? "unknown"
            sqlite3_close(connection)
            throw DatabaseError.open(code: result, message: message)
        }
        handle = connection
        try exec("PRAGMA journal_mode = WAL;")
        try exec("PRAGMA foreign_keys = ON;")
    }

    /// Convenience for tests: an in-memory database.
    static func inMemory() throws -> SQLiteDatabase {
        try SQLiteDatabase(path: ":memory:")
    }

    deinit {
        if let handle {
            sqlite3_close(handle)
        }
    }

    /// Executes one or more statements that take no parameters and return no rows.
    func exec(_ sql: String) throws {
        var errorPointer: UnsafeMutablePointer<CChar>?
        let result = sqlite3_exec(handle, sql, nil, nil, &errorPointer)
        guard result == SQLITE_OK else {
            let message = errorPointer.map { String(cString: $0) } ?? errorMessage
            sqlite3_free(errorPointer)
            throw DatabaseError.step(code: result, message: message)
        }
    }

    /// Runs an insert/update/delete statement and returns the last inserted row id.
    @discardableResult
    func run(_ sql: String, _ parameters: [SQLiteValue] = []) throws -> Int64 {
        let statement = try prepare(sql, parameters)
        defer { sqlite3_finalize(statement) }
        let result = sqlite3_step(statement)
        guard result == SQLITE_DONE else {
            throw DatabaseError.step(code: result, message: errorMessage)
        }
        return sqlite3_last_insert_rowid(handle)
    }

    /// Runs a query and materialises all result rows.
    func query(_ sql: String, _ parameters: [SQLiteValue] = []) throws -> [SQLiteRow] {
        let statement = try prepare(sql, parameters)
        defer { sqlite3_finalize(statement) }

        let columnCount = sqlite3_column_count(statement)
        var names: [String] = []
        names.reserveCapacity(Int(columnCount))
        for index in 0 ..< columnCount {
            names.append(String(cString: sqlite3_column_name(statement, index)))
        }

        var rows: [SQLiteRow] = []
        while true {
            let result = sqlite3_step(statement)
            if result == SQLITE_ROW {
                var values: [String: SQLiteValue] = [:]
                for index in 0 ..< columnCount {
                    values[names[Int(index)]] = columnValue(statement, index)
                }
                rows.append(SQLiteRow(values))
            } else if result == SQLITE_DONE {
                break
            } else {
                throw DatabaseError.step(code: result, message: errorMessage)
            }
        }
        return rows
    }

    /// Runs `body` inside a transaction, rolling back on any thrown error.
    func transaction(_ body: () throws -> Void) throws {
        try exec("BEGIN;")
        do {
            try body()
            try exec("COMMIT;")
        } catch {
            try? exec("ROLLBACK;")
            throw error
        }
    }

    func userVersion() throws -> Int {
        let rows = try query("PRAGMA user_version;")
        return Int(rows.first?.int("user_version") ?? 0)
    }

    func setUserVersion(_ version: Int) throws {
        // PRAGMA does not accept bound parameters, so the integer is interpolated.
        try exec("PRAGMA user_version = \(version);")
    }

    // MARK: - Private

    private func prepare(_ sql: String, _ parameters: [SQLiteValue]) throws -> OpaquePointer? {
        var statement: OpaquePointer?
        let result = sqlite3_prepare_v2(handle, sql, -1, &statement, nil)
        guard result == SQLITE_OK, let statement else {
            sqlite3_finalize(statement)
            throw DatabaseError.prepare(code: result, message: errorMessage, sql: sql)
        }
        for (offset, value) in parameters.enumerated() {
            try bind(value, to: statement, at: Int32(offset + 1))
        }
        return statement
    }

    private func bind(_ value: SQLiteValue, to statement: OpaquePointer, at index: Int32) throws {
        let result: Int32 = switch value {
        case let .integer(number):
            sqlite3_bind_int64(statement, index, number)
        case let .real(number):
            sqlite3_bind_double(statement, index, number)
        case let .text(string):
            sqlite3_bind_text(statement, index, string, -1, sqliteTransient)
        case let .blob(data):
            data.withUnsafeBytes { buffer in
                sqlite3_bind_blob(statement, index, buffer.baseAddress, Int32(buffer.count), sqliteTransient)
            }
        case .null:
            sqlite3_bind_null(statement, index)
        }
        guard result == SQLITE_OK else {
            throw DatabaseError.step(code: result, message: errorMessage)
        }
    }

    private func columnValue(_ statement: OpaquePointer?, _ index: Int32) -> SQLiteValue {
        switch sqlite3_column_type(statement, index) {
        case SQLITE_INTEGER:
            return .integer(sqlite3_column_int64(statement, index))
        case SQLITE_FLOAT:
            return .real(sqlite3_column_double(statement, index))
        case SQLITE_TEXT:
            if let text = sqlite3_column_text(statement, index) {
                return .text(String(cString: text))
            }
            return .null
        case SQLITE_BLOB:
            if let bytes = sqlite3_column_blob(statement, index) {
                let count = Int(sqlite3_column_bytes(statement, index))
                return .blob(Data(bytes: bytes, count: count))
            }
            return .blob(Data())
        default:
            return .null
        }
    }

    private var errorMessage: String {
        handle.map { String(cString: sqlite3_errmsg($0)) } ?? "unknown"
    }
}
