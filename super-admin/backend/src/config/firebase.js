import admin from "firebase-admin";
import serviceAccount from "../mobile-app-db450-firebase-adminsdk-fbsvc-c73a1cfa75.json" assert { type: "json" };

admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
});

export default admin;
