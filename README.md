# Parallel

A module made for easier task usage and execution

This module provides following object-oriented methods:
### `.New()`:
Creates new parallel object with methods and a `finished` boolean property

### `:Run()`:
Runs current task and throws error if there's any errors in function

### `:Clean()`:
Cleans up everything, including internal instances
Highly recomended to call this function once execution is finished

### `:RunOnEnd(...: parallelObject)`:
Runs task after provided set of tasks have finished

# Non-Object-oriented methods:

### `.WaitForEnd(...: parallelObject)`:
Yields until provided set of tasks finish their execution
