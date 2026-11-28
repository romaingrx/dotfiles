## Threads at work at one time

Heavy work in many threads at once has taken this machine down before. So
`start.sh` refuses a new thread while three threads work or start on the
machine, in any project.

- Start one thread at a time, and see it at work before the next start. Two
  starts at once both pass the check.
- A message to a thread that rests makes it work. While three threads work,
  hold such a message, unless the person waits for its answer.
- When `start.sh` refuses a thread, tell the person that the task waits. Write
  the task and the path of its task file in the memory. Remove that line in
  the turn in which the thread starts.
- Try the start again at each report of a thread and at each message of the
  person.
