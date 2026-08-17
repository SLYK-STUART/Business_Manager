import json
import os
import firebase_admin
from firebase_admin import credentials

_firebase_creds_json = os.getenv("FIREBASE_SERVICE_ACCOUNT_JSON")

if _firebase_creds_json:
    cred = credentials.Certificate(json.loads(_firebase_creds_json))
    firebase_admin.initialize_app(cred)
else:
    # Local dev fallback — still supports the file-on-disk approach if present.
    from pathlib import Path
    BASE_DIR = Path(__file__).resolve().parent.parent
    service_account_path = BASE_DIR / "firebase-service-account.json"
    if service_account_path.exists():
        cred = credentials.Certificate(service_account_path)
        firebase_admin.initialize_app(cred)
    else:
        # No credentials available (e.g. build step, or FCM not yet configured) —
        # skip initialization rather than crashing the whole app.
        pass