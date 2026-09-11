import { readFileSync } from 'fs';
import assert from 'assert';
import {
  initializeTestEnvironment,
  assertFails,
  assertSucceeds,
} from '@firebase/rules-unit-testing';
import { doc, getDoc, setDoc, deleteDoc, serverTimestamp } from 'firebase/firestore';

let env;

before(async () => {
  env = await initializeTestEnvironment({
    projectId: 'medai-rules-test',
    firestore: {
      rules: readFileSync('../firestore.rules', 'utf8'),
      host: '127.0.0.1',
      port: 8080,
    },
  });
});

after(async () => { if (env) await env.cleanup(); });
beforeEach(async () => { await env.clearFirestore(); });

const PATIENT = 'patient_uid';
const CAREGIVER = 'caregiver_uid';

describe('caregiverInvites', () => {
  it('a signed-in user can probe a code that does not exist', async () => {
    // This is the uniqueness check in SocialController.createInvite. It ran
    // before any invite existed, so resource was null and the old rule denied
    // it — every invite creation failed here.
    const db = env.authenticatedContext(PATIENT).firestore();
    await assertSucceeds(getDoc(doc(db, 'caregiverInvites/FREECODE')));
  });

  it('the probe reports the code as absent rather than erroring', async () => {
    const db = env.authenticatedContext(PATIENT).firestore();
    const snap = await getDoc(doc(db, 'caregiverInvites/FREECODE'));
    assert.strictEqual(snap.exists(), false);
  });

  it('the patient can create their own invite', async () => {
    // The payload is pinned by the create rule: only patientUid, cgId,
    // relation and createdAt, with createdAt forced to request.time. This
    // fixture used to carry cgName and a client clock, both of which the rule
    // now rejects — the invite is readable by anyone holding the code, so a
    // name in it is a leak and a client timestamp is a backdatable window.
    const db = env.authenticatedContext(PATIENT).firestore();
    await assertSucceeds(setDoc(doc(db, 'caregiverInvites/CODE1'), {
      patientUid: PATIENT,
      cgId: 'cg1',
      relation: 'Spouse',
      createdAt: serverTimestamp(),
    }));
  });

  it('a user cannot forge an invite for someone else', async () => {
    const db = env.authenticatedContext(CAREGIVER).firestore();
    await assertFails(setDoc(doc(db, 'caregiverInvites/CODE2'), {
      patientUid: PATIENT,
      createdAt: new Date(),
    }));
  });

  it('a caregiver can read a fresh invite to redeem it', async () => {
    await env.withSecurityRulesDisabled(async (ctx) => {
      await setDoc(doc(ctx.firestore(), 'caregiverInvites/LIVE'), {
        patientUid: PATIENT, createdAt: new Date(),
      });
    });
    const db = env.authenticatedContext(CAREGIVER).firestore();
    await assertSucceeds(getDoc(doc(db, 'caregiverInvites/LIVE')));
  });

  it('an expired invite is not readable by a stranger', async () => {
    const old = new Date(Date.now() - 25 * 3600 * 1000);
    await env.withSecurityRulesDisabled(async (ctx) => {
      await setDoc(doc(ctx.firestore(), 'caregiverInvites/OLD'), {
        patientUid: PATIENT, createdAt: old,
      });
    });
    const db = env.authenticatedContext(CAREGIVER).firestore();
    await assertFails(getDoc(doc(db, 'caregiverInvites/OLD')));
  });

  it('the patient can still read back their own expired invite', async () => {
    const old = new Date(Date.now() - 25 * 3600 * 1000);
    await env.withSecurityRulesDisabled(async (ctx) => {
      await setDoc(doc(ctx.firestore(), 'caregiverInvites/MINE'), {
        patientUid: PATIENT, createdAt: old,
      });
    });
    const db = env.authenticatedContext(PATIENT).firestore();
    await assertSucceeds(getDoc(doc(db, 'caregiverInvites/MINE')));
  });

  it('an unauthenticated caller cannot probe at all', async () => {
    const db = env.unauthenticatedContext().firestore();
    await assertFails(getDoc(doc(db, 'caregiverInvites/FREECODE')));
  });

  it('the patient can revoke their invite', async () => {
    await env.withSecurityRulesDisabled(async (ctx) => {
      await setDoc(doc(ctx.firestore(), 'caregiverInvites/REVOKE'), {
        patientUid: PATIENT, createdAt: new Date(),
      });
    });
    const db = env.authenticatedContext(PATIENT).firestore();
    await assertSucceeds(deleteDoc(doc(db, 'caregiverInvites/REVOKE')));
  });
});
