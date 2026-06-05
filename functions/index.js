/**
 * eKora Cloud Functions
 * Handles: payment initiation/verification, ranking updates, notifications.
 *
 * Deploy: firebase deploy --only functions
 */

const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();
const db = admin.firestore();

// ─────────────────────────────────────────────────────────────────────────────
// PAYMENTS
// ─────────────────────────────────────────────────────────────────────────────

/**
 * initiatePayment — creates a pending payment record and returns a
 * payment reference/intent. Integrates with Vodafone Cash / Fawry APIs
 * in production; returns a simulated reference in sandbox mode.
 *
 * Called by: PaymentNotifier.initiatePayment()
 */
exports.initiatePayment = functions
  .region("europe-west1")
  .https.onCall(async (data, context) => {
    // ── Auth guard ──────────────────────────────────────────────────────────
    if (!context.auth) {
      throw new functions.https.HttpsError(
        "unauthenticated",
        "User must be authenticated."
      );
    }

    const { tournamentId, amount, method, userId, phoneNumber } = data;

    // ── Input validation ────────────────────────────────────────────────────
    if (!tournamentId || !amount || !method || !userId) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "Missing required payment fields."
      );
    }

    if (amount <= 0) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "Amount must be greater than zero."
      );
    }

    // Ensure the caller matches the userId (prevent spoofing)
    if (context.auth.uid !== userId) {
      throw new functions.https.HttpsError(
        "permission-denied",
        "User ID mismatch."
      );
    }

    // ── Verify tournament exists and is joinable ────────────────────────────
    const tournamentRef = db.collection("tournaments").doc(tournamentId);
    const tournament = await tournamentRef.get();

    if (!tournament.exists) {
      throw new functions.https.HttpsError("not-found", "Tournament not found.");
    }

    const tData = tournament.data();
    if (tData.status !== "upcoming") {
      throw new functions.https.HttpsError(
        "failed-precondition",
        "Tournament is not open for registration."
      );
    }

    if (tData.currentParticipants >= tData.maxParticipants) {
      throw new functions.https.HttpsError(
        "resource-exhausted",
        "Tournament is full."
      );
    }

    // ── Check user hasn't already joined ───────────────────────────────────
    const participants = tData.participantIds || [];
    if (participants.includes(userId)) {
      throw new functions.https.HttpsError(
        "already-exists",
        "User has already joined this tournament."
      );
    }

    // ── Generate payment reference ─────────────────────────────────────────
    // In production: call Vodafone Cash / Fawry / Stripe API here.
    // Below is the integration structure — replace with real API calls.
    let transactionRef;

    if (method === "vodafone_cash") {
      // TODO: Call Vodafone Cash Merchant API
      // const vcResponse = await callVodafoneCashAPI({ phoneNumber, amount, reference });
      // transactionRef = vcResponse.transactionId;
      transactionRef = `VC-${Date.now()}-${Math.random().toString(36).substr(2, 8).toUpperCase()}`;
    } else if (method === "fawry") {
      // TODO: Call Fawry Payment API
      // const fawryResponse = await callFawryAPI({ amount, referenceNumber });
      // transactionRef = fawryResponse.referenceNumber;
      transactionRef = `FW-${Date.now()}-${Math.random().toString(36).substr(2, 8).toUpperCase()}`;
    } else if (method === "credit_card") {
      // TODO: Integrate Stripe / PayMob
      // const paymentIntent = await stripe.paymentIntents.create({ amount: amount * 100, currency: 'egp' });
      // transactionRef = paymentIntent.client_secret;
      transactionRef = `CC-${Date.now()}-${Math.random().toString(36).substr(2, 8).toUpperCase()}`;
    } else {
      throw new functions.https.HttpsError("invalid-argument", "Unsupported payment method.");
    }

    // ── Create payment document ─────────────────────────────────────────────
    const paymentId = db.collection("payments").doc().id;
    await db.collection("payments").doc(paymentId).set({
      userId,
      tournamentId,
      tournamentTitle: tData.title,
      amount,
      method,
      status: "pending",
      transactionId: transactionRef,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    functions.logger.info(`Payment initiated: ${paymentId} for user ${userId}`);

    return { paymentId, transactionRef };
  });

/**
 * verifyPayment — validates a payment against the payment provider
 * and updates Firestore status. Called after the user completes payment.
 *
 * IMPORTANT: Never trust the frontend to mark payments as complete.
 * All verification must happen server-side here.
 */
exports.verifyPayment = functions
  .region("europe-west1")
  .https.onCall(async (data, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError("unauthenticated", "Must be authenticated.");
    }

    const { paymentId, transactionId } = data;

    if (!paymentId || !transactionId) {
      throw new functions.https.HttpsError("invalid-argument", "Missing paymentId or transactionId.");
    }

    // ── Fetch payment record ────────────────────────────────────────────────
    const paymentRef = db.collection("payments").doc(paymentId);
    const paymentSnap = await paymentRef.get();

    if (!paymentSnap.exists) {
      throw new functions.https.HttpsError("not-found", "Payment record not found.");
    }

    const payment = paymentSnap.data();

    // Ensure caller owns the payment
    if (payment.userId !== context.auth.uid) {
      throw new functions.https.HttpsError("permission-denied", "Access denied.");
    }

    if (payment.status === "completed") {
      return { verified: true, alreadyCompleted: true };
    }

    // ── Verify with payment provider ───────────────────────────────────────
    // In production: call the provider API to confirm the transaction.
    // Below is the structure — replace with real API calls.
    let verified = false;

    if (payment.method === "vodafone_cash") {
      // verified = await verifyVodafoneCashTransaction(transactionId, payment.amount);
      verified = true; // DEMO: auto-verify
    } else if (payment.method === "fawry") {
      // verified = await verifyFawryPayment(transactionId);
      verified = true; // DEMO: auto-verify
    } else if (payment.method === "credit_card") {
      // verified = await stripe.paymentIntents.retrieve(transactionId).status === 'succeeded';
      verified = true; // DEMO: auto-verify
    }

    if (!verified) {
      await paymentRef.update({ status: "failed" });
      return { verified: false };
    }

    // ── Atomic: mark payment complete + join tournament ────────────────────
    const batch = db.batch();

    batch.update(paymentRef, {
      status: "completed",
      completedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    const tournamentRef = db.collection("tournaments").doc(payment.tournamentId);
    batch.update(tournamentRef, {
      participantIds: admin.firestore.FieldValue.arrayUnion(payment.userId),
      currentParticipants: admin.firestore.FieldValue.increment(1),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    await batch.commit();

    // ── Send confirmation notification ─────────────────────────────────────
    const userDoc = await db.collection("users").doc(payment.userId).get();
    const fcmToken = userDoc.data()?.fcmToken;

    if (fcmToken) {
      await admin.messaging().send({
        token: fcmToken,
        notification: {
          title: "Payment Confirmed! 🎮",
          body: `You've joined ${payment.tournamentTitle}. Good luck!`,
        },
        data: {
          route: `/home/tournaments/${payment.tournamentId}`,
          type: "payment_confirmed",
        },
        android: { priority: "high" },
        apns: { payload: { aps: { sound: "default" } } },
      });
    }

    functions.logger.info(`Payment verified: ${paymentId}`);
    return { verified: true };
  });

// ─────────────────────────────────────────────────────────────────────────────
// RANKINGS
// ─────────────────────────────────────────────────────────────────────────────

/**
 * updateRankings — recalculates global rank positions.
 * Triggered by an admin callable or scheduled job.
 */
exports.updateRankings = functions
  .region("europe-west1")
  .https.onCall(async (data, context) => {
    // Admin-only
    if (!context.auth) {
      throw new functions.https.HttpsError("unauthenticated", "Must be authenticated.");
    }

    const callerDoc = await db.collection("users").doc(context.auth.uid).get();
    if (callerDoc.data()?.role !== "admin") {
      throw new functions.https.HttpsError("permission-denied", "Admins only.");
    }

    const usersSnap = await db
      .collection("users")
      .orderBy("points", "desc")
      .get();

    const batch = db.batch();
    usersSnap.docs.forEach((doc, index) => {
      batch.update(doc.ref, { globalRank: index + 1 });
    });
    await batch.commit();

    functions.logger.info(`Rankings updated for ${usersSnap.size} users`);
    return { updated: usersSnap.size };
  });

/**
 * Scheduled rankings update — runs daily at midnight Cairo time (UTC+2 = 22:00 UTC).
 */
exports.scheduledRankingsUpdate = functions
  .region("europe-west1")
  .pubsub.schedule("0 22 * * *")
  .timeZone("Africa/Cairo")
  .onRun(async () => {
    const usersSnap = await db
      .collection("users")
      .orderBy("points", "desc")
      .get();

    const batch = db.batch();
    usersSnap.docs.forEach((doc, index) => {
      batch.update(doc.ref, { globalRank: index + 1 });
    });
    await batch.commit();
    functions.logger.info(`Scheduled rankings updated: ${usersSnap.size} users`);
  });

// ─────────────────────────────────────────────────────────────────────────────
// NOTIFICATIONS
// ─────────────────────────────────────────────────────────────────────────────

/**
 * sendTournamentNotification — sends a push notification to all tournament
 * participants. Called by admin actions.
 */
exports.sendTournamentNotification = functions
  .region("europe-west1")
  .https.onCall(async (data, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError("unauthenticated", "Must be authenticated.");
    }

    const callerDoc = await db.collection("users").doc(context.auth.uid).get();
    if (callerDoc.data()?.role !== "admin") {
      throw new functions.https.HttpsError("permission-denied", "Admins only.");
    }

    const { tournamentId, title, body } = data;
    if (!tournamentId || !title || !body) {
      throw new functions.https.HttpsError("invalid-argument", "Missing fields.");
    }

    const tournamentDoc = await db.collection("tournaments").doc(tournamentId).get();
    if (!tournamentDoc.exists) {
      throw new functions.https.HttpsError("not-found", "Tournament not found.");
    }

    const participantIds = tournamentDoc.data().participantIds || [];
    if (participantIds.length === 0) return { sent: 0 };

    // Fetch FCM tokens for all participants
    const userDocs = await Promise.all(
      participantIds.map((uid) => db.collection("users").doc(uid).get())
    );

    const tokens = userDocs
      .filter((d) => d.exists && d.data().fcmToken)
      .map((d) => d.data().fcmToken);

    if (tokens.length === 0) return { sent: 0 };

    // Send via FCM topic for efficiency (subscribe users to topic on join)
    const message = {
      topic: `tournament_${tournamentId}`,
      notification: { title, body },
      data: { tournamentId, type: "tournament_update" },
      android: { priority: "high" },
      apns: { payload: { aps: { sound: "default" } } },
    };

    await admin.messaging().send(message);
    functions.logger.info(`Notification sent to tournament ${tournamentId}: ${tokens.length} recipients`);

    return { sent: tokens.length };
  });

// ─────────────────────────────────────────────────────────────────────────────
// TOURNAMENT LIFECYCLE TRIGGERS
// ─────────────────────────────────────────────────────────────────────────────

/**
 * onTournamentStatusChange — fires when a tournament's status field changes.
 * Sends notifications and handles cleanup.
 */
exports.onTournamentStatusChange = functions
  .region("europe-west1")
  .firestore.document("tournaments/{tournamentId}")
  .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after = change.after.data();

    if (before.status === after.status) return null;

    const { tournamentId } = context.params;
    const participantIds = after.participantIds || [];

    let notifTitle = "";
    let notifBody = "";

    if (after.status === "live") {
      notifTitle = "Tournament Started! 🎮";
      notifBody = `${after.title} is now LIVE! Good luck!`;
    } else if (after.status === "finished") {
      notifTitle = "Tournament Ended 🏆";
      notifBody = `${after.title} has finished. Check the results!`;
    } else if (after.status === "cancelled") {
      notifTitle = "Tournament Cancelled";
      notifBody = `${after.title} has been cancelled.`;

      // Refund logic would go here (call payment provider APIs)
    }

    if (!notifTitle || participantIds.length === 0) return null;

    try {
      await admin.messaging().send({
        topic: `tournament_${tournamentId}`,
        notification: { title: notifTitle, body: notifBody },
        data: { tournamentId, type: "status_change", status: after.status },
      });
      functions.logger.info(
        `Status-change notification sent for tournament ${tournamentId}: ${after.status}`
      );
    } catch (err) {
      functions.logger.error("Notification failed:", err);
    }

    return null;
  });

/**
 * onUserCreated — seed default user stats when a new user signs up.
 */
exports.onUserCreated = functions
  .region("europe-west1")
  .auth.user()
  .onCreate(async (user) => {
    const userRef = db.collection("users").doc(user.uid);
    const existing = await userRef.get();

    // Only set defaults if the document doesn't already exist
    // (social login creates it before this trigger fires)
    if (!existing.exists) {
      await userRef.set({
        uid: user.uid,
        email: user.email || "",
        username: user.displayName || `player_${user.uid.substring(0, 6)}`,
        role: "user",
        wins: 0,
        losses: 0,
        totalMatches: 0,
        points: 0,
        globalRank: 0,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    }

    functions.logger.info(`New user created: ${user.uid}`);
  });

// ─────────────────────────────────────────────────────────────────────────────
// NOTIFICATIONS
// ─────────────────────────────────────────────────────────────────────────────

/**
 * onMatchPlayerJoined — notify match creator when a new player joins.
 */
exports.onMatchPlayerJoined = functions
  .region("europe-west1")
  .firestore.document("matchmaking_sessions/{sessionId}")
  .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after = change.after.data();

    const beforePlayers = before.playerIds || [];
    const afterPlayers = after.playerIds || [];

    // Check if a new player was added
    if (afterPlayers.length <= beforePlayers.length) return null;

    const newPlayerId = afterPlayers.find((id) => !beforePlayers.includes(id));
    if (!newPlayerId) return null;

    // Don't notify if the creator joined their own match (usually happens on creation, but just in case)
    if (newPlayerId === after.creatorId) return null;

    const newPlayerName = after.playerNames?.[newPlayerId] || "لاعب جديد";

    // Get creator's FCM token
    const creatorDoc = await db.collection("users").doc(after.creatorId).get();
    if (!creatorDoc.exists) return null;
    const fcmToken = creatorDoc.data().fcmToken;
    if (!fcmToken) return null;

    try {
      await admin.messaging().send({
        token: fcmToken,
        notification: {
          title: "لاعب جديد انضم! ⚽",
          body: `انضم ${newPlayerName} إلى الماتش الخاص بك في ${after.city}.`,
        },
        data: {
          route: "/matchmaking",
          id: context.params.sessionId,
          type: "match_joined",
        },
        android: { priority: "high" },
        apns: { payload: { aps: { sound: "default" } } },
      });
      functions.logger.info(`Notified creator ${after.creatorId} about new player ${newPlayerId}`);
    } catch (err) {
      functions.logger.error("Match join notification failed:", err);
    }
    return null;
  });

/**
 * onTeamMemberJoined — notify team members when a new player joins.
 */
exports.onTeamMemberJoined = functions
  .region("europe-west1")
  .firestore.document("teams/{teamId}")
  .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after = change.after.data();

    const beforeMembers = before.memberIds || [];
    const afterMembers = after.memberIds || [];

    // Check if a new member was added
    if (afterMembers.length <= beforeMembers.length) return null;

    const newMemberId = afterMembers.find((id) => !beforeMembers.includes(id));
    if (!newMemberId) return null;

    const newMemberName = after.memberNames?.[newMemberId] || "لاعب جديد";

    // Get FCM tokens for all other team members
    const otherMemberIds = afterMembers.filter(id => id !== newMemberId);
    if (otherMemberIds.length === 0) return null;

    const userDocs = await Promise.all(
      otherMemberIds.map(uid => db.collection("users").doc(uid).get())
    );

    const tokens = userDocs
      .filter(d => d.exists && d.data().fcmToken)
      .map(d => d.data().fcmToken);

    if (tokens.length === 0) return null;

    try {
      await admin.messaging().sendEachForMulticast({
        tokens: tokens,
        notification: {
          title: "عضو جديد في التيم! 🛡️",
          body: `انضم ${newMemberName} إلى تيم ${after.name}.`,
        },
        data: {
          route: "/teams/" + context.params.teamId,
          id: context.params.teamId,
          type: "team_joined",
        },
        android: { priority: "high" },
        apns: { payload: { aps: { sound: "default" } } },
      });
      functions.logger.info(`Notified ${tokens.length} team members about new member ${newMemberId}`);
    } catch (err) {
      functions.logger.error("Team join notification failed:", err);
    }
    return null;
  });
