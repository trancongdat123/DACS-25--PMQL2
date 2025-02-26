import 'package:campus_catalogue/add_item.dart';
import 'package:campus_catalogue/constants/colors.dart';
import 'package:campus_catalogue/constants/typography.dart';
import 'package:campus_catalogue/models/order_model.dart';
import 'package:campus_catalogue/models/shopModel.dart';
import 'package:campus_catalogue/screens/login.dart';
import 'package:campus_catalogue/screens/add_menu.dart';
import 'package:campus_catalogue/screens/Scanner/qr_code_scanner.dart';
import 'package:campus_catalogue/screens/Scanner/scanner.dart';
import 'package:campus_catalogue/screens/sele_buyer.dart';
import 'package:campus_catalogue/screens/update_menu.dart';
import 'package:campus_catalogue/screens/userType_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:campus_catalogue/services/database_service.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class OrderWrapper extends StatelessWidget {
  final List<dynamic> orders;
  const OrderWrapper({super.key, required this.orders});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.of(context).size.height,
      child: ListView.builder(
        itemCount: orders.length,
        itemBuilder: (context, index) {
          final order = orders[index];
          return Column(
            children: [
              OrderTile(
                buyerName: order["buyer_name"],
                buyerPhone: order["buyer_phone"],
                status: order["status"],
                totalAmount: order["total_amount"],
                txnId: order["txnId"],
              ),
              const SizedBox(height: 10),
            ],
          );
        },
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  final ShopModel shop;
  const HomePage({super.key, required this.shop});

  @override
  State<HomePage> createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  List card = [];
  bool isLoading = true;
  String errorMessage = '';
  num totalIncome = 0;
  List menu = [];

  @override
  void initState() {
    super.initState();
    fetchOrders();
    initializeMenu();
  }

  Future<void> fetchOrders() async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('orders')
          .where('shop_name', isEqualTo: widget.shop.shopName)
          .get();

      setState(() {
        card = snapshot.docs.map((doc) {
          var data = doc.data() as Map<String, dynamic>;

          totalIncome += (data['price'] ?? 0);
          return [
            data['buyer_name'] ?? 'Unknown',
            data['order_name'] ?? 'Unknown',
            data['price'] ?? 0,
            data['date'] ?? 'Unknown',
            data['img'] ?? 'Unknown', // Đảm bảo 'img' tồn tại trong Firestore
          ];
        }).toList();
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Error fetching orders: $e';
        isLoading = false;
      });
      print('Error fetching orders: $e');
    }
  }

  // List<Map<String, dynamic>> menu = [];
  // void initializeMenu() {
  //   setState(() {
  //     menu = List<Map<String, dynamic>>.from(widget.shop.menu.map((item) => {
  //           "name": item["name"],
  //           "price": item["price"],
  //           "vegetarian": item["vegetarian"],
  //           "description": item["description"],
  //           "category": item["category"],
  //           "img": item['img']
  //         }));
  //     isLoading = false;
  //   });
  // }
  void initializeMenu() async {
    setState(() {
      isLoading = true;
    });

    try {
      // Truy vấn Firestore dựa trên shop_id
      QuerySnapshot shopSnapshot = await FirebaseFirestore.instance
          .collection('shop')
          .where('shop_id', isEqualTo: widget.shop.shopID)
          .get();

      if (shopSnapshot.docs.isNotEmpty) {
        // Lấy document đầu tiên (giả sử mỗi shop_id là duy nhất)
        DocumentSnapshot shopDoc = shopSnapshot.docs.first;
        Map<String, dynamic> shopData = shopDoc.data() as Map<String, dynamic>;

        List<dynamic> firestoreMenu = shopData['menu'] ?? [];

        setState(() {
          menu = List<Map<String, dynamic>>.from(firestoreMenu.map((item) => {
                "name": item["name"],
                "price": item["price"],
                "vegetarian": item["vegetarian"],
                "description": item["description"],
                "category": item["category"],
                "img": item['img']
              }));
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
        // Trường hợp không tìm thấy shop
        print("Shop không tồn tại");
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      // Xử lý lỗi truy xuất Firestore
      print("Lỗi khi truy xuất menu từ Firestore: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        leading: Icon(
          Icons.circle, // You can choose any icon, but this is just an example.
          color: AppColors.backgroundYellow, // Same color as the background
        ),
        backgroundColor: AppColors.backgroundYellow,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: IconButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => Scanner(
                            shop: widget.shop,
                          )),
                );
              },
              icon: const Icon(
                Icons.qr_code,
                color: AppColors.backgroundOrange,
                size: 27.0,
              ),
            ),
          ),
        ],
        // leading: IconButton(
        //   icon: const Icon(
        //     Icons.arrow_back_ios_new_rounded,
        //     color: AppColors.backgroundOrange,
        //   ),
        //   onPressed: () => Navigator.push(context,
        //       MaterialPageRoute(builder: (context) => const UserType())),
        // ),
        // elevation: 0,
        // centerTitle: true,
        title: GestureDetector(
          onTap: () {
            setState(() {
              initializeMenu();
            });
          },
          child: SingleChildScrollView(
            child: Text(
              "Explore Home",
              style: AppTypography.textMd.copyWith(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.backgroundOrange,
              ),
            ),
          ),
        ),
      ),
      backgroundColor: AppColors.backgroundYellow,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 26, 20, 0),
          child: Column(
            // Thêm Column để chứa các widget
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildIncomeCard(),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Icon(
                    Icons.store,
                    size: 24,
                    color: AppColors.backgroundOrange,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "Shop Management",
                    style: AppTypography.textMd.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: 20,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              _buildUpdateMenuButton(context),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Icon(
                    Icons.menu,
                    size: 24,
                    color: AppColors.backgroundOrange,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "Menu",
                    style: AppTypography.textMd.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 7),
              for (var item in menu)
                Container(
                  margin: EdgeInsets.symmetric(vertical: 4, horizontal: 3),
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.yellow[50],
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.3),
                        spreadRadius: 2,
                        blurRadius: 5,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        padding: EdgeInsets.all(1),
                        decoration: BoxDecoration(
                          color: AppColors.backgroundYellow,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Icon(Icons.storefront,
                              size: 48, color: Colors.orange),
                        ),
                      ),
                      SizedBox(width: 11),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(top: 6, bottom: 3),
                              child: Text(
                                "Name: ${item['name']}",
                                style: AppTypography.textMd.copyWith(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.backgroundOrange,
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(bottom: 3),
                              child: Text(
                                "Price: Rs. ${item['price']}",
                                style: AppTypography.textMd.copyWith(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.green[800],
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: Text(
                                "Description: ${item['description']}",
                                style: AppTypography.textSm.copyWith(
                                  fontSize: 13,
                                  fontWeight: FontWeight.normal,
                                  fontStyle: FontStyle.italic,
                                  color: Colors.black87,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 2,
                              ),
                            ),
                            Divider(
                              color:
                                  AppColors.backgroundOrange.withOpacity(0.5),
                              thickness: 1.5,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Center(
                        child: Container(
                          height: 100,
                          width: 100,
                          padding: EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: const Color.fromARGB(255, 0, 0, 0),
                              width: 1.0,
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(15),
                            child: Image.network(
                              item['img'],
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Image.asset(
                                  'assets/iconshop.jpg',
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  height: double.infinity,
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

