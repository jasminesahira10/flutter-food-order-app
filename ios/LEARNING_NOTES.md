# Module 05 Learning Notes

## State Management
Provider keeps shared data (cart, orders) in one place. When data changes,
notifyListeners() refreshes every screen that uses it.

## Device Features
- Location: geolocator checks service, asks permission, reads latitude/longitude.
- Gallery/Camera: image_picker returns the chosen photo.

## Permissions
Apps must ask the user before using location or camera. Android needs
permissions declared in AndroidManifest.xml.

## Error Handling
try/catch blocks show friendly messages instead of crashing when
permission is denied or the photo fails to load.

## Performance and Build
DevTools shows frame timing. A release build is smaller and faster than debug.

## Challenges
Setting up packages, handling denied permissions, testing on Chrome.