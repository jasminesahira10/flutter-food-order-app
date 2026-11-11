import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

void main() {
  // Error catching: app crash aagaama error ah log pannum
  FlutterError.onError = (details) {
    debugPrint('App error: ${details.exceptionAsString()}');
  };
  runApp(
    ChangeNotifierProvider(
      create: (_) => CartProvider(),
      child: const FoodApp(),
    ),
  );
}

// ---------- MODELS ----------
class MenuItem {
  final String id;
  final String name;
  final String emoji;
  final double price;
  const MenuItem(this.id, this.name, this.emoji, this.price);
}

const List<MenuItem> menu = [
  MenuItem('1', 'Margherita Pizza', '🍕', 199),
  MenuItem('2', 'Veg Burger', '🍔', 99),
  MenuItem('3', 'Chicken Biryani', '🍛', 249),
  MenuItem('4', 'Masala Dosa', '🥞', 79),
  MenuItem('5', 'French Fries', '🍟', 89),
  MenuItem('6', 'Cold Coffee', '🥤', 99),
];

class Order {
  final int number;
  final List<String> lines;
  final double total;
  final DateTime time;
  Order(this.number, this.lines, this.total, this.time);
}

// ---------- STATE MANAGEMENT (Provider) ----------
// Oru idathula data vachu, ella screens um adhe paakkum
class CartProvider extends ChangeNotifier {
  final Map<String, int> _qty = {};
  final List<Order> orders = [];

  int quantityOf(String id) => _qty[id] ?? 0;
  int get count => _qty.values.fold(0, (a, b) => a + b);
  bool get isEmpty => _qty.isEmpty;

  double get total {
    double sum = 0;
    for (final item in menu) {
      sum += quantityOf(item.id) * item.price;
    }
    return sum;
  }

  void add(MenuItem item) {
    _qty[item.id] = quantityOf(item.id) + 1;
    notifyListeners(); // screens ku "data maariduchu" nu sollum
  }

  void remove(MenuItem item) {
    final q = quantityOf(item.id);
    if (q <= 1) {
      _qty.remove(item.id);
    } else {
      _qty[item.id] = q - 1;
    }
    notifyListeners();
  }

  Order? placeOrder() {
    if (_qty.isEmpty) return null;
    final lines = menu
        .where((m) => quantityOf(m.id) > 0)
        .map((m) => '${quantityOf(m.id)} x ${m.name}')
        .toList();
    final order = Order(orders.length + 1, lines, total, DateTime.now());
    orders.insert(0, order);
    _qty.clear();
    notifyListeners();
    return order;
  }
}

class FoodApp extends StatelessWidget {
  const FoodApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Food Order App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: Colors.red, useMaterial3: true),
      home: const HomeScreen(),
    );
  }
}

// ---------- HOME (bottom navigation) ----------
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int index = 0;
  final pages = const [MenuTab(), CartTab(), OrdersTab(), ProfileTab()];
  final titles = const ['Menu', 'My Cart', 'My Orders', 'Profile'];

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    return Scaffold(
      appBar: AppBar(title: Text('Food Order • ${titles[index]}')),
      body: pages[index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (i) => setState(() => index = i),
        destinations: [
          const NavigationDestination(
              icon: Icon(Icons.restaurant_menu), label: 'Menu'),
          NavigationDestination(
            icon: Badge(
              label: Text('${cart.count}'),
              isLabelVisible: cart.count > 0,
              child: const Icon(Icons.shopping_cart),
            ),
            label: 'Cart',
          ),
          const NavigationDestination(
              icon: Icon(Icons.receipt_long), label: 'Orders'),
          const NavigationDestination(
              icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}

// ---------- TAB 1: Menu ----------
class MenuTab extends StatelessWidget {
  const MenuTab({super.key});

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    return ListView.builder(
      itemCount: menu.length,
      itemBuilder: (context, i) {
        final item = menu[i];
        final q = cart.quantityOf(item.id);
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: ListTile(
            leading: Text(item.emoji, style: const TextStyle(fontSize: 34)),
            title: Text(item.name),
            subtitle: Text('₹${item.price.toStringAsFixed(0)}'),
            trailing: q == 0
                ? ElevatedButton(
                    onPressed: () => cart.add(item),
                    child: const Text('Add'),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline),
                        onPressed: () => cart.remove(item),
                      ),
                      Text('$q',
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline),
                        onPressed: () => cart.add(item),
                      ),
                    ],
                  ),
          ),
        );
      },
    );
  }
}

// ---------- TAB 2: Cart ----------
class CartTab extends StatelessWidget {
  const CartTab({super.key});

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    if (cart.isEmpty) {
      return const Center(child: Text('Your cart is empty. Add some food!'));
    }
    final items = menu.where((m) => cart.quantityOf(m.id) > 0).toList();
    return Column(
      children: [
        Expanded(
          child: ListView(
            children: items.map((m) {
              final q = cart.quantityOf(m.id);
              return ListTile(
                leading: Text(m.emoji, style: const TextStyle(fontSize: 28)),
                title: Text(m.name),
                subtitle: Text('$q x ₹${m.price.toStringAsFixed(0)}'),
                trailing: Text('₹${(q * m.price).toStringAsFixed(0)}',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
              );
            }).toList(),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total', style: TextStyle(fontSize: 18)),
                  Text('₹${cart.total.toStringAsFixed(0)}',
                      style: const TextStyle(
                          fontSize: 22, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    final order = cart.placeOrder();
                    if (order != null) {
                      // In-app notification
                      showDialog(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: const Text('Order Placed 🎉'),
                          content: Text(
                              'Order #${order.number} confirmed.\nTotal: ₹${order.total.toStringAsFixed(0)}'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('OK'),
                            ),
                          ],
                        ),
                      );
                    }
                  },
                  child: const Text('Place Order'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ---------- TAB 3: Orders ----------
class OrdersTab extends StatelessWidget {
  const OrdersTab({super.key});

  @override
  Widget build(BuildContext context) {
    final orders = context.watch<CartProvider>().orders;
    if (orders.isEmpty) {
      return const Center(child: Text('No orders yet.'));
    }
    return ListView.builder(
      itemCount: orders.length,
      itemBuilder: (context, i) {
        final o = orders[i];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: ListTile(
            leading: const Icon(Icons.check_circle, color: Colors.green),
            title: Text('Order #${o.number} • ₹${o.total.toStringAsFixed(0)}'),
            subtitle: Text(o.lines.join('\n')),
            isThreeLine: o.lines.length > 1,
          ),
        );
      },
    );
  }
}

// ---------- TAB 4: Profile (photo + location) ----------
class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  Uint8List? photoBytes;
  String locationText = 'Location not detected yet';
  String? error;
  bool loadingLocation = false;

  // Camera / Gallery
  Future<void> pickPhoto(ImageSource source) async {
    try {
      final picked = await ImagePicker().pickImage(source: source);
      if (picked == null) return; // user cancel panninaa
      final bytes = await picked.readAsBytes();
      setState(() {
        photoBytes = bytes;
        error = null;
      });
    } catch (e) {
      setState(() => error = 'Could not load photo. Please try again.');
    }
  }

  // Device location (permission + error handling)
  Future<void> getLocation() async {
    setState(() {
      loadingLocation = true;
      error = null;
    });
    try {
      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) {
        setState(() => error = 'Location services are turned off.');
        return;
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied) {
        setState(() => error = 'Location permission was denied.');
        return;
      }
      if (permission == LocationPermission.deniedForever) {
        setState(() => error =
            'Location permission is blocked. Enable it in browser/app settings.');
        return;
      }
      final pos = await Geolocator.getCurrentPosition();
      setState(() {
        locationText =
            'Lat: ${pos.latitude.toStringAsFixed(4)}, Lng: ${pos.longitude.toStringAsFixed(4)}';
      });
    } catch (e) {
      setState(() => error = 'Could not get location. Please try again.');
    } finally {
      if (mounted) setState(() => loadingLocation = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          CircleAvatar(
            radius: 60,
            backgroundImage:
                photoBytes != null ? MemoryImage(photoBytes!) : null,
            child: photoBytes == null
                ? const Icon(Icons.person, size: 60)
                : null,
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              OutlinedButton.icon(
                onPressed: () => pickPhoto(ImageSource.gallery),
                icon: const Icon(Icons.photo_library),
                label: const Text('Gallery'),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: () => pickPhoto(ImageSource.camera),
                icon: const Icon(Icons.camera_alt),
                label: const Text('Camera'),
              ),
            ],
          ),
          const SizedBox(height: 32),
          const Icon(Icons.location_on, size: 40, color: Colors.red),
          const SizedBox(height: 8),
          Text(locationText, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: loadingLocation ? null : getLocation,
            icon: loadingLocation
                ? const SizedBox(
                    height: 16,
                    width: 16,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.my_location),
            label: const Text('Detect delivery location'),
          ),
          if (error != null)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Text(error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red)),
            ),
        ],
      ),
    );
  }
}