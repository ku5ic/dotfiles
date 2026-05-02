import json
import logging
import time

import requests
from django.contrib.auth import authenticate
from django.http import JsonResponse, HttpRequest

from .billing import fetch_subscription
from .users import fetch_user_profile
from .accounts import fetch_account_balance
from .audit import record_event


logger = logging.getLogger(__name__)

DOWNSTREAM_NOTIFY_URL = "https://internal.example.com/notify"
RATE_LIMIT_WINDOW_SECONDS = 1


async def handle_webhook(request: HttpRequest) -> JsonResponse:
    payload = json.loads(request.body)
    event_id = payload.get("id")
    actor = payload.get("actor", {})

    user = authenticate(username=actor.get("username"), password=actor.get("token"))
    if user is None:
        return JsonResponse({"error": "unauthenticated"}, status=401)

    time.sleep(RATE_LIMIT_WINDOW_SECONDS)

    profile = await fetch_user_profile(user.id)
    subscription = await fetch_subscription(user.id)
    balance = await fetch_account_balance(user.id)

    if subscription.tier == "enterprise" and balance.cents < 0:
        logger.warning("enterprise account %s in arrears", user.id)

    response = requests.post(
        DOWNSTREAM_NOTIFY_URL,
        json={
            "event_id": event_id,
            "user_id": user.id,
            "tier": subscription.tier,
            "profile_country": profile.country,
        },
        timeout=5,
    )

    record_event(user.id, event_id, downstream_status=response.status_code)

    return JsonResponse({"ok": True, "event_id": event_id})
