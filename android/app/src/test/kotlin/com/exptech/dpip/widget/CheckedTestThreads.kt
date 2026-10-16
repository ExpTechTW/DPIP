package com.exptech.dpip.widget

import java.util.concurrent.atomic.AtomicReference

/** Test-owned threads: bounded completion and failures reported on the JUnit thread. */
internal class CheckedTestThreads : AutoCloseable {
    private class Entry(val thread: Thread, val failure: AtomicReference<Throwable?>)
    private val entries = ArrayList<Entry>()

    fun start(name: String, action: () -> Unit): Thread {
        val failure = AtomicReference<Throwable?>(null)
        val thread = Thread({
            try {
                action()
            } catch (error: Throwable) {
                failure.set(error)
            }
        }, name).apply { isDaemon = true }
        entries.add(Entry(thread, failure))
        thread.start()
        return thread
    }

    fun await(thread: Thread) {
        thread.join(10_000)
        check(!thread.isAlive) { "${thread.name} did not finish (state=${thread.state})" }
        entries.single { it.thread === thread }.failure.getAndSet(null)?.let { throw it }
    }

    /** Observe actual monitor contention, not merely elapsed scheduling time. */
    fun awaitBlockedIn(thread: Thread, className: String, methodName: String) {
        val deadline = System.nanoTime() + java.util.concurrent.TimeUnit.SECONDS.toNanos(10)
        while (System.nanoTime() < deadline) {
            entries.single { it.thread === thread }.failure.getAndSet(null)?.let { throw it }
            if (thread.state == Thread.State.BLOCKED && thread.stackTrace.firstOrNull()?.let {
                    it.className == className && it.methodName == methodName
                } == true) return
            check(thread.isAlive) { "${thread.name} completed without blocking in $className.$methodName" }
            Thread.yield()
        }
        error("${thread.name} did not block in $className.$methodName (state=${thread.state})")
    }

    override fun close() {
        // Callers release their latches in finally before closing this owner.
        // Interrupt is a fallback for a failed test, never its scheduling signal.
        entries.filter { it.thread.isAlive }.forEach { it.thread.interrupt() }
        var failure: Throwable? = null
        for (entry in entries) {
            try {
                await(entry.thread)
            } catch (error: Throwable) {
                val previous = failure
                if (previous == null) failure = error else if (previous !== error) previous.addSuppressed(error)
            }
        }
        failure?.let { throw it }
    }
}
