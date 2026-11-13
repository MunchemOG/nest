/// A value stored in or read from one SQLite column.
enum SQLiteValue: Equatable {
    case integer(Int)
    case text(String)
    case null

    var integer: Int? { if case .integer(let value) = self { value } else { nil } }
    var text: String? { if case .text(let value) = self { value } else { nil } }
}
