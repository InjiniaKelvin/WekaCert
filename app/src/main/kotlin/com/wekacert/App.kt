package com.wekacert

data class PriorityTask(
    val id: String,
    val description: String,
)

class App {
    val sprintOnePriorities: List<PriorityTask> = listOf(
        PriorityTask("1.1", "Set up project repository (Flutter/Kotlin)"),
        PriorityTask("1.2", "Implement secure local storage using encrypted SQLite"),
        PriorityTask("1.3", "Develop document upload UI"),
        PriorityTask("1.4", "Test offline document storage"),
    )

    fun nextPriorityTask(): PriorityTask = sprintOnePriorities.first()
}

fun main() {
    val app = App()
    val nextTask = app.nextPriorityTask()
    println("Next implementation priority: Task ${nextTask.id} - ${nextTask.description}")
}
