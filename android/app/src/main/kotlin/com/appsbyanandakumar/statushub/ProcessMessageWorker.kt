package com.appsbyanandakumar.statushub

import android.content.Context
import android.database.sqlite.SQLiteDatabase
import android.database.sqlite.SQLiteOpenHelper
import androidx.work.Worker
import androidx.work.WorkerParameters

class ProcessMessageWorker(context: Context, workerParams: WorkerParameters) : Worker(context, workerParams) {
    override fun doWork(): Result {
        return Result.success()
    }
}

class MessagesDbHelper(context: Context) :
    SQLiteOpenHelper(context, "messages.db", null, 2) {

    override fun onCreate(db: SQLiteDatabase) {
        db.execSQL(
            """
            CREATE TABLE IF NOT EXISTS messages (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                sender TEXT NOT NULL,
                message TEXT NOT NULL,
                packageName TEXT NOT NULL,
                timestamp TEXT NOT NULL,
                notificationKey TEXT,
                isDeleted INTEGER NOT NULL DEFAULT 0
            )
            """
        )
    }

    override fun onUpgrade(db: SQLiteDatabase, oldVersion: Int, newVersion: Int) {
        db.execSQL("DROP TABLE IF EXISTS messages")
        onCreate(db)
    }

    // ✅ FIX: Force Native Android to use WAL mode.
    // This stops it from trying to switch to TRUNCATE and locking the DB.
    override fun onConfigure(db: SQLiteDatabase) {
        super.onConfigure(db)
        db.setForeignKeyConstraintsEnabled(true)
        db.enableWriteAheadLogging()
    }
}