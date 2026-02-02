import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';

class TransactionPage extends StatefulWidget {
  const TransactionPage({super.key});

  @override
  State<TransactionPage> createState() => _TransactionPageState();
}

class _TransactionPageState extends State<TransactionPage> {
  BlueThermalPrinter bluetooth = BlueThermalPrinter.instance;
  List<BluetoothDevice> _devices = [];
  BluetoothDevice? _selectedDevice;
  bool _connected = false;

  List<Map<String, dynamic>> cart = [];
  final TextEditingController _qtyController = TextEditingController(text: '1');
  final TextEditingController _customerController = TextEditingController();

  String? selectedProductId;
  String? selectedProductName;
  int? selectedProductPrice;

  final currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    _initBluetooth();
  }

  Future<void> _initBluetooth() async {
    await [
      Permission.bluetooth,
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.location,
    ].request();

    bool? isConnected = await bluetooth.isConnected;
    List<BluetoothDevice> devices = [];
    try {
      devices = await bluetooth.getBondedDevices();
    } catch (e) {
      print("Error getting devices: $e");
    }

    if (mounted) {
      setState(() {
        _devices = devices;
        _connected = isConnected ?? false;
      });
    }
  }

  void _addToCart() {
    if (selectedProductName == null || _qtyController.text.isEmpty) return;
    int qty = int.parse(_qtyController.text);
    int price = selectedProductPrice ?? 0;

    setState(() {
      cart.add({
        'name': selectedProductName,
        'price': price,
        'qty': qty,
        'total': price * qty,
      });
    });
    _qtyController.text = '1';
  }

  int _calculateTotal() {
    return cart.fold(0, (sum, item) => sum + (item['total'] as int));
  }

  void _printReceipt() async {
    if ((await bluetooth.isConnected) != true) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Bluetooth belum terkoneksi!")));
      return;
    }

    String noNota = "N-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}";
    String tanggal = DateFormat('dd/MM/yy HH:mm').format(DateTime.now());
    String namaPelanggan = _customerController.text.isEmpty ? "Umum" : _customerController.text;

    if (namaPelanggan.length > 15) {
      namaPelanggan = namaPelanggan.substring(0, 15);
    }

    bluetooth.isConnected.then((isConnected) {
      if (isConnected == true) {
        bluetooth.printCustom("PINANG MAJU SEJAHTERA", 1, 1);
        bluetooth.printCustom("Jasa Notaris & PPAT", 0, 1);
        bluetooth.printCustom("Tanjung Pinang", 0, 1);
        bluetooth.printNewLine();

        bluetooth.printCustom("NOTA PEMBAYARAN", 1, 1);
        bluetooth.printCustom("--------------------------------", 1, 1);

        bluetooth.printLeftRight("No Nota", ": $noNota", 0);
        bluetooth.printLeftRight("Tanggal", ": $tanggal", 0);
        bluetooth.printLeftRight("Klien", ": $namaPelanggan", 0);

        bluetooth.printCustom("--------------------------------", 1, 1);

        bluetooth.printLeftRight("Item Jasa (Qty)", "Total", 1);
        bluetooth.printNewLine();

        for (var item in cart) {
          String name = item['name'];
          String qtyPrice = "${item['qty']}x${item['price']}";
          String total = currencyFormatter.format(item['total']);

          bluetooth.printCustom(name, 1, 0);
          bluetooth.printLeftRight(qtyPrice, total, 0);
        }

        bluetooth.printCustom("--------------------------------", 1, 1);

        bluetooth.printLeftRight("TOTAL", currencyFormatter.format(_calculateTotal()), 1);
        bluetooth.printCustom("--------------------------------", 1, 1);

        bluetooth.printNewLine();
        bluetooth.printLeftRight("", "Hormat Kami,", 0);
        bluetooth.printNewLine();
        bluetooth.printNewLine();
        bluetooth.printNewLine();
        bluetooth.printLeftRight("", "(....................)", 0);

        bluetooth.printNewLine();
        bluetooth.printCustom("Terima Kasih", 0, 1);
        bluetooth.printNewLine();
        bluetooth.printNewLine();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Cetak Nota"),
        backgroundColor: const Color(0xFFA5CF61),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _initBluetooth,
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.bluetooth, color: Colors.blue),
                  const SizedBox(width: 10),
                  Expanded(
                    child: DropdownButton<BluetoothDevice>(
                      isExpanded: true,
                      hint: const Text("Pilih Printer"),
                      value: _selectedDevice,
                      items: _devices.map((device) {
                        return DropdownMenuItem(
                          value: device,
                          child: Text(device.name ?? "Unknown Device"),
                        );
                      }).toList(),
                      onChanged: (device) {
                        setState(() => _selectedDevice = device);
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _connected ? Colors.red : Colors.blue,
                    ),
                    onPressed: () async {
                      if (_selectedDevice == null) return;
                      if (_connected) {
                        await bluetooth.disconnect();
                        setState(() => _connected = false);
                      } else {
                        await bluetooth.connect(_selectedDevice!);
                        setState(() => _connected = true);
                      }
                    },
                    child: Text(_connected ? "Putus" : "Connect", style: const TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    TextField(
                      controller: _customerController,
                      decoration: const InputDecoration(
                          labelText: "Nama Klien / PT",
                          prefixIcon: Icon(Icons.person),
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 5)
                      ),
                    ),
                    const SizedBox(height: 10),

                    StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance.collection('products').snapshots(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) return const LinearProgressIndicator();

                        List<DropdownMenuItem<String>> items = [];
                        for (var doc in snapshot.data!.docs) {
                          var data = doc.data() as Map<String, dynamic>;
                          int price = (data['price'] is int) ? data['price'] : int.tryParse(data['price'].toString()) ?? 0;

                          items.add(DropdownMenuItem(
                            value: doc.id,
                            onTap: () {
                              selectedProductName = data['name'];
                              selectedProductPrice = price;
                            },
                            child: Text("${data['name']} - ${currencyFormatter.format(price)}"),
                          ));
                        }
                        return DropdownButtonFormField<String>(
                          decoration: const InputDecoration(labelText: "Pilih Jasa / Layanan"),
                          value: selectedProductId,
                          items: items,
                          onChanged: (val) => setState(() => selectedProductId = val),
                        );
                      },
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _qtyController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: "Jumlah"),
                          ),
                        ),
                        ElevatedButton(
                          onPressed: _addToCart,
                          child: const Text("Tambah"),
                        )
                      ],
                    )
                  ],
                ),
              ),
            ),

            Expanded(
              child: ListView.builder(
                itemCount: cart.length,
                itemBuilder: (context, index) {
                  final item = cart[index];
                  return ListTile(
                    title: Text(item['name']),
                    subtitle: Text("${item['qty']} x ${item['price']}"),
                    trailing: Text(currencyFormatter.format(item['total'])),
                    leading: IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => setState(() => cart.removeAt(index))),
                  );
                },
              ),
            ),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [BoxShadow(blurRadius: 5, color: Colors.grey.withOpacity(0.2))]
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Total:", style: TextStyle(fontSize: 16)),
                      Text(currencyFormatter.format(_calculateTotal()),
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF758F44))
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: _connected ? _printReceipt : null,
                      icon: const Icon(Icons.print),
                      label: const Text("CETAK NOTA", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF758F44),
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}