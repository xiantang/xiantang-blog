```scala
object Future {
  def apply[T](body: => T)(implicit executor: ExecutionContext): Future[T] =
    unit.map(_ => body)
}
```

a Java framework for supporting a style of parallel programming in which problems are solved by (recursively) splitting them into subtasks that are solved in parallel, waiting for them to complete, and then composing results

1.INTRODUCTION

The fork operation starts a new parallel fork/join subtask.

The join operation causes the current task not to proceed until the forked subtask has completed. 





java.lang.Thread and POSIX pthread are suboptimal vehicles

for supporting fork/join programs

* Fork/join tasks have simple and regular synchronization and management requirements.For example, fork/join tasks never need to block except to wait out subtasks. Thus, the overhead and bookkeeping necessary for tracking blocked general−purpose threads are wasted.



Work-Stealing 

* Each worker thread maintains runnable tasks in its own scheduling queue.
* Queues are maintained as double−ended queues (i.e., deques, usually pronounced "decks"), supporting both LIFO push and pop operations, as well as a FIFO take operation. 
* Worker threads process their own deques in LIFO (youngest−first) order, by popping tasks.
* Subtasks generated in tasks run by a given worker thread are pushed onto that workers own deque.

 

