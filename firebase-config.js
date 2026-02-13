/* ============================================
   MediMinder – Firebase Configuration
   ============================================ */

const firebaseConfig = {
    apiKey: "AIzaSyAQMJraoGryH1oNItrBUIn9p9XtY0N-loo",
    authDomain: "mediminder-b5a14.firebaseapp.com",
    projectId: "mediminder-b5a14",
    storageBucket: "mediminder-b5a14.firebasestorage.app",
    messagingSenderId: "82374151917",
    appId: "1:82374151917:web:4cc8d3ee66b27fe51cc6e4",
    measurementId: "G-JHDRRZCGF9"
};

// Initialize Firebase
firebase.initializeApp(firebaseConfig);

// Initialize services
const auth = firebase.auth();
const db = firebase.firestore();

// Enable offline persistence
db.enablePersistence({ synchronizeTabs: true })
    .catch((err) => {
        if (err.code === 'failed-precondition') {
            console.warn('[Firebase] Multiple tabs open, persistence can only be enabled in one tab.');
        } else if (err.code === 'unimplemented') {
            console.warn('[Firebase] Browser does not support persistence.');
        }
    });

console.log('[Firebase] Initialized');
