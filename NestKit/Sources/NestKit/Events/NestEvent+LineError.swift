extension NestEvent {
    /// A JSONL line that did not decode as an event.
    public struct LineError: Error, Sendable {
        /// The line's number, counting from 1.
        public let line: Int
        /// Why it did not decode.
        public let underlying: any Error
    }
}
