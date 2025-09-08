const fs = require('fs');
const readline = require('readline');
const { initializeFirebaseApp, backups } = require('firestore-export-import');

// ใส่ไฟล์ service account ของโปรเจกต์คุณ
const serviceAccount = require('./kanbanflowkey.json');

// ฟังก์ชันสำหรับสร้าง readline interface
const createReadlineInterface = () => {
  return readline.createInterface({
    input: process.stdin,
    output: process.stdout
  });
};

// ฟังก์ชันถามคำถาม
const askQuestion = (rl, question) => {
  return new Promise((resolve) => {
    rl.question(question, resolve);
  });
};

// รายชื่อ collections ที่พบบ่อย (สามารถปรับแต่งได้)
const commonCollections = [
  'users',
  'workspaces', 
  'boards',
  'cards',
  'lanes',
  'customers',
  'companies'
];

// ฟังก์ชันสำหรับกรอง keys ที่ต้องการ
const filterDataKeys = (data, keysToFilter) => {
  const filteredData = {};
  
  Object.keys(data).forEach(collectionName => {
    filteredData[collectionName] = {};
    
    Object.keys(data[collectionName]).forEach(docId => {
      const doc = data[collectionName][docId];
      filteredData[collectionName][docId] = {};
      
      // กรอง keys ที่ต้องการ
      keysToFilter.forEach(key => {
        if (doc.hasOwnProperty(key)) {
          filteredData[collectionName][docId][key] = doc[key];
        }
      });
    });
  });
  
  return filteredData;
};

// ฟังก์ชันสำหรับกรอง documents เฉพาะ
const filterDocuments = (data, documentsToExport) => {
  const filteredData = {};
  
  Object.keys(data).forEach(collectionName => {
    filteredData[collectionName] = {};
    
    documentsToExport.forEach(docId => {
      if (data[collectionName][docId]) {
        filteredData[collectionName][docId] = data[collectionName][docId];
      }
    });
  });
  
  return filteredData;
};

(async () => {
  const rl = createReadlineInterface();
  
  try {
    console.log('🚀 Firestore Export Tool');
    console.log('========================');
    
    // แสดงตัวเลือก
    console.log('เลือกวิธีการ export:');
    console.log('1. Export ทุก collection');
    console.log('2. เลือก collection เฉพาะ');
    console.log('3. เลือกจาก collection ที่พบบ่อย');
    console.log('4. Export collection พร้อมกรอง keys เฉพาะ');
    console.log('5. Export document เฉพาะจาก collection');
    
    const choice = await askQuestion(rl, '\nป้อนตัวเลือก (1-5): ');
    
    let collectionsToExport = null;
    let exportMode = '';
    let keysToFilter = null;
    let documentsToExport = null;
    
    if (choice === '1') {
      exportMode = 'all';
      console.log('✅ เลือก: Export ทุก collection');
      
    } else if (choice === '2') {
      exportMode = 'custom';
      console.log('\n📝 ตัวอย่าง: users, workspaces, boards');
      console.log('📝 หรือ: customers, companies');
      console.log('📝 หรือเพียง: users');
      const customCollections = await askQuestion(rl, '\nป้อนชื่อ collection (คั่นด้วยเครื่องหมายจุลภาค): ');
      collectionsToExport = customCollections.split(',').map(name => name.trim()).filter(name => name);
      
      if (collectionsToExport.length === 0) {
        console.log('❌ ไม่ได้ระบุ collection ใดๆ');
        rl.close();
        return;
      }
      
      console.log('✅ เลือก collection:', collectionsToExport);
      
    } else if (choice === '3') {
      exportMode = 'common';
      console.log('\nCollection ที่พบบ่อย:');
      commonCollections.forEach((col, index) => {
        console.log(`${index + 1}. ${col}`);
      });
      
      const indices = await askQuestion(rl, '\n📝 ตัวอย่าง: 1,2,3 หรือ 1,4 หรือ all\nเลือกหมายเลข collection: ');
      
      if (indices.toLowerCase() === 'all') {
        collectionsToExport = commonCollections;
      } else {
        const selectedIndices = indices.split(',').map(i => parseInt(i.trim()) - 1);
        collectionsToExport = selectedIndices
          .filter(i => i >= 0 && i < commonCollections.length)
          .map(i => commonCollections[i]);
      }
      console.log('✅ เลือก collection:', collectionsToExport);
      
    } else if (choice === '4') {
      exportMode = 'filtered';
      
      // เลือก collection
      console.log('\nCollection ที่พบบ่อย:');
      commonCollections.forEach((col, index) => {
        console.log(`${index + 1}. ${col}`);
      });
      
      const collectionChoice = await askQuestion(rl, '\nเลือก collection (ใส่หมายเลข): ');
      const collectionIndex = parseInt(collectionChoice) - 1;
      
      if (collectionIndex < 0 || collectionIndex >= commonCollections.length) {
        console.log('❌ หมายเลข collection ไม่ถูกต้อง');
        rl.close();
        return;
      }
      
      collectionsToExport = [commonCollections[collectionIndex]];
      
      // เลือก keys
      console.log('\n📝 ตัวอย่าง keys: id, name, email');
      console.log('📝 หรือ: title, status, assignee');
      console.log('📝 หรือ: *  (สำหรับทุก keys)');
      const keysInput = await askQuestion(rl, '\nป้อน keys ที่ต้องการ (คั่นด้วยเครื่องหมายจุลภาค): ');
      
      if (keysInput.trim() === '*') {
        keysToFilter = null; // Export ทุก keys
      } else {
        keysToFilter = keysInput.split(',').map(key => key.trim()).filter(key => key);
        if (keysToFilter.length === 0) {
          console.log('❌ ไม่ได้ระบุ keys ใดๆ');
          rl.close();
          return;
        }
      }
      
      console.log('✅ เลือก collection:', collectionsToExport);
      console.log('✅ เลือก keys:', keysToFilter || 'ทุก keys');
      
    } else if (choice === '5') {
      exportMode = 'documents';
      
      // เลือก collection
      console.log('\nCollection ที่พบบ่อย:');
      commonCollections.forEach((col, index) => {
        console.log(`${index + 1}. ${col}`);
      });
      
      const collectionChoice = await askQuestion(rl, '\nเลือก collection (ใส่หมายเลข): ');
      const collectionIndex = parseInt(collectionChoice) - 1;
      
      if (collectionIndex < 0 || collectionIndex >= commonCollections.length) {
        console.log('❌ หมายเลข collection ไม่ถูกต้อง');
        rl.close();
        return;
      }
      
      collectionsToExport = [commonCollections[collectionIndex]];
      
      // เลือก document IDs
      console.log('\n📝 ตัวอย่าง document IDs: xKnLu20t7n6A0IJxl4NN');
      console.log('📝 หรือหลาย documents: doc1, doc2, doc3');
      const docsInput = await askQuestion(rl, '\nป้อน document IDs ที่ต้องการ (คั่นด้วยเครื่องหมายจุลภาค): ');
      
      documentsToExport = docsInput.split(',').map(id => id.trim()).filter(id => id);
      if (documentsToExport.length === 0) {
        console.log('❌ ไม่ได้ระบุ document ID ใดๆ');
        rl.close();
        return;
      }
      
      console.log('✅ เลือก collection:', collectionsToExport);
      console.log('✅ เลือก documents:', documentsToExport);
      
    } else {
      console.log('❌ ตัวเลือกไม่ถูกต้อง');
      rl.close();
      return;
    }
    
    rl.close();
    
    console.log('\n🔄 กำลัง export ข้อมูล...');
    
    const firestore = initializeFirebaseApp(serviceAccount);
    
    // Export ตามที่เลือก
    let data = collectionsToExport 
      ? await backups(firestore, collectionsToExport)
      : await backups(firestore);
    
    // กรอง keys ถ้าเลือกโหมด filtered
    if (exportMode === 'filtered' && keysToFilter) {
      data = filterDataKeys(data, keysToFilter);
    }
    
    // กรอง documents ถ้าเลือกโหมด documents
    if (exportMode === 'documents' && documentsToExport) {
      data = filterDocuments(data, documentsToExport);
    }
    
    // สร้างชื่อไฟล์ตาม collection ที่เลือก
    const now = new Date().toISOString().replace(/[:.]/g, '-').slice(0, 19);
    let filename;
    
    if (exportMode === 'all') {
      filename = `backup-all-${now}.json`;
    } else if (exportMode === 'documents' && documentsToExport.length === 1) {
      const collectionName = collectionsToExport[0];
      const docId = documentsToExport[0];
      filename = `backup-${collectionName}-${docId}-${now}.json`;
    } else if (exportMode === 'documents') {
      const collectionName = collectionsToExport[0];
      filename = `backup-${collectionName}-docs(${documentsToExport.length})-${now}.json`;
    } else if (collectionsToExport && collectionsToExport.length === 1) {
      const collectionName = collectionsToExport[0];
      const keySuffix = keysToFilter ? `-keys(${keysToFilter.join(',')})` : '';
      filename = `backup-${collectionName}${keySuffix}-${now}.json`;
    } else if (collectionsToExport && collectionsToExport.length <= 3) {
      const collectionNames = collectionsToExport.join('-');
      filename = `backup-${collectionNames}-${now}.json`;
    } else {
      filename = `backup-multiple-${now}.json`;
    }
    
    fs.writeFileSync(filename, JSON.stringify(data, null, 2));
    
    console.log(`✅ Export สำเร็จ!`);
    console.log(`📁 ไฟล์: ${filename}`);
    console.log(`📊 Collections ที่ export:`, Object.keys(data));
    console.log(`💾 ขนาดไฟล์: ${(fs.statSync(filename).size / 1024 / 1024).toFixed(2)} MB`);
    
  } catch (e) {
    console.error('❌ Export failed:', e);
    rl.close();
    process.exit(1);
  }
})();
