/// Default backend URL used the first time the app runs. It can be changed
/// at runtime from the "Server" option on the login screen (stored on the
/// device, so you only need to set it once per install).
///
/// Notes for local development — "localhost" means different things
/// depending on where the app is actually running:
/// - Flutter web running on the same computer as the server: localhost works.
/// - Android emulator: the emulator has its own network namespace, so it
///   must use 10.0.2.2 to reach your computer, e.g. http://10.0.2.2:4000/api
/// - iOS simulator: localhost works, same as web.
/// - A physical phone/tablet: use your computer's LAN IP address, e.g.
///   http://192.168.1.23:4000/api — the phone and computer must be on the
///   same network, and the server's CORS_ORIGIN / firewall must allow it.
const String defaultApiBaseUrl = 'http://localhost:4000/api';
