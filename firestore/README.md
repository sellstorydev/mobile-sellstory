# Firestore Export

Simple script to export all Firestore collections to `backup.json` using a service account key.

## Prereqs
- Node.js 18+
- A Firebase service account JSON saved as `kanbanflowkey.json` in this folder (never commit this file).

## Install
```
npm ci
```

## Run
```
node export.js
```

The export writes `backup.json` with all collections by default. To limit collections, edit `export.js` and pass an array to `backups()`.

## Quick inspect of backup.json
Use these one-liners to sanity‑check the export without writing extra scripts:

- List collection names
	```sh
	node -e "const d=require('./backup.json'); console.log(Object.keys(d))"
	```

- Count documents in a collection (example: users)
	```sh
	node -e "const d=require('./backup.json'); console.log(Object.keys(d.users||{}).length)"
	```

- Show first 3 document IDs (example: users)
	```sh
	node -e "const d=require('./backup.json'); console.log(Object.keys(d.users||{}).slice(0,3))"
	```

คำสั่งตรวจไฟล์อย่างเร็ว (ภาษาไทย):
- แสดงชื่อคอลเลกชันทั้งหมด: คำสั่งแรก
- นับจำนวนเอกสารในคอลเลกชัน (เช่น users): คำสั่งที่สอง
- ดูตัวอย่างรหัสเอกสาร 3 รายการแรก: คำสั่งที่สาม

## Notes
- `.gitignore` excludes `backup.json` and the key file.
- Rotate keys regularly and restrict IAM permissions to minimum needed (Firestore Viewer).
