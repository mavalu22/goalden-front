# Goalden — Multi-Device Sync Test Checklist

Platform-agnostic manual verification checklist for the bidirectional sync
architecture. Run on two devices (A and B) logged into the **same account**.
Between each step, ensure a successful sync completes on the receiving device
(observe the sync indicator or wait ~2 s with network available).

---

## Prerequisites

- Both devices are logged in with the same account.
- Both devices have completed an initial pull (sync indicator shows "Synced").
- `last_sync_at` is stored on each device independently.

---

## 1 — Create propagates A → B

| Step | Action | Expected result |
|------|--------|-----------------|
| 1.1  | Device A: create task "Sync test task" for today | Task appears on Device A |
| 1.2  | Device B: trigger sync (or wait for auto-sync) | "Sync test task" appears on Device B |

---

## 2 — Edit propagates A → B

| Step | Action | Expected result |
|------|--------|-----------------|
| 2.1  | Device A: edit "Sync test task" title to "Sync test task (edited)" | Edit applied on A |
| 2.2  | Device B: sync | Title updated to "Sync test task (edited)" on B |

---

## 3 — Completion propagates A → B

| Step | Action | Expected result |
|------|--------|-----------------|
| 3.1  | Device A: toggle task as done | Task marked done on A |
| 3.2  | Device B: sync | Task appears done on B |

---

## 4 — Deletion propagates A → B

| Step | Action | Expected result |
|------|--------|-----------------|
| 4.1  | Device A: delete the task | Task removed from A |
| 4.2  | Device B: sync | Task removed (or absent) on B |

---

## 5 — Offline create then reconnect

| Step | Action | Expected result |
|------|--------|-----------------|
| 5.1  | Device A: go offline (airplane mode) | Sync indicator shows "Offline" |
| 5.2  | Device A: create task "Offline task" | Task created locally, `syncStatus = pending_create` |
| 5.3  | Device A: restore connectivity | Sync runs automatically |
| 5.4  | Device B: sync | "Offline task" appears on B |

---

## 6 — Conflict resolution: last-write-wins

| Step | Action | Expected result |
|------|--------|-----------------|
| 6.1  | Both devices: ensure they have the same task synced | Starting state identical |
| 6.2  | Device A: go offline; edit task title to "Title from A" | Local edit on A, not yet synced |
| 6.3  | Device B (online): edit same task title to "Title from B" and sync | B's version on server has newer `updated_at` |
| 6.4  | Device A: restore connectivity and sync | Server's "Title from B" wins; A's title overwritten |
| 6.5  | Device B: sync | Both devices show "Title from B" |

---

## 7 — Delete vs. edit conflict (delete wins when newer)

| Step | Action | Expected result |
|------|--------|-----------------|
| 7.1  | Device A: go offline; edit task | Local edit on A |
| 7.2  | Device B: delete same task (online, synced) | Task deleted on server with `deleted_at` = now |
| 7.3  | Device A: reconnect and sync | Server `deleted_at` > A's `updated_at` → task deleted on A |

---

## 8 — Edit wins over delete when local edit is newer

| Step | Action | Expected result |
|------|--------|-----------------|
| 8.1  | Device B: delete a task (online, synced) | Task soft-deleted on server |
| 8.2  | Device A: go offline; edit the same task **after** B deleted it (clock ahead) | Local `updated_at` newer than server `deleted_at` |
| 8.3  | Device A: reconnect and sync | A's edit is upserted; server record restored; B sees task alive |

---

## 9 — No cross-user leakage

| Step | Action | Expected result |
|------|--------|-----------------|
| 9.1  | Log in with Account 1, create task "Account 1 private" | Task created |
| 9.2  | Log out; log in with Account 2 | No tasks from Account 1 visible |
| 9.3  | Sync with Account 2 | Still no Account 1 tasks — server scopes all queries to authenticated user |

---

## Implementation notes

- Server LWW: `ON CONFLICT (id) DO UPDATE … WHERE EXCLUDED.updated_at >= tasks.updated_at`
- Client LWW insert: `upsertFromCloud` skips update when `incoming.updatedAt <= existing.updatedAt`
- Deletion LWW: `applyServerDeletion` compares `serverDeletedAt` vs local `updatedAt`
- Pending states: `pending_create`, `pending_update`, `pending_delete` → `synced`
- Offline retry: `SyncActionsNotifier` listens to `isOnlineProvider` and auto-retries on reconnect
- App resume: `WidgetsBindingObserver.didChangeAppLifecycleState` triggers `pushSync` on `resumed`
