// Import the Firebase Admin SDK and Cloud Functions SDK
const functions = require("firebase-functions");
const admin = require("firebase-admin");

// Initialize the Firebase Admin SDK
// When deployed to Cloud Functions, this often initializes automatically.
// For local testing, ensure it's initialized.
admin.initializeApp();

/**
 * 1. Cloud Function to notify Admin when a Mechanic updates a Job Status.
 *    Listens for updates to documents in the 'jobs' collection.
 */
exports.notifyAdminOnJobStatusUpdate = functions.firestore
    .document("jobs/{jobId}")
    .onUpdate(async (change, context) => {
      const newData = change.after.data(); // Data after the update
      const previousData = change.before.data(); // Data before the update
      const jobId = context.params.jobId;

      // Check if the 'status' field actually changed
      if (newData.status === previousData.status) {
        console.log(`Job ${jobId} status did not change. 
          No notification sent.`);
        return null; // Exit if status hasn't changed
      }

      console.log(`Job ${jobId} status changed from 
        "${previousData.status}" to "${newData.status}"`);

      // Fetch all admin users' FCM tokens
      try {
        const adminUsersSnapshot = await admin.firestore().collection("users")
            .where("role", "==", "admin")
            .get();

        if (adminUsersSnapshot.empty) {
          console.log("No admin users found to notify.");
          return null;
        }

        const adminFCMTokens = [];
        adminUsersSnapshot.forEach((doc) => {
          const userData = doc.data();
          if (userData.fcmTokens && Array.isArray(userData.fcmTokens)) {
            adminFCMTokens.push(...userData.fcmTokens);
            // Add all tokens for this admin
          }
        });

        if (adminFCMTokens.length === 0) {
          console.log("No FCM tokens found for admin users.");
          return null;
        }

        // Construct the notification message for admins
        const message = {
          notification: {
            title: "Job Status Update!",
            body: `Job "${newData.title || jobId}" 
            status changed to: ${newData.status}`,
          },
          data: {
            jobId: jobId,
            newStatus: newData.status,
          // Add any other data your admin app
          // might need to handle the notification
          },
          tokens: adminFCMTokens, // Send to multiple tokens at once
        };

        // Send the message
        const response = await admin.messaging().sendEachForMulticast(message);
        console.log("Successfully sent notifications to admins:", response);
        // Log successes and failures
        response.responses.forEach((resp, idx) => {
          if (resp.success) {
            console.log(`Message to token 
              ${adminFCMTokens[idx]} sent successfully.`);
          } else {
            console.error(`Failed to send message to token 
              ${adminFCMTokens[idx]}:`, resp.error);
          }
        });
        return null;
      } catch (error) {
        console.error("Error sending notification to admins:", error);
        return null;
      }
    });


/**
 * 2. Cloud Function to notify Mechanic when an Admin assigns a new Job.
 *    Listens for creation of documents in the 'jobs' collection.
 */
exports.notifyMechanicOnJobAssignment = functions.firestore
    .document("jobs/{jobId}")
    .onCreate(async (snapshot, context) => {
      const newJobData = snapshot.data();
      const jobId = context.params.jobId;

      const assignedMechanicId = newJobData.assignedMechanicId;

      if (!assignedMechanicId) {
        console.log(`Job ${jobId} has no assigned mechanic. 
          No notification sent.`);
        return null;
      }

      console.log(`New job ${jobId} assigned 
        to mechanic ID: ${assignedMechanicId}`);

      // Fetch the assigned mechanic's FCM tokens
      try {
        const mechanicDoc = await admin.firestore().collection("users")
            .doc(assignedMechanicId).get();

        if (!mechanicDoc.exists) {
          console.log(`Mechanic with ID ${assignedMechanicId} not found.`);
          return null;
        }

        const mechanicData = mechanicDoc.data();
        const mechanicFCMTokens = [];
        if (mechanicData.fcmTokens && Array.isArray(mechanicData.fcmTokens)) {
          mechanicFCMTokens.push(...mechanicData.fcmTokens);
        }

        if (mechanicFCMTokens.length === 0) {
          console.log(`No FCM tokens found for 
            mechanic ID: ${assignedMechanicId}.`);
          return null;
        }

        // Construct the notification message for the mechanic
        const message = {
          notification: {
            title: "New Job Assigned!",
            body: `You have been assigned a new job: 
            "${newJobData.title || "Untitled Job"}".`,
          },
          data: {
            jobId: jobId,
          // Add any other data your mechanic app
          // might need to handle the notification
          },
          tokens: mechanicFCMTokens,
          // Send to multiple tokens if mechanic has multiple devices
        };

        // Send the message
        const response = await admin.messaging().sendEachForMulticast(message);
        console.log("Successfully sent notification to mechanic:", response);
        response.responses.forEach((resp, idx) => {
          if (resp.success) {
            console.log(`Message to token 
              ${mechanicFCMTokens[idx]} sent successfully.`);
          } else {
            console.error(`Failed to send message to token 
              ${mechanicFCMTokens[idx]}:`, resp.error);
          }
        });
        return null;
      } catch (error) {
        console.error("Error sending notification to mechanic:", error);
        return null;
      }
    });

