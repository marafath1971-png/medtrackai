package com.medtracker.medtrackaiflutter

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Paint
import android.graphics.RectF
import android.net.Uri
import android.view.View
import android.widget.RemoteViews
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

/**
 * Home-screen steps widget: today's ring and count, plus the walking
 * partner's count when paired.
 *
 * The widget does not read steps itself. The app pushes a snapshot over the
 * `com.medtrackai.widget` channel (see MainActivity) and this draws it. A
 * snapshot from an earlier day is shown as "open to update" rather than as
 * today's number.
 */
class StepsWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(context: Context, manager: AppWidgetManager, ids: IntArray) {
        val views = render(context)
        ids.forEach { manager.updateAppWidget(it, views) }
    }

    companion object {
        private const val PREFS = "steps_widget"
        private const val LIME = 0xFFB4E869.toInt()
        private const val PARTNER_BLUE = 0xFF8AB4FF.toInt()
        private const val TRACK = 0x1FFFFFFF

        /** Stores the snapshot sent from Dart and redraws every placed widget. */
        fun save(context: Context, args: Map<*, *>) {
            context.getSharedPreferences(PREFS, Context.MODE_PRIVATE).edit()
                .putBoolean("enabled", args["enabled"] as? Boolean ?: false)
                .putInt("steps", (args["steps"] as? Number)?.toInt() ?: 0)
                .putInt("goal", (args["goal"] as? Number)?.toInt() ?: 0)
                .putInt("streak", (args["streak"] as? Number)?.toInt() ?: 0)
                .putString("partnerName", args["partnerName"] as? String ?: "")
                .putInt("partnerSteps", (args["partnerSteps"] as? Number)?.toInt() ?: -1)
                .putInt("partnerGoal", (args["partnerGoal"] as? Number)?.toInt() ?: 0)
                .putString("day", today())
                .apply()
            updateAll(context)
        }

        private fun updateAll(context: Context) {
            val manager = AppWidgetManager.getInstance(context)
            val ids = manager.getAppWidgetIds(
                ComponentName(context, StepsWidgetProvider::class.java)
            )
            if (ids.isNotEmpty()) manager.updateAppWidget(ids, render(context))
        }

        private fun today(): String =
            SimpleDateFormat("yyyy-MM-dd", Locale.US).format(Date())

        private fun group(n: Int): String = String.format(Locale.US, "%,d", n)

        private fun render(context: Context): RemoteViews {
            val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            val views = RemoteViews(context.packageName, R.layout.steps_widget)

            val enabled = prefs.getBoolean("enabled", false)
            val fresh = prefs.getString("day", "") == today()
            val goal = prefs.getInt("goal", 0)
            val steps = if (fresh) prefs.getInt("steps", 0) else 0
            val partnerName = prefs.getString("partnerName", "") ?: ""
            val partnerRaw = prefs.getInt("partnerSteps", -1)
            val hasPartner = enabled && partnerRaw >= 0
            val partnerSteps = if (fresh && hasPartner) partnerRaw else 0
            val partnerGoal = prefs.getInt("partnerGoal", 0)

            val mine = if (goal > 0) steps.toFloat() / goal else 0f
            val theirs = if (partnerGoal > 0) partnerSteps.toFloat() / partnerGoal else 0f
            val px = (context.resources.displayMetrics.density * 120).toInt()
            views.setImageViewBitmap(
                R.id.steps_widget_ring,
                ring(px, mine, if (hasPartner) theirs else null)
            )

            if (!enabled) {
                views.setTextViewText(R.id.steps_widget_count, "–")
                views.setTextViewText(
                    R.id.steps_widget_goal,
                    context.getString(R.string.steps_widget_steps)
                )
                views.setTextViewText(
                    R.id.steps_widget_footer,
                    context.getString(R.string.steps_widget_turn_on)
                )
            } else {
                views.setTextViewText(R.id.steps_widget_count, group(steps))
                views.setTextViewText(
                    R.id.steps_widget_goal,
                    context.getString(R.string.steps_widget_of_goal, group(goal))
                )
                val footer = when {
                    !fresh -> context.getString(R.string.steps_widget_open_to_update)
                    hasPartner -> context.getString(
                        R.string.steps_widget_partner,
                        partnerName.ifEmpty {
                            context.getString(R.string.steps_widget_partner_fallback)
                        },
                        group(partnerSteps)
                    )
                    prefs.getInt("streak", 0) > 1 -> context.getString(
                        R.string.steps_widget_streak, prefs.getInt("streak", 0)
                    )
                    goal > steps -> context.getString(
                        R.string.steps_widget_to_go, group(goal - steps)
                    )
                    else -> context.getString(R.string.steps_widget_goal_reached)
                }
                views.setTextViewText(R.id.steps_widget_footer, footer)
            }
            views.setViewVisibility(R.id.steps_widget_footer, View.VISIBLE)

            // medai://steps is routed by LinkService to the steps screen.
            val open = Intent(Intent.ACTION_VIEW, Uri.parse("medai://steps"))
                .setPackage(context.packageName)
                .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            views.setOnClickPendingIntent(
                android.R.id.background,
                PendingIntent.getActivity(
                    context, 0, open,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )
            )
            return views
        }

        /** One ring for a solo walker, two concentric rings when paired. */
        private fun ring(size: Int, mine: Float, partner: Float?): Bitmap {
            val bitmap = Bitmap.createBitmap(size, size, Bitmap.Config.ARGB_8888)
            val canvas = Canvas(bitmap)
            val stroke = size * if (partner == null) 0.09f else 0.07f
            val paint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
                style = Paint.Style.STROKE
                strokeWidth = stroke
                strokeCap = Paint.Cap.ROUND
            }

            fun arc(inset: Float, progress: Float, color: Int) {
                val box = RectF(inset, inset, size - inset, size - inset)
                paint.color = TRACK
                canvas.drawArc(box, 0f, 360f, false, paint)
                val sweep = 360f * progress.coerceIn(0f, 1f)
                if (sweep > 0.5f) {
                    paint.color = color
                    canvas.drawArc(box, -90f, sweep, false, paint)
                }
            }

            arc(stroke / 2, mine, LIME)
            if (partner != null) arc(stroke * 1.5f + size * 0.025f, partner, PARTNER_BLUE)
            return bitmap
        }
    }
}
