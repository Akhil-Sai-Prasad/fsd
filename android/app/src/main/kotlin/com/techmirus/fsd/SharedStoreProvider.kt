package com.techmirus.fsd

import android.content.ContentProvider
import android.content.ContentValues
import android.database.Cursor
import android.net.Uri
import android.os.Bundle
import com.tencent.mmkv.MMKV

/**
 * Owner of the suite's shared key/value store.
 *
 * The MMKV instance lives in FSD's own sandbox and is only ever touched from
 * this one process, which is what MMKV is actually designed for. QT and LT
 * reach it over Binder; access is gated by a signature-level permission, so
 * only apps signed with the same certificate can call in.
 *
 * This provider is `call()`-only — a key/value store is RPC-shaped, and going
 * through query()/insert() would mean mapping everything through Cursors for
 * no benefit.
 */
class SharedStoreProvider : ContentProvider() {

    companion object {
        const val AUTHORITY = "com.techmirus.sharedstore.provider"
        private const val STORE_ID = "techmirus-shared-store"
        private val BASE_URI: Uri = Uri.parse("content://$AUTHORITY")

        /** `entity.customers` -> `content://<authority>/entity/customers` */
        private fun uriForKey(key: String): Uri {
            val builder = BASE_URI.buildUpon()
            key.split('.').forEach { builder.appendPath(it) }
            return builder.build()
        }
    }

    private var kv: MMKV? = null

    override fun onCreate(): Boolean {
        val ctx = context ?: return false
        MMKV.initialize(ctx)
        // Empty in local builds; injected at build time in CI. See
        // android/app/build.gradle.kts.
        val cryptKey = BuildConfig.SHARED_STORE_KEY.ifEmpty { null }
        kv = MMKV.mmkvWithID(STORE_ID, MMKV.SINGLE_PROCESS_MODE, cryptKey)
        return kv != null
    }

    override fun call(method: String, arg: String?, extras: Bundle?): Bundle? {
        val store = kv ?: return null
        val key = arg.orEmpty()

        return when (method) {
            "get" -> Bundle().apply { putString("value", store.decodeString(key)) }

            "set" -> {
                val value = extras?.getString("value") ?: return null
                store.encode(key, value)
                notifyChanged(key)
                Bundle().apply { putBoolean("ok", true) }
            }

            "delete" -> {
                store.removeValueForKey(key)
                notifyChanged(key)
                Bundle().apply { putBoolean("ok", true) }
            }

            // `key` is a prefix here, e.g. "entity." for every entity record.
            "keys" -> {
                val all = store.allKeys() ?: emptyArray()
                Bundle().apply {
                    putStringArray(
                        "keys",
                        all.filter { it.startsWith(key) }.toTypedArray(),
                    )
                }
            }

            else -> null
        }
    }

    /**
     * Wakes every registered [android.database.ContentObserver] in the suite,
     * across app boundaries. This is what lets LT redraw when QT saves without
     * anyone firing a deep link.
     */
    private fun notifyChanged(key: String) {
        context?.contentResolver?.notifyChange(uriForKey(key), null)
    }

    // --- unsupported: this provider exposes no table surface ------------------

    override fun query(
        uri: Uri,
        projection: Array<out String>?,
        selection: String?,
        selectionArgs: Array<out String>?,
        sortOrder: String?,
    ): Cursor? = null

    override fun getType(uri: Uri): String? = null

    override fun insert(uri: Uri, values: ContentValues?): Uri? = null

    override fun delete(
        uri: Uri,
        selection: String?,
        selectionArgs: Array<out String>?,
    ): Int = 0

    override fun update(
        uri: Uri,
        values: ContentValues?,
        selection: String?,
        selectionArgs: Array<out String>?,
    ): Int = 0
}
