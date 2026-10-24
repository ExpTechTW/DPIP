package com.exptech.dpip.widget

/** UI-only feedback, not a claim about observation freshness or server time. */
enum class WidgetRefreshFeedback(val wire: String) {
    Queued("queued"), Running("running"), Updated("updated"), Failed("failed");

    val durationMilliseconds: Long
        get() = if (this == Updated) 30_000L else 120_000L
}

internal data class StoredWidgetRefreshFeedback(
    val state: WidgetRefreshFeedback,
    val expiresAtMilliseconds: Long,
)
