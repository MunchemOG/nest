import Foundation
import SQLite3

/// One connection to an SQLite file, using the SQLite that ships with macOS.
final class SQLiteDatabase {
    private var handle: OpaquePointer?

    /// Opens the file at `url`, creating it if needed; waits up to `busyTimeout` seconds when another connection is writing.
    init(at url: URL, busyTimeout: Double = 5) throws {
        let flags = SQLITE_OPEN_READWRITE | SQLITE_OPEN_CREATE | SQLITE_OPEN_FULLMUTEX
        guard sqlite3_open_v2(url.path, &handle, flags, nil) == SQLITE_OK else {
            let error = SQLiteError(code: sqlite3_errcode(handle), message: String(cString: sqlite3_errmsg(handle)))
            sqlite3_close_v2(handle)
            throw error
        }
        sqlite3_busy_timeout(handle, Int32(busyTimeout * 1000))
    }

    deinit {
        sqlite3_close_v2(handle)
    }

    /// The number of rows the last statement changed.
    var changes: Int { Int(sqlite3_changes(handle)) }

    /// Runs `sql` with `values` bound to its `?` placeholders, ignoring any rows.
    func execute(_ sql: String, _ values: [SQLiteValue] = []) throws {
        _ = try rows(sql, values)
    }

    /// Runs `sql` with `values` bound to its `?` placeholders and returns every row it yields.
    func rows(_ sql: String, _ values: [SQLiteValue] = []) throws -> [[SQLiteValue]] {
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(handle, sql, -1, &statement, nil) == SQLITE_OK else { throw lastError }
        defer { sqlite3_finalize(statement) }
        for (offset, value) in values.enumerated() {
            let index = Int32(offset + 1)
            switch value {
            case .integer(let number): sqlite3_bind_int64(statement, index, Int64(number))
            case .text(let string): sqlite3_bind_text(statement, index, string, -1, Self.transient)
            case .null: sqlite3_bind_null(statement, index)
            }
        }
        var result: [[SQLiteValue]] = []
        while true {
            switch sqlite3_step(statement) {
            case SQLITE_ROW:
                result.append((0..<sqlite3_column_count(statement)).map { column(statement, $0) })
            case SQLITE_DONE:
                return result
            default:
                throw lastError
            }
        }
    }

    /// Runs `body` inside a transaction that takes the write lock first, so no other connection writes in between.
    func writing<T>(_ body: () throws -> T) throws -> T {
        try execute("BEGIN IMMEDIATE")
        do {
            let result = try body()
            try execute("COMMIT")
            return result
        } catch {
            try? execute("ROLLBACK")
            throw error
        }
    }

    private func column(_ statement: OpaquePointer?, _ index: Int32) -> SQLiteValue {
        switch sqlite3_column_type(statement, index) {
        case SQLITE_INTEGER: .integer(Int(sqlite3_column_int64(statement, index)))
        case SQLITE_NULL: .null
        default: .text(String(cString: sqlite3_column_text(statement, index)))
        }
    }

    private var lastError: SQLiteError {
        SQLiteError(code: sqlite3_extended_errcode(handle), message: String(cString: sqlite3_errmsg(handle)))
    }

    /// Tells SQLite to copy bound text, since Swift's string buffer does not outlive the call.
    private static let transient = unsafeBitCast(-1, to: sqlite3_destructor_type.self)
}
