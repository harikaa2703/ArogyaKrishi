# API Contracts

POST /detect-image
Request:

- multipart/form-data
  - image
  - lat (optional)
  - lng (optional)

Response:

```json
{
    "crop": "string",
    "disease": "string",
    "confidence": float,
    "remedies": [string],
    "language": "en|te|hi"
}
```

GET /nearby-alerts
Response:

```json
{
"alerts": [
        {
            "disease": "string",
            "distance_km": float,
            "timestamp": "iso"
        }
    ]
}
```

POST /scan-treatment
Request:

- multipart/form-data
  - image
  - disease (localized or English key)
  - item_label (optional)
  - language (en|te|hi|kn|ml)

Response:

```json
{
	"disease": "string",
	"language": "en|te|hi|kn|ml",
	"item_label": "string | null",
	"will_cure": true,
	"feedback": "string"
}
```

GET /suggested-treatments
Request:

- query params
  - disease (required)
  - language (optional)
  - lat (required for real-time stores)
  - lng (required for real-time stores)

Response:

```json
{
  "disease": "string",
  "language": "en|te|hi|kn|ml",
  "remedies": ["string"],
  "stores": [
    {
      "name": "string",
      "address": "string | null",
      "phone": "string | null",
      "latitude": float,
      "longitude": float,
      "distance_km": float | null
    }
  ]
}
```

Notes:

- Real-time store lookup uses OpenStreetMap Overpass API (no API key required).

POST /register-device
Request:

- JSON body
  - device_token (required)
  - latitude (required)
  - longitude (required)
  - notifications_enabled (optional, default true)

Response:

```json
{
	"ok": true
}
```
