// Preserve Marketplace's Glassy theme, replacing only its cover-art backdrop.
(() => {
    const id = "glassy-transparent-backdrop";
    if (document.getElementById(id)) return;
    const style = document.createElement("style");
    style.id = id;
    style.textContent = `
        html:root {
            --glass-accent: rgb(235, 235, 235) !important;
            --glass-accent-ink: #171717 !important;
        }
        html:root, html body { background: transparent !important; }
        #glass-bg { display: none !important; }
        #glass-bg .glass-layer { background-image: none !important; }
    `;
    (document.head || document.documentElement).appendChild(style);

    // Neutralize only Glassy's warm surface/text colors; preserve images and layout.
    const neutralize = () => {
        for (const sheet of document.querySelectorAll("style.marketplaceUserCSS")) {
            const original = sheet.textContent;
            if (!original.includes("--glass-tint")) continue;
            const neutral = original
                .replace(/rgba\(255,\s*(?:244,\s*228|246,\s*232|250,\s*242),/g, "rgba(255, 255, 255,")
                .replace(/rgba\((?:20,\s*14,\s*10|24,\s*18,\s*13|22,\s*16,\s*11|12,\s*8,\s*6|13,\s*9,\s*6),/g, "rgba(18, 18, 18,")
                .replace(/#(?:fff6e8|cfc3ac|9c8f78|f0c24f|e8b847|f3c95e|c99a2e|1a120b|0d0906)\b/gi, color => ({
                    "#fff6e8": "#f6f6f6", "#cfc3ac": "#c7c7c7",
                    "#9c8f78": "#929292", "#f0c24f": "#e8e8e8",
                    "#e8b847": "#dedede", "#f3c95e": "#eeeeee",
                    "#c99a2e": "#b4b4b4", "#1a120b": "#171717",
                    "#0d0906": "#0b0b0b"
                })[color.toLowerCase()]);
            if (neutral !== original) sheet.textContent = neutral;
        }
    };
    const observer = new MutationObserver(records => {
        if (records.some(record => record.target.nodeName === "STYLE" ||
            record.target.parentElement?.nodeName === "STYLE" ||
            Array.from(record.addedNodes).some(node => node.nodeName === "STYLE"))) neutralize();
    });
    observer.observe(document.documentElement, { childList: true, subtree: true, characterData: true });
    neutralize();
})();
