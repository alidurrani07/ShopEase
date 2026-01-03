import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

// Initialize Firebase and start the app
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const ShopEaseApp());
}

class Product {
  final int id;
  final String name;
  final int price;
  final String category;
  final String sub;
  final String image;
  int qty;

  Product({
    required this.id,
    required this.name,
    required this.price,
    required this.category,
    required this.sub,
    required this.image,
    this.qty = 1,
  });
}

class Order {
  final String id;
  final String userEmail;
  final List<Product> items;
  final int total;
  final String paymentMethod;
  final String address;
  final DateTime date;
  final String status;

  Order({
    required this.id,
    required this.userEmail,
    required this.items,
    required this.total,
    required this.paymentMethod,
    required this.address,
    required this.date,
    this.status = "Processing",
  });
}

class ShopEaseApp extends StatefulWidget {
  const ShopEaseApp({super.key});

  @override
  State<ShopEaseApp> createState() => _ShopEaseAppState();
}

class _ShopEaseAppState extends State<ShopEaseApp> {
  bool isDarkMode = false;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ShopEase Premium',
      debugShowCheckedModeBanner: false,
      themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorSchemeSeed: const Color(0xFF6366F1),
        fontFamily: 'Inter',
        scaffoldBackgroundColor: const Color(0xFFF1F5F9),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorSchemeSeed: const Color(0xFF818CF8),
        scaffoldBackgroundColor: const Color(0xFF0F172A),
      ),
      home: MainLayout(
        onThemeToggle: () => setState(() => isDarkMode = !isDarkMode),
        isDarkMode: isDarkMode,
      ),
    );
  }
}

class MainLayout extends StatefulWidget {
  final VoidCallback onThemeToggle;
  final bool isDarkMode;
  const MainLayout({super.key, required this.onThemeToggle, required this.isDarkMode});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  // Navigation State
  String currentView = 'home';
  Map<String, String>? currentUser; 
  List<Product> cart = [];
  List<Order> allOrders = []; 
  String activeCategory = 'All';
  
  // Checkout Controllers
  String paymentMethod = 'Credit Card';
  final TextEditingController addressCtrl = TextEditingController();
  final TextEditingController cardNumCtrl = TextEditingController();
  final TextEditingController cardExpCtrl = TextEditingController();
  final TextEditingController cardCvvCtrl = TextEditingController();

  final TextEditingController emailCtrl = TextEditingController();
  final TextEditingController passCtrl = TextEditingController();

  final List<Product> products = [
    Product(id: 1, name: "iPhone 15 Pro Max", price: 450000, category: "Electronics", sub: "Smartphones", image: "https://images.unsplash.com/photo-1720357632099-6d84cd7ee044?fm=jpg&q=60&w=3000&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxzZWFyY2h8Nnx8aXBob25lJTIwMTUlMjBwcm8lMjBtYXh8ZW58MHx8MHx8fDA%3D"),
    Product(id: 2, name: "Bespoke Navy Suit", price: 85000, category: "Adult", sub: "Male", image: "https://images.unsplash.com/photo-1426523038054-a260f3ef5bc9?fm=jpg&q=60&w=3000&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D"),
    Product(id: 3, name: "Summer Floral Gown", price: 12500, category: "Adult", sub: "Female", image: "https://media.istockphoto.com/id/1486286576/photo/summer-silk-floral-dress-on-a-white-background.jpg?s=612x612&w=0&k=20&c=XBmiPEpZfdvu9EEYJXtybdFd13qJO9HsWfmD9suWJ70="),
    Product(id: 4, name: "Kids Spider-man Suit", price: 4500, category: "Kids", sub: "Boys", image: "https://media.4rgos.it/i/Argos/tuc142459861-Red_R_Z001A?w=598&h=810&qlt=70"),
    Product(id: 8, name: "MacBook Pro M3", price: 580000, category: "Electronics", sub: "Laptops", image: "data:image/jpeg;base64,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"),
    Product(id: 9, name: "Leather Formal Shoes", price: 15000, category: "Adult", sub: "Footwear", image: "data:image/jpeg;base64,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"),
  ];

  @override
  void dispose() {
    emailCtrl.dispose();
    passCtrl.dispose();
    addressCtrl.dispose();
    cardNumCtrl.dispose();
    cardExpCtrl.dispose();
    cardCvvCtrl.dispose();
    super.dispose();
  }

  void addToCart(Product product) {
    if (currentUser == null) {
      _showMsg("Please login as a user to shop", Colors.orange);
      return;
    }
    if (currentUser!['role'] == 'admin') {
      _showMsg("Admins cannot shop!", Colors.redAccent);
      return;
    }
    setState(() {
      int idx = cart.indexWhere((p) => p.id == product.id);
      if (idx != -1) {
        cart[idx].qty++;
      } else {
        cart.add(Product(id: product.id, name: product.name, price: product.price, category: product.category, sub: product.sub, image: product.image, qty: 1));
      }
      _showMsg("${product.name} added to cart", Colors.indigo);
    });
  }

  void _showMsg(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg), 
      backgroundColor: color, 
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  void handlePlaceOrder() {
    if (currentUser == null) return;
    
    // 1. Validation
    if (addressCtrl.text.trim().isEmpty) {
      _showMsg("Please enter your shipping address", Colors.redAccent);
      return;
    }

    if (paymentMethod == 'Credit Card') {
      if (cardNumCtrl.text.isEmpty || cardExpCtrl.text.isEmpty || cardCvvCtrl.text.isEmpty) {
        _showMsg("Please complete your card details", Colors.redAccent);
        return;
      }
    }

    // 2. Calculation
    int subtotal = cart.fold(0, (sum, p) => sum + (p.price * p.qty));
    int total = subtotal + (paymentMethod == 'COD' ? 500 : 0);

    // 3. Create Order Object
    final newOrder = Order(
      id: "#ORD-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}",
      userEmail: currentUser!['email']!,
      items: List.from(cart),
      total: total,
      paymentMethod: paymentMethod,
      address: addressCtrl.text,
      date: DateTime.now(),
      status: "Processing",
    );

    // 4. Update State
    setState(() {
      allOrders.add(newOrder);
      cart.clear(); // Empty cart after purchase
      currentView = 'track_order'; // Redirect to tracking page
      // Reset checkout form
      addressCtrl.clear();
      cardNumCtrl.clear();
      cardExpCtrl.clear();
      cardCvvCtrl.clear();
    });

    _showMsg("Order Confirmed! Tracking started.", Colors.green);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: _buildSideDrawer(),
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              _buildModernAppBar(),
              if (currentView == 'home') ...[
                _buildHeroSection(),
                _buildCategorySection(),
              ],
              _buildBody(),
              const SliverToBoxAdapter(child: SizedBox(height: 120)),
            ],
          ),
          if (currentUser != null && currentUser!['role'] == 'user' && currentView == 'home')
            _buildBottomCartBar(),
        ],
      ),
    );
  }

  Widget _buildSideDrawer() {
    return Drawer(
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(Icons.person, color: Theme.of(context).primaryColor),
            ),
            accountName: Text(currentUser != null ? currentUser!['role']!.toUpperCase() : "Guest"),
            accountEmail: Text(currentUser != null ? currentUser!['email']! : "Login to access features"),
            decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [Color(0xFF6366F1), Color(0xFFA855F7)]),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.home_outlined),
            title: const Text("Marketplace"),
            onTap: () {
              Navigator.pop(context);
              setState(() => currentView = 'home');
            },
          ),
          if (currentUser != null && currentUser!['role'] == 'user') ...[
            ListTile(
              leading: const Icon(Icons.shopping_cart_outlined),
              title: const Text("My Cart"),
              onTap: () {
                Navigator.pop(context);
                setState(() => currentView = 'cart');
              },
            ),
            ListTile(
              leading: const Icon(Icons.local_shipping_outlined),
              title: const Text("Track My Order"),
              onTap: () {
                Navigator.pop(context);
                setState(() => currentView = 'track_order');
              },
            ),
          ],
          if (currentUser != null && currentUser!['role'] == 'admin')
            ListTile(
              leading: const Icon(Icons.history_edu_rounded),
              title: const Text("User Purchase History"),
              onTap: () {
                Navigator.pop(context);
                setState(() => currentView = 'admin_history');
              },
            ),
          const Divider(),
          ListTile(
            leading: Icon(widget.isDarkMode ? Icons.light_mode : Icons.dark_mode),
            title: Text(widget.isDarkMode ? "Light Mode" : "Dark Mode"),
            onTap: widget.onThemeToggle,
          ),
          if (currentUser != null)
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text("Logout", style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                setState(() { currentUser = null; cart.clear(); currentView = 'home'; });
              },
            ),
        ],
      ),
    );
  }

  Widget _buildModernAppBar() {
    return SliverAppBar(
      floating: true,
      pinned: true,
      elevation: 0,
      toolbarHeight: 80,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor.withOpacity(0.8),
      leading: Builder(
        builder: (context) => IconButton(
          icon: const Icon(Icons.menu_rounded, color: Color(0xFF6366F1)),
          onPressed: () => Scaffold.of(context).openDrawer(),
        ),
      ),
      title: const Text("SHOPEASE", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: 1.5)),
      actions: [
        if (currentUser == null)
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: TextButton(
              onPressed: () => setState(() => currentView = 'login'),
              child: const Text("Sign In", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF6366F1))),
            ),
          )
        else
          IconButton(
            onPressed: () => setState(() => currentView = 'cart'),
            icon: Badge(
              label: Text(cart.length.toString()),
              isLabelVisible: cart.isNotEmpty,
              child: const Icon(Icons.shopping_basket_outlined),
            ),
          ),
      ],
    );
  }

  Widget _buildHeroSection() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Container(
          height: 180,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: const LinearGradient(colors: [Color(0xFF6366F1), Color(0xFFA855F7)]),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text("Winter Sale", style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                const Text("UP TO 50% OFF\nNEW COLLECTIONS", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900, height: 1.1)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategorySection() {
    final categories = ["All", "Adult", "Kids", "Electronics"];
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: SizedBox(
          height: 40,
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: categories.length,
            itemBuilder: (context, i) {
              bool active = activeCategory == categories[i];
              return Padding(
                padding: const EdgeInsets.only(right: 10),
                child: ChoiceChip(
                  label: Text(categories[i]),
                  selected: active,
                  onSelected: (_) => setState(() => activeCategory = categories[i]),
                  selectedColor: const Color(0xFF6366F1),
                  labelStyle: TextStyle(color: active ? Colors.white : Colors.black, fontWeight: FontWeight.bold),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (currentView == 'login') return SliverToBoxAdapter(child: _buildLoginView());
    if (currentView == 'cart') return SliverToBoxAdapter(child: _buildCartView());
    if (currentView == 'track_order') return SliverToBoxAdapter(child: _buildTrackingView());
    if (currentView == 'admin_history') return SliverToBoxAdapter(child: _buildAdminHistory());

    final filtered = products.where((p) => activeCategory == "All" || p.category == activeCategory).toList();
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2, 
          mainAxisSpacing: 16, 
          crossAxisSpacing: 16, 
          childAspectRatio: 0.72,
        ),
        delegate: SliverChildBuilderDelegate((c, i) => _buildProductCard(filtered[i]), childCount: filtered.length),
      ),
    );
  }

  Widget _buildProductCard(Product p) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: ClipRRect(borderRadius: const BorderRadius.vertical(top: Radius.circular(20)), child: Image.network(p.image, fit: BoxFit.cover, width: double.infinity))),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14), maxLines: 1),
                const SizedBox(height: 4),
                Text("Rs. ${p.price}", style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF6366F1), fontSize: 16)),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => addToCart(p),
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6366F1), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                    child: const Text("Add to Cart", style: TextStyle(fontSize: 12)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginView() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          const Icon(Icons.lock_person, size: 80, color: Color(0xFF6366F1)),
          const SizedBox(height: 24),
          const Text("Welcome Back", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 32),
          TextField(controller: emailCtrl, decoration: InputDecoration(hintText: "Email", prefixIcon: const Icon(Icons.email), filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)))),
          const SizedBox(height: 16),
          TextField(controller: passCtrl, obscureText: true, decoration: InputDecoration(hintText: "Password", prefixIcon: const Icon(Icons.key), filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)))),
          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6366F1), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 18)),
                  onPressed: () {
                    if (emailCtrl.text.isEmpty) { _showMsg("Enter email", Colors.red); return; }
                    setState(() { currentUser = {'email': emailCtrl.text, 'role': 'user'}; currentView = 'home'; emailCtrl.clear(); passCtrl.clear(); });
                  },
                  child: const Text("USER LOGIN"),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.black87, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 18)),
                  onPressed: () {
                    if (emailCtrl.text.isEmpty) { _showMsg("Enter email", Colors.red); return; }
                    setState(() { currentUser = {'email': emailCtrl.text, 'role': 'admin'}; currentView = 'home'; emailCtrl.clear(); passCtrl.clear(); });
                  },
                  child: const Text("ADMIN LOGIN"),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCartView() {
    int subtotal = cart.fold(0, (sum, p) => sum + (p.price * p.qty));
    int shipping = paymentMethod == 'COD' ? 500 : 0;
    int grandTotal = subtotal + shipping;
    
    if (cart.isEmpty) return const Center(child: Padding(padding: EdgeInsets.all(100), child: Text("Your cart is empty")));

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Review Order", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          ...cart.map((item) => ListTile(
            contentPadding: EdgeInsets.zero,
            leading: ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.network(item.image, width: 50, height: 50, fit: BoxFit.cover)),
            title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text("${item.qty} x Rs. ${item.price}"),
            trailing: IconButton(icon: const Icon(Icons.delete, color: Colors.redAccent), onPressed: () => setState(() => cart.remove(item))),
          )),
          const Divider(height: 40),
          const Text("Shipping Address", style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          TextField(controller: addressCtrl, decoration: InputDecoration(hintText: "Enter full delivery address", filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
          const SizedBox(height: 20),
          const Text("Payment Method", style: TextStyle(fontWeight: FontWeight.bold)),
          Row(
            children: [
              Expanded(child: RadioListTile(value: 'Credit Card', groupValue: paymentMethod, onChanged: (v) => setState(() => paymentMethod = v!), title: const Text("Card"))),
              Expanded(child: RadioListTile(value: 'COD', groupValue: paymentMethod, onChanged: (v) => setState(() => paymentMethod = v!), title: const Text("COD (+500)"))),
            ],
          ),
          if (paymentMethod == 'Credit Card') _buildCardFields(),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
            child: Column(
              children: [
                _summaryRow("Subtotal", "Rs. $subtotal"),
                _summaryRow("Shipping", "Rs. $shipping"),
                const Divider(),
                _summaryRow("Total", "Rs. $grandTotal", isBold: true),
              ],
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 60,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6366F1), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
              onPressed: handlePlaceOrder,
              child: const Text("PLACE ORDER", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildCardFields() {
    return Column(
      children: [
        TextField(controller: cardNumCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Card Number")),
        Row(
          children: [
            Expanded(child: TextField(controller: cardExpCtrl, decoration: const InputDecoration(labelText: "MM/YY"))),
            const SizedBox(width: 10),
            Expanded(child: TextField(controller: cardCvvCtrl, obscureText: true, decoration: const InputDecoration(labelText: "CVV"))),
          ],
        ),
      ],
    );
  }

  Widget _buildTrackingView() {
    final myOrders = allOrders.where((o) => o.userEmail == currentUser!['email']).toList().reversed.toList();
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("My Orders", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          if (myOrders.isEmpty) const Text("No orders found.")
          else ...myOrders.map((o) => Card(
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: ListTile(
              title: Text(o.id, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text("Status: ${o.status}\n${o.date.toString().substring(0, 16)}"),
              trailing: Text("Rs. ${o.total}", style: const TextStyle(color: Color(0xFF6366F1), fontWeight: FontWeight.w900)),
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildAdminHistory() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("System Purchase History", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          if (allOrders.isEmpty) const Text("No sales recorded.")
          else ...allOrders.reversed.map((o) => ExpansionTile(
            title: Text(o.id),
            subtitle: Text("User: ${o.userEmail}"),
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Address: ${o.address}"),
                    Text("Method: ${o.paymentMethod}"),
                    const Divider(),
                    ...o.items.map((i) => Text("• ${i.name} (x${i.qty})")),
                    const Divider(),
                    Text("Total Revenue: Rs. ${o.total}", style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              )
            ],
          )),
        ],
      ),
    );
  }

  Widget _buildBottomCartBar() {
    if (cart.isEmpty) return const SizedBox.shrink();
    return Positioned(
      bottom: 20, left: 20, right: 20,
      child: InkWell(
        onTap: () => setState(() => currentView = 'cart'),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(30)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("${cart.length} items", style: const TextStyle(color: Colors.white)),
              const Text("CHECKOUT", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _summaryRow(String l, String v, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(l, style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
          Text(v, style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal, color: isBold ? const Color(0xFF6366F1) : Colors.black)),
        ],
      ),
    );
  }
}