importScripts("https://www.gstatic.com/firebasejs/9.6.10/firebase-app-compat.js");
importScripts("https://www.gstatic.com/firebasejs/9.6.10/firebase-messaging-compat.js");

firebase.initializeApp({
    apiKey: "AIzaSyAO7SOLjoFX8V8BrkbRaKlq-EVDLOaMg9I",
    authDomain: "mobile-app-db450.firebaseapp.com",
    projectId: "mobile-app-db450",
    storageBucket: "mobile-app-db450.firebasestorage.app",
    messagingSenderId: "1000078003954",
    appId: "1:1000078003954:web:4ac515cb79c256e30c8a6b",
    measurementId: "G-MFQNG9DKFQ"
});

const messaging = firebase.messaging();