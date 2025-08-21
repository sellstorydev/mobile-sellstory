const fs = require('fs');
const { initializeFirebaseApp, backups } = require('firestore-export-import');

// ใส่ไฟล์ service account ของโปรเจกต์คุณ
const serviceAccount = require('./kanbanflowkey.json');

(async () => {
  try {
    const firestore = initializeFirebaseApp(serviceAccount); // ใช้ค่า databaseURL จากไฟล์นี้ได้เลย
    // ดึงทุกคอลเลกชัน (จะครอบคลุม subcollections ในโครงสร้างผลลัพธ์ด้วย)
    const data = await backups(firestore /*, ['users','workspaces'] ใส่ชื่อคอลเลกชันเฉพาะได้ */);
    const now = new Date().toISOString().replace(/[:.]/g, '-').slice(0, 19);
    const filename = `backup-${now}.json`;
    fs.writeFileSync(filename, JSON.stringify(data, null, 2));
    console.log(`✅ Export done. File: ${filename}, Collections:`, Object.keys(data));
  } catch (e) {
    console.error('❌ Export failed:', e);
    process.exit(1);
  }
})();
