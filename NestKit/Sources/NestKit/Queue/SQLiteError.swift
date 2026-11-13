/// A failure reported by SQLite, with its result code.
struct SQLiteError: Error, Equatable {
    let code: Int32
    let message: String
}
