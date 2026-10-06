package com.wekacert

import org.junit.jupiter.api.Assertions.assertEquals
import org.junit.jupiter.api.Test

class AppTest {
    @Test
    fun sprintOnePrioritiesStayOrderedFromRequirements() {
        val app = App()

        assertEquals(4, app.sprintOnePriorities.size)
        assertEquals("1.1", app.sprintOnePriorities[0].id)
        assertEquals("1.2", app.sprintOnePriorities[1].id)
        assertEquals("1.3", app.sprintOnePriorities[2].id)
        assertEquals("1.4", app.sprintOnePriorities[3].id)
    }

    @Test
    fun nextPriorityTaskReturnsFirstItem() {
        val app = App()

        assertEquals(PriorityTask("1.1", "Set up project repository (Flutter/Kotlin)"), app.nextPriorityTask())
    }
}
