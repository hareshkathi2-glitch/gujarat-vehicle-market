import 'dart:io';

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

const String appName = 'Gujarat Vehicle Market';

String currentLanguage = 'ગુજરાતી';

String tr(String gu, [String? hi, String? en]) {
  if (currentLanguage == 'હિન્દી') return hi ?? gu;
  if (currentLanguage == 'English') return en ?? gu;
  return gu;
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  Object? firebaseStartupError;
  try {
    await Firebase.initializeApp();
  } catch (error, stackTrace) {
    firebaseStartupError = error;
    debugPrint('Firebase initialization failed: $error');
    debugPrintStack(stackTrace: stackTrace);
  }

  runApp(VehicleMarketApp(firebaseStartupError: firebaseStartupError));
}

class VehicleMarketApp extends StatelessWidget {
  final Object? firebaseStartupError;

  const VehicleMarketApp({super.key, this.firebaseStartupError});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: appName,
      theme: ThemeData(
        colorSchemeSeed: Colors.green,
        useMaterial3: true,
      ),
      home: firebaseStartupError == null
          ? const AuthGate()
          : FirebaseStartupErrorPage(error: firebaseStartupError!),
    );
  }
}

class FirebaseStartupErrorPage extends StatelessWidget {
  final Object error;

  const FirebaseStartupErrorPage({super.key, required this.error});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(appName)),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              const Text(
                'Firebase શરૂ થઈ શક્યું નથી.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              const Text(
                'આ ભૂલનો મેસેજ સ્ક્રીનશોટમાં મોકલો, જેથી યોગ્ય સુધારો કરી શકાય.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              SelectableText(
                error.toString(),
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class LanguageMenu extends StatelessWidget {
  const LanguageMenu({super.key});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.language),
      onSelected: (value) {
        currentLanguage = value;
        (context as Element).markNeedsBuild();
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomePage()),
        );
      },
      itemBuilder: (context) => const [
        PopupMenuItem(value: 'ગુજરાતી', child: Text('ગુજરાતી')),
        PopupMenuItem(value: 'હિન્દી', child: Text('हिन्दी')),
        PopupMenuItem(value: 'English', child: Text('English')),
      ],
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(title: const Text(appName)),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'લોગિન સ્થિતિ તપાસવામાં ભૂલ: ${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasData) {
          return const HomePage();
        }

        return const PhoneLoginPage();
      },
    );
  }
}

// ---------------- PHONE LOGIN ----------------

class PhoneLoginPage extends StatefulWidget {
  const PhoneLoginPage({super.key});

  @override
  State<PhoneLoginPage> createState() => _PhoneLoginPageState();
}

class _PhoneLoginPageState extends State<PhoneLoginPage> {
  final phoneController = TextEditingController();
  final otpController = TextEditingController();

  String verificationId = '';
  bool otpSent = false;
  bool loading = false;

  Future<void> sendOTP() async {
    final phone = phoneController.text.trim();

    if (phone.length != 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('10 અંકનો મોબાઇલ નંબર લખો')),
      );
      return;
    }

    setState(() => loading = true);

    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: '+91$phone',
      verificationCompleted: (credential) async {
        await FirebaseAuth.instance.signInWithCredential(credential);
      },
      verificationFailed: (error) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(error.message ?? 'OTP મોકલી શકાયો નથી')),
          );
        }
      },
      codeSent: (id, token) {
        if (!mounted) return;
        setState(() {
          verificationId = id;
          otpSent = true;
          loading = false;
        });
      },
      codeAutoRetrievalTimeout: (id) {
        verificationId = id;
      },
    );

    if (mounted) setState(() => loading = false);
  }

  Future<void> verifyOTP() async {
    try {
      setState(() => loading = true);

      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: otpController.text.trim(),
      );

      await FirebaseAuth.instance.signInWithCredential(credential);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ખોટો OTP. ફરી પ્રયાસ કરો.')),
        );
      }
    }

    if (mounted) setState(() => loading = false);
  }

  @override
  void dispose() {
    phoneController.dispose();
    otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(appName),
        actions: const [LanguageMenu()],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Icon(
                Icons.directions_car,
                size: 90,
                color: Colors.green,
              ),
              const SizedBox(height: 20),
              Text(
                tr('મોબાઇલ નંબરથી લોગિન કરો',
                    'मोबाइल नंबर से लॉगिन करें',
                    'Login with mobile number'),
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 25),
              if (!otpSent)
                TextField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  maxLength: 10,
                  decoration: const InputDecoration(
                    labelText: 'મોબાઇલ નંબર',
                    prefixText: '+91 ',
                    border: OutlineInputBorder(),
                  ),
                )
              else
                TextField(
                  controller: otpController,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  decoration: const InputDecoration(
                    labelText: 'OTP લખો',
                    border: OutlineInputBorder(),
                  ),
                ),
              const SizedBox(height: 15),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: loading
                      ? null
                      : (otpSent ? verifyOTP : sendOTP),
                  child: loading
                      ? const CircularProgressIndicator()
                      : Text(otpSent ? 'OTP ચકાસો' : 'OTP મોકલો'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------- HOME PAGE ----------------

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(appName),
        actions: [
          const LanguageMenu(),
          IconButton(
            tooltip: 'Logout',
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            const SizedBox(height: 20),
            const Icon(
              Icons.directions_car_filled,
              size: 85,
              color: Colors.green,
            ),
            const SizedBox(height: 12),
            const Text(
              'Gujarat Vehicle Market',
              style: TextStyle(
                fontSize: 23,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 30),
            _homeButton(
              context,
              tr('વાહન ખરીદો', 'वाहन खरीदें', 'Buy Vehicle'),
              Icons.shopping_cart,
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const BuyVehiclesPage(),
                  ),
                );
              },
            ),
            const SizedBox(height: 18),
            _homeButton(
              context,
              tr('વાહન વેચો', 'वाहन बेचें', 'Sell Vehicle'),
              Icons.add_circle,
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const SellVehiclePage(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _homeButton(
    BuildContext context,
    String title,
    IconData icon,
    VoidCallback onTap,
  ) {
    return SizedBox(
      width: double.infinity,
      height: 65,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 27),
        label: Text(
          title,
          style: const TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}

// ---------------- BUY VEHICLES ----------------

class BuyVehiclesPage extends StatefulWidget {
  const BuyVehiclesPage({super.key});

  @override
  State<BuyVehiclesPage> createState() => _BuyVehiclesPageState();
}

class _BuyVehiclesPageState extends State<BuyVehiclesPage> {
  String selectedCategory = 'કાર';
  String searchText = '';
  String sortBy = 'નવી જાહેરાત';

  final searchController = TextEditingController();
  final minPriceController = TextEditingController();
  final maxPriceController = TextEditingController();

  final categories = ['કાર', 'બાઈક', 'ટ્રક', 'ટ્રેક્ટર'];

  @override
  void dispose() {
    searchController.dispose();
    minPriceController.dispose();
    maxPriceController.dispose();
    super.dispose();
  }

  num? get minPrice => num.tryParse(minPriceController.text.trim());
  num? get maxPrice => num.tryParse(maxPriceController.text.trim());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(tr('વાહન ખરીદો', 'वाहन खरीदें', 'Buy Vehicle')),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                DropdownButtonFormField<String>(
                  value: selectedCategory,
                  decoration: const InputDecoration(
                    labelText: 'વાહનનો પ્રકાર પસંદ કરો',
                    border: OutlineInputBorder(),
                  ),
                  items: categories.map((category) {
                    return DropdownMenuItem(
                      value: category,
                      child: Text(category),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => selectedCategory = value);
                    }
                  },
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: searchController,
                  decoration: InputDecoration(
                    labelText: 'વાહનનું નામ અથવા મોડેલ શોધો',
                    prefixIcon: const Icon(Icons.search),
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        searchController.clear();
                        setState(() => searchText = '');
                      },
                    ),
                  ),
                  onChanged: (value) {
                    setState(() => searchText = value.toLowerCase());
                  },
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: minPriceController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'ઓછામાં ઓછી કિંમત',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: maxPriceController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'વધુમાં વધુ કિંમત',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: sortBy,
                  decoration: const InputDecoration(
                    labelText: 'ક્રમ ગોઠવો',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'નવી જાહેરાત',
                      child: Text('નવી જાહેરાત'),
                    ),
                    DropdownMenuItem(
                      value: 'ઓછી કિંમત પહેલા',
                      child: Text('ઓછી કિંમત પહેલા'),
                    ),
                    DropdownMenuItem(
                      value: 'વધુ કિંમત પહેલા',
                      child: Text('વધુ કિંમત પહેલા'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) setState(() => sortBy = value);
                  },
                ),
              ],
            ),
          ),
          const Divider(),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('vehicles')
                  .where('category', isEqualTo: selectedCategory)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(child: Text('ડેટા લોડ કરવામાં ભૂલ'));
                }

                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data!.docs.where((doc) {
                  final data = doc.data();
                  final title =
                      (data['title'] ?? '').toString().toLowerCase();
                  final model =
                      (data['model'] ?? '').toString().toLowerCase();
                  final priceValue = data['price'];
                  final price = priceValue is num
                      ? priceValue
                      : num.tryParse('$priceValue') ?? 0;

                  if (searchText.isNotEmpty &&
                      !title.contains(searchText) &&
                      !model.contains(searchText)) {
                    return false;
                  }

                  if (minPrice != null && price < minPrice!) return false;
                  if (maxPrice != null && price > maxPrice!) return false;

                  return true;
                }).toList();

                docs.sort((a, b) {
                  final av = a.data()['price'];
                  final bv = b.data()['price'];
                  final aPrice =
                      av is num ? av : num.tryParse('$av') ?? 0;
                  final bPrice =
                      bv is num ? bv : num.tryParse('$bv') ?? 0;

                  if (sortBy == 'ઓછી કિંમત પહેલા') {
                    return aPrice.compareTo(bPrice);
                  }
                  if (sortBy == 'વધુ કિંમત પહેલા') {
                    return bPrice.compareTo(aPrice);
                  }

                  final aTime = a.data()['createdAt'];
                  final bTime = b.data()['createdAt'];
                  if (aTime is Timestamp && bTime is Timestamp) {
                    return bTime.compareTo(aTime);
                  }
                  return 0;
                });

                if (docs.isEmpty) {
                  return const Center(
                    child: Text('હાલમાં કોઈ વાહનની જાહેરાત નથી.'),
                  );
                }

                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    return VehicleCard(
                      vehicleId: doc.id,
                      data: doc.data(),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}// ---------------- VEHICLE CARD ----------------

class VehicleCard extends StatelessWidget {
  final String vehicleId;
  final Map<String, dynamic> data;

  const VehicleCard({
    super.key,
    required this.vehicleId,
    required this.data,
  });

  Future<void> _contactSeller(
    BuildContext context,
    String phone,
  ) async {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.call, color: Colors.green),
                title: const Text('કોલ કરો'),
                onTap: () async {
                  Navigator.pop(context);
                  final uri = Uri.parse('tel:$phone');
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri);
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.chat, color: Colors.green),
                title: const Text('WhatsApp કરો'),
                onTap: () async {
                  Navigator.pop(context);
                  final cleanPhone = phone.replaceAll(
                    RegExp(r'[^0-9]'),
                    '',
                  );
                  final uri = Uri.parse(
                    'https://wa.me/$cleanPhone',
                  );
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(
                      uri,
                      mode: LaunchMode.externalApplication,
                    );
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _delete(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('જાહેરાત ડિલીટ કરવી છે?'),
        content: const Text('આ જાહેરાત કાયમ માટે ડિલીટ થશે.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('ના'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('હા, ડિલીટ કરો'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final photos = List<String>.from(data['imageUrls'] ?? []);

      await FirebaseFirestore.instance
          .collection('vehicles')
          .doc(vehicleId)
          .delete();

      for (final url in photos) {
        try {
          await FirebaseStorage.instance.refFromURL(url).delete();
        } catch (_) {}
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('જાહેરાત ડિલીટ થઈ ગઈ')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ડિલીટ કરવામાં ભૂલ: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final ownerUid = (data['ownerUid'] ?? '').toString();
    final isOwner = user != null && user.uid == ownerUid;

    final title = (data['title'] ?? data['model'] ?? 'વાહન').toString();
    final price = (data['price'] ?? '').toString();
    final location = (data['location'] ?? '').toString();
    final description = (data['description'] ?? '').toString();
    final phone = (data['phone'] ?? '').toString();
    final images = List<String>.from(data['imageUrls'] ?? []);

    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 7,
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (images.isNotEmpty)
              SizedBox(
                height: 190,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: images.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.network(
                          images[index],
                          width: 230,
                          height: 190,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              const Icon(Icons.directions_car, size: 80),
                        ),
                      ),
                    );
                  },
                ),
              ),
            const SizedBox(height: 10),
            Text(
              title,
              style: const TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '₹ $price',
              style: const TextStyle(
                fontSize: 18,
                color: Colors.green,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (location.isNotEmpty)
              Text('📍 $location'),
            if (description.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 5),
                child: Text(description),
              ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              children: [
                if (!isOwner && phone.isNotEmpty)
                  ElevatedButton.icon(
                    onPressed: () => _contactSeller(context, phone),
                    icon: const Icon(Icons.call),
                    label: const Text('સંપર્ક કરો'),
                  ),
                if (!isOwner && user != null)
                  OutlinedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ChatPage(
                            vehicleId: vehicleId,
                            sellerUid: ownerUid,
                            vehicleTitle: title,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.chat),
                    label: const Text('ચેટ કરો'),
                  ),
                if (isOwner)
                  IconButton(
                    tooltip: 'મારી જાહેરાત ડિલીટ કરો',
                    icon: const Icon(
                      Icons.delete_outline,
                      color: Colors.red,
                    ),
                    onPressed: () => _delete(context),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------- SELL VEHICLE ----------------

class SellVehiclePage extends StatefulWidget {
  const SellVehiclePage({super.key});

  @override
  State<SellVehiclePage> createState() => _SellVehiclePageState();
}

class _SellVehiclePageState extends State<SellVehiclePage> {
  final formKey = GlobalKey<FormState>();

  final titleController = TextEditingController();
  final modelController = TextEditingController();
  final priceController = TextEditingController();
  final locationController = TextEditingController();
  final descriptionController = TextEditingController();
  final phoneController = TextEditingController();

  String category = 'કાર';
  bool uploading = false;

  final picker = ImagePicker();
  final List<XFile> selectedImages = [];

  Future<void> pickImages() async {
    try {
      final images = await picker.pickMultiImage();

      if (images.isEmpty) return;

      setState(() {
        selectedImages.addAll(
          images.take(5 - selectedImages.length),
        );
      });

      if (images.length + selectedImages.length > 5) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('વધુમાં વધુ 5 ફોટા પસંદ કરી શકો છો.'),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ફોટા પસંદ કરવામાં ભૂલ: $e')),
      );
    }
  }

  Future<void> saveVehicle() async {
    if (!formKey.currentState!.validate()) return;

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('પહેલા લોગિન કરો')),
      );
      return;
    }

    setState(() => uploading = true);

    final uploadedUrls = <String>[];

    try {
      for (int i = 0; i < selectedImages.length; i++) {
        final file = File(selectedImages[i].path);

        final ref = FirebaseStorage.instance
            .ref()
            .child('vehicle_photos')
            .child(user.uid)
            .child('${DateTime.now().millisecondsSinceEpoch}_$i.jpg');

        await ref.putFile(file);

        final url = await ref.getDownloadURL();
        uploadedUrls.add(url);
      }

      await FirebaseFirestore.instance.collection('vehicles').add({
        'ownerUid': user.uid,
        'category': category,
        'title': titleController.text.trim(),
        'model': modelController.text.trim(),
        'price': int.parse(priceController.text.trim()),
        'location': locationController.text.trim(),
        'description': descriptionController.text.trim(),
        'phone': phoneController.text.trim(),
        'imageUrls': uploadedUrls,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('તમારી જાહેરાત સફળતાપૂર્વક ઉમેરાઈ ગઈ!'),
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      for (final url in uploadedUrls) {
        try {
          await FirebaseStorage.instance.refFromURL(url).delete();
        } catch (_) {}
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('જાહેરાત ઉમેરવામાં ભૂલ: $e')),
        );
      }
    }

    if (mounted) setState(() => uploading = false);
  }

  @override
  void dispose() {
    titleController.dispose();
    modelController.dispose();
    priceController.dispose();
    locationController.dispose();
    descriptionController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('વાહન વેચો')),
      body: Form(
        key: formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            DropdownButtonFormField<String>(
              value: category,
              decoration: const InputDecoration(
                labelText: 'વાહનનો પ્રકાર',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'કાર', child: Text('કાર')),
                DropdownMenuItem(value: 'બાઈક', child: Text('બાઈક')),
                DropdownMenuItem(value: 'ટ્રક', child: Text('ટ્રક')),
                DropdownMenuItem(value: 'ટ્રેક્ટર', child: Text('ટ્રેક્ટર')),
              ],
              onChanged: (value) {
                if (value != null) setState(() => category = value);
              },
            ),
            const SizedBox(height: 12),
            _input(titleController, 'વાહનનું નામ', required: true),
            _input(modelController, 'મોડેલ'),
            _input(
              priceController,
              'કિંમત',
              required: true,
              number: true,
            ),
            _input(locationController, 'શહેર / ગામ', required: true),
            _input(descriptionController, 'વાહનની માહિતી'),
            _input(
              phoneController,
              'મોબાઇલ નંબર',
              number: true,
            ),
            const SizedBox(height: 15),
            OutlinedButton.icon(
              onPressed: selectedImages.length >= 5 ? null : pickImages,
              icon: const Icon(Icons.photo_library),
              label: Text(
                'ફોટા પસંદ કરો (${selectedImages.length}/5)',
              ),
            ),
            if (selectedImages.isNotEmpty)
              SizedBox(
                height: 100,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: selectedImages.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.all(5),
                      child: Stack(
                        children: [
                          Image.file(
                            File(selectedImages[index].path),
                            width: 90,
                            height: 90,
                            fit: BoxFit.cover,
                          ),
                          Positioned(
                            right: 0,
                            top: 0,
                            child: InkWell(
                              onTap: () {
                                setState(() {
                                  selectedImages.removeAt(index);
                                });
                              },
                              child: const Icon(
                                Icons.cancel,
                                color: Colors.red,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            const SizedBox(height: 20),
            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: uploading ? null : saveVehicle,
                child: uploading
                    ? const CircularProgressIndicator()
                    : const Text(
                        'જાહેરાત ઉમેરો',
                        style: TextStyle(fontSize: 18),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _input(
    TextEditingController controller,
    String label, {
    bool required = false,
    bool number = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        keyboardType:
            number ? TextInputType.number : TextInputType.text,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        validator: (value) {
          if (required && (value == null || value.trim().isEmpty)) {
            return 'આ માહિતી લખવી જરૂરી છે';
          }

          if (label == 'કિંમત' &&
              (int.tryParse(value ?? '') == null ||
                  int.parse(value!) <= 0)) {
            return 'યોગ્ય કિંમત લખો';
          }

          return null;
        },
      ),
    );
  }
}

// ---------------- CHAT PAGE ----------------

class ChatPage extends StatefulWidget {
  final String vehicleId;
  final String sellerUid;
  final String vehicleTitle;

  const ChatPage({
    super.key,
    required this.vehicleId,
    required this.sellerUid,
    required this.vehicleTitle,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final messageController = TextEditingController();

  String get roomId {
    final user = FirebaseAuth.instance.currentUser!;
    final ids = [user.uid, widget.sellerUid]..sort();
    return '${widget.vehicleId}_${ids[0]}_${ids[1]}';
  }

  Future<void> sendMessage() async {
    final text = messageController.text.trim();
    final user = FirebaseAuth.instance.currentUser;

    if (text.isEmpty || user == null) return;

    messageController.clear();

    try {
      final roomRef =
          FirebaseFirestore.instance.collection('chats').doc(roomId);

      await roomRef.set({
        'vehicleId': widget.vehicleId,
        'vehicleTitle': widget.vehicleTitle,
        'participants': [user.uid, widget.sellerUid],
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await roomRef.collection('messages').add({
        'senderUid': user.uid,
        'text': text,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('મેસેજ મોકલવામાં ભૂલ: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser!;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.vehicleTitle),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('chats')
                  .doc(roomId)
                  .collection('messages')
                  .orderBy('createdAt')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                final messages = snapshot.data!.docs;

                if (messages.isEmpty) {
                  return const Center(
                    child: Text('ચેટ શરૂ કરો.'),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final data = messages[index].data();
                    final isMine = data['senderUid'] == user.uid;

                    return Align(
                      alignment: isMine
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 5),
                        padding: const EdgeInsets.all(12),
                        constraints: const BoxConstraints(
                          maxWidth: 280,
                        ),
                        decoration: BoxDecoration(
                          color: isMine
                              ? Colors.green.shade100
                              : Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          (data['text'] ?? '').toString(),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: messageController,
                      decoration: const InputDecoration(
                        hintText: 'મેસેજ લખો...',
                        border: OutlineInputBorder(),
                      ),
                      onSubmitted: (_) => sendMessage(),
                    ),
                  ),
                  IconButton(
                    onPressed: sendMessage,
                    icon: const Icon(
                      Icons.send,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
