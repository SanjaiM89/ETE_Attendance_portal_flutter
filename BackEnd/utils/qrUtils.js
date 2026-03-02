const QRCode = require("qrcode");
const { createCanvas, loadImage } = require("canvas");
const path = require("path");

exports.generateQRWithLogo = async (dataString) => {
    try {
        const width = 300;

        // High error correction (H) is required to allow replacing the center with a logo
        const canvas = createCanvas(width, width);
        await QRCode.toCanvas(canvas, dataString, {
            errorCorrectionLevel: "H",
            width,
            margin: 1
        });

        const ctx = canvas.getContext("2d");

        // The node script runs from BackEnd/, so the logo absolute path is ../logo.png
        const logoPath = path.join(__dirname, "../../logo.png");

        const logo = await loadImage(logoPath);

        // Center logo dimensions
        const logoSize = 60; // 20% of width
        const x = (width - logoSize) / 2;
        const y = (width - logoSize) / 2;

        // Draw white background for logo context
        ctx.fillStyle = "white";
        ctx.fillRect(x - 2, y - 2, logoSize + 4, logoSize + 4);

        // Draw the main logo image
        ctx.drawImage(logo, x, y, logoSize, logoSize);

        return canvas.toDataURL("image/png");
    } catch (error) {
        console.error("⚠ Outputting standard QR Code without logo due to an error:", error.message);
        return await QRCode.toDataURL(dataString);
    }
};
