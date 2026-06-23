/**
 * ============================================================
 *  🔐 config-loader-hybrid.js
 *  جرب المحلي أولاً، بعد كده جرب GitHub إذا فشل
 *  يعطيك أفضل الأداء والأمان
 * ============================================================
 */

const fs = require('fs');
const path = require('path');
const localConfig = require('./config-loader');
const remoteConfig = require('./config-loader-remote');

let cachedConfig = null;

/**
 * جرب المحلي أولاً
 */
function tryLocal() {
    try {
        return localConfig.getAll();
    } catch (err) {
        console.warn('⚠️ فشل جلب الـ config محلياً:', err.message);
        return null;
    }
}

/**
 * جيب قيمة واحدة (محلي أو GitHub)
 */
async function get(key) {
    // تحقق من الـ cache
    if (cachedConfig && cachedConfig[key]) {
        return cachedConfig[key];
    }

    // جرب المحلي
    const local = tryLocal();
    if (local) {
        cachedConfig = local;
        return local[key];
    }

    // جرب GitHub
    console.log('🌐 جاري جلب الـ config من GitHub...');
    try {
        const remote = await remoteConfig.getAll();
        cachedConfig = remote;
        return remote[key];
    } catch (err) {
        console.error(`❌ فشل جلب ${key} من أي مصدر`);
        throw err;
    }
}

/**
 * جيب كل القيم (محلي أو GitHub)
 */
async function getAll() {
    if (cachedConfig) {
        return { ...cachedConfig };
    }

    // جرب المحلي
    const local = tryLocal();
    if (local) {
        cachedConfig = local;
        return { ...local };
    }

    // جرب GitHub
    console.log('🌐 جاري جلب الـ config من GitHub...');
    try {
        const remote = await remoteConfig.getAll();
        cachedConfig = remote;
        return { ...remote };
    } catch (err) {
        console.error('❌ فشل جلب الـ config من أي مصدر');
        throw err;
    }
}

module.exports = {
    get,
    getAll,
    clearCache: () => { cachedConfig = null; }
};
