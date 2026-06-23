/**
 * ============================================================
 *  🔐 config-loader-remote.js
 *  يجيب الـ config المفكوك من GitHub Releases
 *  الاستخدام:
 *      const config = require('./config-loader-remote');
 *      const token  = await config.get('GITHUB_TOKEN');
 * ============================================================
 */

const https = require('https');
const cache = {};
const CACHE_TTL = 3600000; // ساعة واحدة

/**
 * جيب الآخر Release اللي فيها config-decrypted.json
 */
async function fetchLatestConfigFromRelease(owner, repo) {
    return new Promise((resolve, reject) => {
        const options = {
            hostname: 'api.github.com',
            path: `/repos/${owner}/${repo}/releases/latest`,
            method: 'GET',
            headers: {
                'User-Agent': 'Panda-Toolbox',
                'Accept': 'application/vnd.github.v3+json'
            }
        };

        https.request(options, (res) => {
            let data = '';
            res.on('data', chunk => data += chunk);
            res.on('end', () => {
                try {
                    const release = JSON.parse(data);
                    const asset = release.assets?.find(a => a.name === 'config-decrypted.json');
                    
                    if (!asset) {
                        reject(new Error('❌ ملف config-decrypted.json مش موجود في Release'));
                        return;
                    }

                    // جيب محتوى الملف
                    const downloadOptions = {
                        hostname: 'github.com',
                        path: asset.browser_download_url.replace('https://github.com', ''),
                        method: 'GET',
                        headers: { 'User-Agent': 'Panda-Toolbox' }
                    };

                    https.request(downloadOptions, (downloadRes) => {
                        let configData = '';
                        downloadRes.on('data', chunk => configData += chunk);
                        downloadRes.on('end', () => {
                            try {
                                const config = JSON.parse(configData);
                                resolve(config);
                            } catch (e) {
                                reject(new Error(`❌ فشل parsing الـ config: ${e.message}`));
                            }
                        });
                    }).on('error', reject).end();

                } catch (e) {
                    reject(new Error(`❌ فشل parsing Release: ${e.message}`));
                }
            });
        }).on('error', reject).end();
    });
}

/**
 * جيب قيمة واحدة (مع caching)
 */
async function get(key, owner = 'pg0panda', repo = 'KEYS') {
    const cacheKey = `${owner}/${repo}`;
    
    // تحقق من الـ cache
    if (cache[cacheKey] && Date.now() - cache[cacheKey].timestamp < CACHE_TTL) {
        return cache[cacheKey].data[key];
    }

    try {
        const config = await fetchLatestConfigFromRelease(owner, repo);
        cache[cacheKey] = {
            data: config,
            timestamp: Date.now()
        };
        return config[key];
    } catch (err) {
        console.error(`❌ خطأ في جلب الـ config: ${err.message}`);
        throw err;
    }
}

/**
 * جيب كل القيم (مع caching)
 */
async function getAll(owner = 'pg0panda', repo = 'KEYS') {
    const cacheKey = `${owner}/${repo}`;
    
    if (cache[cacheKey] && Date.now() - cache[cacheKey].timestamp < CACHE_TTL) {
        return { ...cache[cacheKey].data };
    }

    try {
        const config = await fetchLatestConfigFromRelease(owner, repo);
        cache[cacheKey] = {
            data: config,
            timestamp: Date.now()
        };
        return { ...config };
    } catch (err) {
        console.error(`❌ خطأ في جلب الـ config: ${err.message}`);
        throw err;
    }
}

module.exports = {
    get,
    getAll,
    clearCache: () => Object.keys(cache).forEach(k => delete cache[k])
};
