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


/* ===============================
   🔁 Notification Click Handler
=============================== */
self.addEventListener("notificationclick", function (event) {
    console.log("🔔 Notification Clicked:", event.notification.data);

    event.notification.close();

    event.waitUntil(
        clients.matchAll({ type: "window", includeUncontrolled: true })
            .then(function (clientList) {
                for (var i = 0; i < clientList.length; i++) {
                    var client = clientList[i];
                    if (client.url && "focus" in client) {
                        return client.focus();
                    }
                }
                if (clients.openWindow) {
                    return clients.openWindow("/");
                }
            })
    );
});