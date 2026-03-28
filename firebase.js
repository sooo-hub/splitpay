// firebase.js
// ⚠️ このファイルを .gitignore に追加するか、
//    環境変数を使って API キーを隠してください

import { initializeApp } from 'firebase/app';
import { getFirestore } from 'firebase/firestore';

// warikan-tool プロジェクトの Firebase 設定
const firebaseConfig = {
  apiKey: "AIzaSyDaJpPgP2GVg7aI1Yxrnsj9qYIcoHbJRu4",
  authDomain: "warikan-tool.firebaseapp.com",
  projectId: "warikan-tool",
  storageBucket: "warikan-tool.firebasestorage.app",
  messagingSenderId: "174776494764",
  appId: "1:174776494764:web:a7ec5a053877f19a0a8d09",
  measurementId: "G-N92RK0KRBZ",
};

const app = initializeApp(firebaseConfig);
export const db = getFirestore(app);
