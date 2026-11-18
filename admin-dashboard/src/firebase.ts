import { initializeApp, getApps, getApp } from 'firebase/app';
import { getAuth, GoogleAuthProvider } from 'firebase/auth';
import { getFirestore } from 'firebase/firestore';

// Firebase Web Configuration
// Default values correspond to project drislam-magdy (from google-services.json)
const firebaseConfig = {
  apiKey: import.meta.env.VITE_FIREBASE_API_KEY || 'AIzaSyCYuBDDgaedA8_O0GQsmurW53Qi6WTs4o4',
  authDomain: import.meta.env.VITE_FIREBASE_AUTH_DOMAIN || 'drislam-magdy.firebaseapp.com',
  projectId: import.meta.env.VITE_FIREBASE_PROJECT_ID || 'drislam-magdy',
  storageBucket: import.meta.env.VITE_FIREBASE_STORAGE_BUCKET || 'drislam-magdy.firebasestorage.app',
  messagingSenderId: import.meta.env.VITE_FIREBASE_MESSAGING_SENDER_ID || '562869901758',
  appId: import.meta.env.VITE_FIREBASE_APP_ID || '1:562869901758:web:7b72f087b07cd7550c01ef',
};

// Initialize Firebase App
const app = getApps().length === 0 ? initializeApp(firebaseConfig) : getApp();

export const auth = getAuth(app);
export const db = getFirestore(app);
export const googleProvider = new GoogleAuthProvider();

export default app;
