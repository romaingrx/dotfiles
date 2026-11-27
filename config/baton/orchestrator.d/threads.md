## Threads at work at one time

At most three threads work at one time on a machine: heavy work in many
threads at once has taken this machine down before. `start.sh` refuses a
fourth one. Tell the person then that the task waits, write it in the memory
as waiting, and start it when a thread ends.
