import { readFileSync } from 'fs';
import {
  initializeTestEnvironment,
  assertFails,
  assertSucceeds,
} from '@firebase/rules-unit-testing';
import {
  doc, getDoc, setDoc, deleteDoc, addDoc, collection, writeBatch,
  serverTimestamp, Timestamp,
} from 'firebase/firestore';

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

const ALEX = 'alex_uid';
const SAM = 'sam_uid';
const STRANGER = 'stranger_uid';

const as = (uid) => env.authenticatedContext(uid).firestore();
const seed = (fn) => env.withSecurityRulesDisabled((ctx) => fn(ctx.firestore()));

const invite = (db, code = 'ABC234') => doc(db, `stepInvites/${code}`);
const grant = (db, owner, partner) => doc(db, `users/${owner}/stepPartners/${partner}`);
const day = (db, owner, key = '2026-10-13') => doc(db, `users/${owner}/stepDays/${key}`);

/** Exactly what FirestoreStepsCloud.redeemInvite commits. */
const redeem = (uid, owner, code = 'ABC234') => {
  const db = as(uid);
  const batch = writeBatch(db);
  batch.set(grant(db, owner, uid), {
    uid, name: 'Sam', avatar: '', inviteCode: code, since: serverTimestamp(),
  });
  batch.set(grant(db, uid, owner), {
    uid: owner, name: '', avatar: '', since: serverTimestamp(),
  });
  batch.delete(invite(db, code));
  return batch.commit();
};

describe('stepDays', () => {
  it('the owner reads and writes their own days', async () => {
    await assertSucceeds(setDoc(day(as(ALEX), ALEX), { steps: 4200, goal: 8000 }));
    await assertSucceeds(getDoc(day(as(ALEX), ALEX)));
  });

  it('a stranger cannot read them', async () => {
    await seed((db) => setDoc(day(db, ALEX), { steps: 4200, goal: 8000 }));
    await assertFails(getDoc(day(as(STRANGER), ALEX)));
  });

  it('a partner reads but cannot write', async () => {
    await seed(async (db) => {
      await setDoc(day(db, ALEX), { steps: 4200, goal: 8000 });
      await setDoc(grant(db, ALEX, SAM), { uid: SAM });
    });
    await assertSucceeds(getDoc(day(as(SAM), ALEX)));
    await assertFails(setDoc(day(as(SAM), ALEX), { steps: 99999, goal: 1 }));
  });

  it('a caregiver is not a step partner', async () => {
    // Watching someone's medication and seeing their steps are separate
    // consents; the caregiver grant must not unlock this.
    await seed(async (db) => {
      await setDoc(day(db, ALEX), { steps: 4200, goal: 8000 });
      await setDoc(doc(db, `users/${ALEX}/caregiverAccess/${SAM}`), { status: 'active' });
    });
    await assertFails(getDoc(day(as(SAM), ALEX)));
  });
});

describe('pairing', () => {
  it('the owner creates an invite naming only themselves', async () => {
    await assertSucceeds(setDoc(invite(as(ALEX)), {
      ownerUid: ALEX, createdAt: serverTimestamp(),
    }));
  });

  it('an invite cannot carry extra fields or a backdated clock', async () => {
    await assertFails(setDoc(invite(as(ALEX)), {
      ownerUid: ALEX, ownerName: 'Alex', createdAt: serverTimestamp(),
    }));
    await assertFails(setDoc(invite(as(ALEX)), {
      ownerUid: ALEX, createdAt: Timestamp.fromDate(new Date('2030-01-01')),
    }));
  });

  it('nobody can issue an invite in someone else\'s name', async () => {
    await assertFails(setDoc(invite(as(SAM)), {
      ownerUid: ALEX, createdAt: serverTimestamp(),
    }));
  });

  it('redeeming a live invite pairs both ways and consumes it', async () => {
    await seed((db) => setDoc(invite(db), { ownerUid: ALEX, createdAt: serverTimestamp() }));
    await assertSucceeds(redeem(SAM, ALEX));

    await seed((db) => setDoc(day(db, ALEX), { steps: 1, goal: 2 }));
    await seed((db) => setDoc(day(db, SAM), { steps: 3, goal: 4 }));
    await assertSucceeds(getDoc(day(as(SAM), ALEX)));
    await assertSucceeds(getDoc(day(as(ALEX), SAM)));
    // Consumed: a second person holding the same code gets nothing.
    await assertFails(redeem(STRANGER, ALEX));
  });

  it('a grant cannot be self-issued without an invite', async () => {
    // The hole this closes: without the invite check, any signed-in user
    // could write themselves into anyone's stepPartners and read their days.
    await assertFails(setDoc(grant(as(STRANGER), ALEX, STRANGER), {
      uid: STRANGER, name: 'x', avatar: '', inviteCode: 'ZZZZZZ', since: serverTimestamp(),
    }));
    await assertFails(setDoc(grant(as(STRANGER), ALEX, STRANGER), { uid: STRANGER }));
  });

  it('an invite only opens its owner\'s steps', async () => {
    await seed((db) => setDoc(invite(db), { ownerUid: ALEX, createdAt: serverTimestamp() }));
    // Sam holds Alex's code and tries to use it against a third person.
    await assertFails(setDoc(grant(as(SAM), STRANGER, SAM), {
      uid: SAM, name: 'Sam', avatar: '', inviteCode: 'ABC234', since: serverTimestamp(),
    }));
  });

  it('an expired invite cannot be redeemed', async () => {
    const old = Timestamp.fromMillis(Date.now() - 25 * 3600 * 1000);
    await seed((db) => setDoc(invite(db), { ownerUid: ALEX, createdAt: old }));
    await assertFails(redeem(SAM, ALEX));
  });

  it('a stranger cannot delete a pending invite', async () => {
    await seed((db) => setDoc(invite(db), { ownerUid: ALEX, createdAt: serverTimestamp() }));
    await assertFails(deleteDoc(invite(as(STRANGER))));
    await assertSucceeds(deleteDoc(invite(as(ALEX))));
  });

  it('either side can unpair, and access ends with it', async () => {
    await seed(async (db) => {
      await setDoc(grant(db, ALEX, SAM), { uid: SAM });
      await setDoc(grant(db, SAM, ALEX), { uid: ALEX });
      await setDoc(day(db, ALEX), { steps: 1, goal: 2 });
    });
    const db = as(SAM);
    const batch = writeBatch(db);
    batch.delete(grant(db, SAM, ALEX));
    batch.delete(grant(db, ALEX, SAM));
    await assertSucceeds(batch.commit());
    await assertFails(getDoc(day(as(SAM), ALEX)));
  });

  it('a third party cannot break up a pair', async () => {
    await seed((db) => setDoc(grant(db, ALEX, SAM), { uid: SAM }));
    await assertFails(deleteDoc(grant(as(STRANGER), ALEX, SAM)));
  });
});

describe('stepCheers', () => {
  const cheers = (db, owner) => collection(db, `users/${owner}/stepCheers`);
  const cheer = (from, kind = 'cheer') =>
    ({ fromUid: from, kind, createdAt: serverTimestamp() });

  beforeEach(() => seed((db) => setDoc(grant(db, ALEX, SAM), { uid: SAM })));

  it('a partner can cheer and nudge', async () => {
    await assertSucceeds(addDoc(cheers(as(SAM), ALEX), cheer(SAM)));
    await assertSucceeds(addDoc(cheers(as(SAM), ALEX), cheer(SAM, 'nudge')));
  });

  it('a stranger cannot', async () => {
    await assertFails(addDoc(cheers(as(STRANGER), ALEX), cheer(STRANGER)));
  });

  it('a cheer cannot carry free text or another sender', async () => {
    await assertFails(addDoc(cheers(as(SAM), ALEX), { ...cheer(SAM), text: 'hi' }));
    await assertFails(addDoc(cheers(as(SAM), ALEX), cheer(SAM, 'insult')));
    await assertFails(addDoc(cheers(as(SAM), ALEX), cheer(STRANGER)));
  });

  it('only the recipient reads and clears them', async () => {
    let id;
    await seed(async (db) => {
      id = (await addDoc(cheers(db, ALEX), { fromUid: SAM, kind: 'cheer' })).id;
    });
    await assertFails(getDoc(doc(as(SAM), `users/${ALEX}/stepCheers/${id}`)));
    await assertSucceeds(deleteDoc(doc(as(ALEX), `users/${ALEX}/stepCheers/${id}`)));
  });
});
