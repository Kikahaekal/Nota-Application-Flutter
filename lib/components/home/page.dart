import 'package:flutter/material.dart';
import 'package:nota_app/components/home/custom_bottom_bar.dart';
import 'package:nota_app/components/home/product_list.dart';
import 'package:nota_app/components/profile/page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: IndexedStack(
          index: _selectedIndex,
          children: [
            ProductList(),
            ProfileContent(),
          ],
        ),
      ),
      floatingActionButton: Container(
        margin: EdgeInsets.only(top: 35),
        child: SizedBox(
          width: 85,
          height: 85,
          child: FloatingActionButton(
            onPressed: () {
              print('Tombol tengah ditekan');
              // Navigator.pushNamed(context, '/print');
            },
            child: Icon(Icons.print, size: 35),
            backgroundColor: Color(0xFF758F44),
            foregroundColor: Colors.white,
            elevation: 4,
            shape: CircleBorder(),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: CustomBottomBar(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
      extendBody: true,
    );
  }
}