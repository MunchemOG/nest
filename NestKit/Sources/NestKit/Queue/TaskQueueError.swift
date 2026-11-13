/// Why the queue refused a change.
public enum TaskQueueError: Error, Equatable {
    /// A task with this id is already in the queue.
    case duplicate(String)
    /// The task is not in the queue, or no run has claimed it.
    case notClaimed(String)
    /// A task can only be finished as done or held.
    case notAnEnd(QueueState)
}
