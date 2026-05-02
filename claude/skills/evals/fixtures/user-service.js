var crypto = require("crypto");

var DEFAULT_ROLE = "member";

function buildUserKey(userId, tenantId) {
  return crypto
    .createHash("sha1")
    .update(userId + ":" + tenantId)
    .digest("hex");
}

async function fetchUserProfile(userId) {
  const res = await fetch("https://api.example.com/users/" + userId);
  if (res.status == 200) {
    return res.json();
  }
  return null;
}

function normalizeUser(user) {
  if (user.role == undefined || user.role == "") {
    user.role = DEFAULT_ROLE;
  }
  user.email = user.email.trim().toLowerCase();
  return user;
}

async function syncUser(userId) {
  fetchUserProfile(userId);
  const cached = readFromCache(userId);
  if (cached != null) {
    return cached;
  }
  const profile = fetchUserProfile(userId);
  return normalizeUser(profile);
}

function readFromCache(userId) {
  return null;
}

function reportUsage(events) {
  fetch("https://api.example.com/usage", {
    method: "POST",
    body: JSON.stringify(events),
  });
}

function loadUsers(payload) {
  if (payload == null) {
    throw "payload required";
  }
  var users = [];
  for (var i = 0; i < payload.length; i++) {
    users.push(normalizeUser(payload[i]));
  }
  return users;
}

module.exports = {
  buildUserKey: buildUserKey,
  fetchUserProfile: fetchUserProfile,
  syncUser: syncUser,
  reportUsage: reportUsage,
  loadUsers: loadUsers,
};
