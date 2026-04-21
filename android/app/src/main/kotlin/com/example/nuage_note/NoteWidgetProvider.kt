package com.example.nuage_note

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetPlugin

class NoteWidgetProvider : AppWidgetProvider() {

    companion object {
        private const val MAX_PINNED = 2
        private const val MAX_RECENT = 3
    }

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        val prefs = HomeWidgetPlugin.getData(context)

        for (widgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.note_widget_layout)

            // Bouton "+" : ouvre l'app sur une nouvelle note
            val newNoteIntent = createLaunchIntent(context, "noteapp://new")
            views.setOnClickPendingIntent(R.id.widget_add_button, newNoteIntent)

            // Pinned notes
            val pinnedIds = mutableListOf<String>()
            val pinnedTitles = mutableListOf<String>()
            for (i in 1..MAX_PINNED) {
                val id = prefs.getString("pinned_${i}_id", null)
                val title = prefs.getString("pinned_${i}_title", null)
                if (!id.isNullOrEmpty() && !title.isNullOrEmpty()) {
                    pinnedIds.add(id)
                    pinnedTitles.add(title)
                }
            }

            if (pinnedTitles.isNotEmpty()) {
                views.setViewVisibility(R.id.widget_pinned_header, View.VISIBLE)
            } else {
                views.setViewVisibility(R.id.widget_pinned_header, View.GONE)
            }

            bindSlot(
                context, views,
                slotId = R.id.widget_pinned_1,
                titleViewId = R.id.widget_pinned_1_title,
                title = pinnedTitles.getOrNull(0),
                noteId = pinnedIds.getOrNull(0)
            )
            bindSlot(
                context, views,
                slotId = R.id.widget_pinned_2,
                titleViewId = R.id.widget_pinned_2_title,
                title = pinnedTitles.getOrNull(1),
                noteId = pinnedIds.getOrNull(1)
            )

            // Recent notes
            val recentIds = mutableListOf<String>()
            val recentTitles = mutableListOf<String>()
            for (i in 1..MAX_RECENT) {
                val id = prefs.getString("recent_${i}_id", null)
                val title = prefs.getString("recent_${i}_title", null)
                if (!id.isNullOrEmpty() && !title.isNullOrEmpty()) {
                    recentIds.add(id)
                    recentTitles.add(title)
                }
            }

            if (recentTitles.isNotEmpty()) {
                views.setViewVisibility(R.id.widget_recent_header, View.VISIBLE)
            } else {
                views.setViewVisibility(R.id.widget_recent_header, View.GONE)
            }

            bindRecentText(
                context, views,
                viewId = R.id.widget_recent_1,
                title = recentTitles.getOrNull(0),
                noteId = recentIds.getOrNull(0)
            )
            bindRecentText(
                context, views,
                viewId = R.id.widget_recent_2,
                title = recentTitles.getOrNull(1),
                noteId = recentIds.getOrNull(1)
            )
            bindRecentText(
                context, views,
                viewId = R.id.widget_recent_3,
                title = recentTitles.getOrNull(2),
                noteId = recentIds.getOrNull(2)
            )

            // État vide
            val isEmpty = pinnedTitles.isEmpty() && recentTitles.isEmpty()
            views.setViewVisibility(
                R.id.widget_empty,
                if (isEmpty) View.VISIBLE else View.GONE
            )

            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }

    private fun bindSlot(
        context: Context,
        views: RemoteViews,
        slotId: Int,
        titleViewId: Int,
        title: String?,
        noteId: String?
    ) {
        if (title.isNullOrEmpty() || noteId.isNullOrEmpty()) {
            views.setViewVisibility(slotId, View.GONE)
            return
        }
        views.setViewVisibility(slotId, View.VISIBLE)
        views.setTextViewText(titleViewId, title)
        views.setOnClickPendingIntent(
            slotId,
            createLaunchIntent(context, "noteapp://open?id=$noteId")
        )
    }

    private fun bindRecentText(
        context: Context,
        views: RemoteViews,
        viewId: Int,
        title: String?,
        noteId: String?
    ) {
        if (title.isNullOrEmpty() || noteId.isNullOrEmpty()) {
            views.setViewVisibility(viewId, View.GONE)
            return
        }
        views.setViewVisibility(viewId, View.VISIBLE)
        views.setTextViewText(viewId, title)
        views.setOnClickPendingIntent(
            viewId,
            createLaunchIntent(context, "noteapp://open?id=$noteId")
        )
    }

    private fun createLaunchIntent(context: Context, deeplink: String): PendingIntent {
        val intent = Intent(context, MainActivity::class.java).apply {
            action = Intent.ACTION_VIEW
            data = Uri.parse(deeplink)
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        return PendingIntent.getActivity(
            context,
            deeplink.hashCode(),
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
    }
}
