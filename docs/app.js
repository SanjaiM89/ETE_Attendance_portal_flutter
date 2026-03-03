// ── Configuration ────────────────────────────────────────────
const REPO_OWNER = 'S-Harish2005';
const REPO_NAME = 'ETE_STUDENT_BACKEND';

// Asset prefix → button ID mapping
const ASSET_MAP = {
    'ETE-Windows': 'dl-ETE-Windows',
    'ETE-macOS': 'dl-ETE-macOS',
    'ETE-iOS': 'dl-ETE-iOS',
    'ETE-APK': 'dl-ETE-APK',
    'ETE-Linux-AppImage': 'dl-ETE-Linux-AppImage',
    'ETE_ADMIN-Windows': 'dl-ETE_ADMIN-Windows',
    'ETE_ADMIN-macOS': 'dl-ETE_ADMIN-macOS',
    'ETE_ADMIN-iOS': 'dl-ETE_ADMIN-iOS',
    'ETE_ADMIN-APK': 'dl-ETE_ADMIN-APK',
    'ETE_ADMIN-Linux-AppImage': 'dl-ETE_ADMIN-Linux-AppImage',
};

// ── Fetch latest release & wire up buttons ───────────────────
async function init() {
    const loadingEl = document.getElementById('loading');
    const platformsEl = document.getElementById('platforms');
    const badgeEl = document.getElementById('release-badge');
    const tagEl = document.getElementById('release-tag');

    try {
        // Try "latest" first, fall back to first release in list
        let data;
        const latestRes = await fetch(`https://api.github.com/repos/${REPO_OWNER}/${REPO_NAME}/releases/latest`);
        if (latestRes.ok) {
            data = await latestRes.json();
        } else {
            const listRes = await fetch(`https://api.github.com/repos/${REPO_OWNER}/${REPO_NAME}/releases?per_page=1`);
            if (!listRes.ok) throw new Error('No releases');
            const list = await listRes.json();
            if (!list.length) throw new Error('No releases');
            data = list[0];
        }

        const assets = data.assets || [];

        // Show release tag
        tagEl.textContent = data.tag_name || data.name || 'Latest';
        loadingEl.classList.add('hidden');
        platformsEl.classList.remove('hidden');
        badgeEl.classList.remove('hidden');

        // Match assets to buttons
        for (const [prefix, btnId] of Object.entries(ASSET_MAP)) {
            const asset = assets.find(a => a.name.startsWith(prefix));
            const btn = document.getElementById(btnId);
            if (asset && btn) {
                btn.href = asset.browser_download_url;
                btn.target = '_blank';
                btn.rel = 'noopener';
                btn.classList.remove('disabled');
                btn.classList.add('ready');
            }
        }

    } catch (err) {
        console.error('Release fetch failed:', err);
        loadingEl.innerHTML = `<span style="color:#f87171">⚠ Could not load releases. <a href="https://github.com/${REPO_OWNER}/${REPO_NAME}/releases" target="_blank">View on GitHub →</a></span>`;
        // Still show the platform cards as disabled
        platformsEl.classList.remove('hidden');
    }
}

init();
