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

  Widget _buildIncomeCard() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.backgroundYellow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(width: 3, color: AppColors.backgroundOrange),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            offset: Offset(0, 2),
            blurRadius: 6,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Total Income",
                style: AppTypography.textMd.copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "Rs. ${totalIncome.toString()}",
                style: AppTypography.textMd.copyWith(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.backgroundOrange,
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                "UPI ID",
                style: AppTypography.textMd.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                widget.shop.upiId,
                style: AppTypography.textMd.copyWith(
                  fontSize: 14,
                  color: AppColors.backgroundOrange,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUpdateMenuButton(BuildContext context) {
    final List<String> items = ["Update Menu", "Add Menu"];

    return Center(
      child: SizedBox(
        height: 100, // Đảm bảo chiều cao cho ListView
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: items.length,
          itemBuilder: (BuildContext context, int index) {
            return GestureDetector(
              onTap: () {
                if (index == 0) {
                  // Điều hướng đến trang chỉnh sửa menu
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) =>
                            UpdateMenuItemPage(shop: widget.shop, menu: menu)),
                  );
                } else if (index == 1) {
                  // Điều hướng đến trang thêm menu
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) =>
                            AddMenuItemPage(shop: widget.shop, menu: menu)),
                  );
                }
              },
              child: Padding(
                padding: const EdgeInsets.only(right: 15),
                child: Container(
                  width: 150,
                  padding: const EdgeInsets.symmetric(vertical: 25),
                  decoration: BoxDecoration(
                      color: AppColors.signIn,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        width: 3,
                        color: AppColors.backgroundOrange,
                      )),
                  child: Center(
                    child: Text(
                      items[index],
                      style: AppTypography.textMd.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 20,
                        color: AppColors.backgroundOrange,
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class HistoryPage extends StatefulWidget {
  final ShopModel shop;

  const HistoryPage({super.key, required this.shop});

  @override
  _HistoryPageState createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  List card = [];
  bool isLoading = true;
  String errorMessage = '';
  String selectedButton = "All";
  // bool isPay = false;

  @override
  void initState() {
    super.initState();
    fetchOrders();
  }

  Future<void> fetchOrders() async {
    try {
      // Lấy toàn bộ dữ liệu từ Firestore
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('orders')
          .where('shop_name', isEqualTo: widget.shop.shopName)
          .get();

      setState(() {
        // Lấy danh sách tất cả các đơn hàng
        List<List<dynamic>> allOrders = snapshot.docs.map((doc) {
          var data = doc.data() as Map<String, dynamic>;
          return [
            data['buyer_name'] ?? 'Unknown',
            data['order_name'] ?? 'Unknown',
            data['price']?.toString() ?? '0',
            data['date'] ?? 'Unknown',
            data['img'] ?? 'Unknown',
            data['rating'] ?? 0.0,
            data['review'] ?? '',
            data['pay'] ?? false,
          ];
        }).toList();

        // Lọc đơn hàng theo ngày hiện tại nếu chọn "Day"
        if (selectedButton == "Day") {
          DateTime now = DateTime.now();
          String today = DateFormat('dd/MM/yyyy').format(now);

          card = allOrders.where((order) {
            String orderDate = order[3]; // Trường 'date'
            return orderDate == today; // So sánh với ngày hiện tại
          }).toList();
        } else {
          // Hiển thị toàn bộ nếu là "All"
          card = allOrders;
        }

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

  void _showReviewDialog(BuildContext context, String review) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Review',
            style: TextStyle(
              color: AppColors.backgroundOrange,
            ),
          ),
          content: Text(review),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Close',
                style: TextStyle(
                  color: AppColors.backgroundOrange,
                ),
              ),
            ),
          ],
        );
      },
    );
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
        title: Text("Order History",
            style: AppTypography.textMd.copyWith(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.backgroundOrange)),
        backgroundColor: AppColors.backgroundYellow,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: IconButton(
              onPressed: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => Scanner(shop: widget.shop),
                    ));
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
      ),
      backgroundColor: AppColors.backgroundYellow,
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage.isNotEmpty
              ? Center(child: Text(errorMessage))
              : SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Thẻ thông tin cửa hàng hoặc bất kỳ widget nào bạn muốn hiển thị
                      Container(
                        margin: const EdgeInsets.all(20),
                        padding: const EdgeInsets.all(20),
                        height: 120,
                        decoration: BoxDecoration(
                            border: Border.all(
                                color: AppColors.backgroundOrange, width: 2),
                            borderRadius:
                                const BorderRadius.all(Radius.circular(20))),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.pin_drop_rounded,
                                      size: 25,
                                    ),
                                    SizedBox(
                                      width: 10,
                                    ),
                                    Text(widget.shop.shopName.toUpperCase(),
                                        style: AppTypography.textMd.copyWith(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700)),
                                  ],
                                ),
                                Row(
                                  children: [
                                    const Icon(Icons.timelapse_rounded,
                                        size: 25),
                                    SizedBox(
                                      width: 10,
                                    ),
                                    Text(
                                        "${widget.shop.openingTime} AM TO ${widget.shop.closingTime} PM",
                                        style: AppTypography.textMd.copyWith(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700)),
                                  ],
                                ),
                                Row(
                                  children: [
                                    const Icon(Icons.shopping_cart, size: 25),
                                    SizedBox(
                                      width: 10,
                                    ),
                                    Text("${card.length} ITEMS IN STOCK",
                                        style: AppTypography.textMd.copyWith(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700)),
                                  ],
                                ),
                                // Container(
                                //     width: 30,
                                //     padding: const EdgeInsets.all(2),
                                //     decoration: BoxDecoration(
                                //         borderRadius: BorderRadius.circular(5),
                                //         color: AppColors.signIn),
                                //     child: Row(
                                //       children: [
                                //         Text(
                                //           "0",
                                //           style: AppTypography.textSm.copyWith(
                                //               fontSize: 15,
                                //               fontWeight: FontWeight.w700),
                                //         ),
                                //         const Icon(
                                //           Icons.star,
                                //           size: 15,
                                //         )
                                //       ],
                                //     )
                                //     )
                              ],
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "All Orders",
                              style: AppTypography.textMd.copyWith(
                                  fontSize: 20, fontWeight: FontWeight.w700),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _buildButtonHst("All"),
                                _buildButtonHst("Day"),
                              ],
                            ),
                          ],
                        ),
                      ),
                      card.isEmpty
                          ? Padding(
                              padding: const EdgeInsets.all(20),
                              child: Text(
                                "No orders found",
                                style: AppTypography.textMd.copyWith(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            )
                          : ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: card.length,
                              itemBuilder: (context, index) {
                                final order = card[index];
                                return Padding(
                                  padding:
                                      const EdgeInsets.fromLTRB(20, 0, 20, 5),
                                  child: Container(
                                    decoration: BoxDecoration(
                                        color: const Color(0xFFFFF2E0),
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: order[7]
                                              ? Colors.green
                                              : Colors.red,
                                          width: 5,
                                        )),
                                    child: Padding(
                                      padding: const EdgeInsets.all(10),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.start,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.fromLTRB(
                                                          0, 15, 0, 0),
                                                  child: Text(
                                                      "User : ${order[0]}",
                                                      style: AppTypography
                                                          .textSm
                                                          .copyWith(
                                                              fontSize: 14)),
                                                ),
                                                Text(
                                                  "Order : ${order[1]}",
                                                  style: AppTypography.textSm
                                                      .copyWith(
                                                          fontSize: 14,
                                                          fontWeight:
                                                              FontWeight.w400),
                                                ),
                                                Text(
                                                  "Price : ${order[2]}",
                                                  style: AppTypography.textSm
                                                      .copyWith(
                                                          fontSize: 14,
                                                          fontWeight:
                                                              FontWeight.w400),
                                                ),
                                                Text(
                                                  "Time : ${order[3]}",
                                                  style: AppTypography.textSm
                                                      .copyWith(
                                                          fontSize: 14,
                                                          fontWeight:
                                                              FontWeight.w400),
                                                ),
                                                Row(
                                                  children: [
                                                    CircleAvatar(
                                                      radius:
                                                          15, // Điều chỉnh bán kính để phù hợp với kích thước icon
                                                      backgroundColor: const Color(
                                                          0xFFFFF2E0), // Màu nền
                                                      child: IconButton(
                                                        icon: Icon(
                                                          Icons.comment,
                                                          size:
                                                              15, // Kích thước biểu tượng
                                                          color: Colors
                                                              .grey, // Màu biểu tượng
                                                        ),
                                                        onPressed: () =>
                                                            _showReviewDialog(
                                                                context,
                                                                order[6]),
                                                      ),
                                                    ),
                                                    RatingBarIndicator(
                                                      rating:
                                                          order[5].toDouble(),
                                                      itemBuilder:
                                                          (context, _) => Icon(
                                                        Icons.star,
                                                        color: Colors.amber,
                                                      ),
                                                      itemCount: 5,
                                                      itemSize: 20.0,
                                                    ),
                                                  ],
                                                )
                                              ],
                                            ),
                                          ),
                                          SizedBox(
                                            width: 10,
                                          ),
                                          Container(
                                            height: 120,
                                            width: 120,
                                            decoration: BoxDecoration(
                                                border: Border.all(
                                                    color: AppColors
                                                        .backgroundOrange,
                                                    width: 1.5),
                                                borderRadius:
                                                    BorderRadius.circular(20)),
                                            child: ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                              child: Image.network(
                                                order[4],
                                                fit: BoxFit.cover,
                                                errorBuilder: (context, error,
                                                    stackTrace) {
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
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                    ],
                  ),
                ),
      // Nếu bạn muốn cuộn lên đầu khi có nhiều nội dung, hãy xem xét sử dụng ListView thay vì SingleChildScrollView với Column
    );
  }

  Widget _buildButtonHst(String label) {
    final isSelected = selectedButton == label;
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedButton = label;
          fetchOrders();
        });
      },
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 8, horizontal: 10),
        decoration: BoxDecoration(
          border: Border(
            bottom: isSelected
                ? BorderSide(color: AppColors.backgroundOrange, width: 2)
                : BorderSide.none,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppColors.backgroundOrange : Colors.grey,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

class InfoPage extends StatefulWidget {
  final ShopModel shop;

  const InfoPage({super.key, required this.shop});

  @override
  _InfoPageState createState() => _InfoPageState();
}

class _InfoPageState extends State<InfoPage> {
  late TextEditingController ownerNameController;
  late TextEditingController phoneNumberController;
  late TextEditingController shopNameController;
  late TextEditingController openingTimeController;
  late TextEditingController closingTimeController;
  late TextEditingController upiIdController;

  bool _isEditable = false;
  bool _isUpdating = false;
  String _updateMessage = '';
  bool _showMessage = false;
  Map<String, dynamic>? weatherData;

  @override
  void initState() {
    super.initState();
    ownerNameController = TextEditingController(text: widget.shop.ownerName);
    phoneNumberController =
        TextEditingController(text: widget.shop.phoneNumber);
    shopNameController = TextEditingController(text: widget.shop.shopName);
    openingTimeController =
        TextEditingController(text: widget.shop.openingTime);
    closingTimeController =
        TextEditingController(text: widget.shop.closingTime);
    upiIdController = TextEditingController(text: widget.shop.upiId);
    fetchWeather();
  }

  @override
  void dispose() {
    ownerNameController.dispose();
    phoneNumberController.dispose();
    shopNameController.dispose();
    openingTimeController.dispose();
    closingTimeController.dispose();
    upiIdController.dispose();
    super.dispose();
  }

  Future<void> fetchWeather() async {
    try {
      final response = await http.get(
        Uri.parse(
          'https://api.openweathermap.org/data/2.5/weather?q=Hanoi&appid=e0ea7c2430957c0b90c7a6375a5f8cba&units=metric',
        ),
      );
      if (response.statusCode == 200) {
        setState(() {
          weatherData = json.decode(response.body);
        });
      } else {
        throw Exception('Failed to load weather data');
      }
    } catch (e) {
      print('Error fetching weather data: $e');
    }
  }

  Future<void> updateShop() async {
    setState(() {
      _isUpdating = true;
      _updateMessage = '';
      _showMessage = false;
    });

    try {
      // Tìm kiếm document dựa trên điều kiện
      final shopQuery = FirebaseFirestore.instance
          .collection('shop')
          .where('shop_id', isEqualTo: widget.shop.shopID);

      // Lấy snapshot của document
      final querySnapshot = await shopQuery.get();

      if (querySnapshot.docs.isNotEmpty) {
        // Giả sử bạn muốn cập nhật document đầu tiên tìm thấy
        final shopRef = querySnapshot.docs.first.reference;

        await shopRef.update({
          'owner_name': ownerNameController.text,
          'phone_number': phoneNumberController.text,
          'shop_name': shopNameController.text,
          'opening_time': openingTimeController.text,
          'closing_time': closingTimeController.text,
          'upi_id': upiIdController.text,
        });

        setState(() {
          _updateMessage = 'Shop information updated successfully!';
          _isEditable = false;
          _showMessage = true;
        });
        Future.delayed(const Duration(seconds: 5), () {
          setState(() {
            _showMessage = false; // Ẩn thông báo
          });
        });
      } else {
        setState(() {
          _updateMessage = "Error : No shop found .";
          _showMessage = true;
        });
        Future.delayed(const Duration(seconds: 5), () {
          setState(() {
            _showMessage = false; // Ẩn thông báo
          });
        });
      }
    } catch (e) {
      setState(() {
        _updateMessage = 'Error updating shop: $e';
        _showMessage = true;
      });
      print('Error updating shop: $e');
    } finally {
      setState(() {
        _isUpdating = false;
      });
    }
  }

  IconData _getWeatherIcon(String main) {
    switch (main.toLowerCase()) {
      case 'clear':
        return Icons.wb_sunny;
      case 'clouds':
        return Icons.cloud;
      case 'rain':
        return Icons.umbrella;
      case 'snow':
        return Icons.ac_unit;
      case 'thunderstorm':
        return Icons.flash_on;
      default:
        return Icons.wb_cloudy;
    }
  }

  void logOut() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0), // Bo góc cho hộp thoại
          ),
          backgroundColor: AppColors.backgroundYellow,
          title: Row(
            children: [
              Icon(Icons.exit_to_app,
                  color: Colors.orange, size: 30), // Biểu tượng
              const SizedBox(width: 10),
              const Text(
                "LogOut | ChangeRole ",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "What do you want to do next ?",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.black87),
              ),
            ],
          ),
          actionsAlignment: MainAxisAlignment.spaceEvenly,
          actions: [
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const UserType()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.swap_horiz),
              label: const Text("ChangeRole"),
            ),
            OutlinedButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                );
              },
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.orange),
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.logout, color: Colors.orange),
              label: const Text(
                "LogOut",
                style: TextStyle(color: Colors.orange),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget inputText(TextEditingController controller, String hintText,
      {double width = 250, double height = 50}) {
    return Padding(
      padding: const EdgeInsets.all(5),
      child: SizedBox(
        width: width, // Chiều rộng của trường nhập liệu
        child: TextFormField(
          decoration: InputDecoration(
            enabledBorder: const OutlineInputBorder(
              borderSide:
                  BorderSide(width: 2, color: Color.fromRGBO(238, 118, 0, 1)),
              borderRadius: BorderRadius.all(Radius.circular(10)),
            ),
            focusedBorder: const OutlineInputBorder(
              borderSide:
                  BorderSide(width: 2, color: Color.fromRGBO(238, 118, 0, 1)),
              borderRadius: BorderRadius.all(Radius.circular(10)),
            ),
            hintText: hintText,
            suffixIcon: IconButton(
              icon: Icon(
                Icons.edit,
                color: _isEditable
                    ? Colors.grey[400]
                    : const Color.fromRGBO(238, 118, 0, 1),
              ),
              onPressed: () {
                setState(() {
                  _isEditable = !_isEditable;
                });
              },
            ),
          ),
          readOnly: !_isEditable, // Nếu không editable thì sẽ chỉ hiển thị
          controller: controller,
          style: TextStyle(
              height: height / 24), // Điều chỉnh chiều cao của TextFormField
        ),
      ),
    );
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
        title: Text("Profile",
            style: AppTypography.textMd.copyWith(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.backgroundOrange)),
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
      ),
      backgroundColor: AppColors.backgroundYellow,
      body: SingleChildScrollView(
        child: Stack(
          children: [
            Column(
              children: [
                Container(
                  height: 120,
                  width: double.infinity,
                  decoration: BoxDecoration(
                      borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(20),
                          topRight: Radius.circular(20)),
                      color: Colors.amber[900]),
                ),
                Container(
                  height: 500,
                  width: double.infinity,
                  decoration: const BoxDecoration(
                      borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(20),
                          bottomRight: Radius.circular(20)),
                      color: Colors.white),
                ),
              ],
            ),
            Align(
              alignment: Alignment.topCenter,
              child: Container(
                margin: const EdgeInsets.only(top: 5),
                child: Column(
                  children: [
                    Text(
                      "CAMPUS MEAL",
                      style: TextStyle(
                        fontSize: 16.5,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    if (weatherData != null)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _getWeatherIcon(weatherData!['weather'][0]['main']),
                            color: const Color.fromARGB(255, 58, 179, 234),
                            size: 20,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            'Hà Nội: ${weatherData!['main']['temp']}°C, ',
                            style: const TextStyle(
                                fontSize: 16.5,
                                fontWeight: FontWeight.bold,
                                color: Color.fromARGB(255, 0, 0, 0)),
                          ),
                          Text(
                            weatherData!['weather'][0]['description'],
                            style: const TextStyle(
                                fontSize: 16.5,
                                color: Color.fromARGB(255, 0, 0, 0)),
                          ),
                        ],
                      )
                    else
                      const CircularProgressIndicator(),
                  ],
                ),
              ),
            ),
            Align(
              alignment: Alignment.topCenter,
              child: Container(
                margin: const EdgeInsets.only(top: 50),
                height: 130,
                width: 130,
                decoration: BoxDecoration(
                  border: Border.all(
                      color: Color.fromRGBO(122, 103, 238, 1), width: 3),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(100),
                  child: Image.asset(
                    "assets/iconprofile.png",
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 95,
              left: (MediaQuery.of(context).size.width - 250) /
                  2, // Căn giữa form
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Điều chỉnh chiều rộng và khoảng cách giữa các trường
                  inputText(ownerNameController, "Owner Name",
                      width: 250, height: 20),
                  inputText(phoneNumberController, "Phone Number",
                      width: 250, height: 20),
                  inputText(shopNameController, "Shop Name",
                      width: 250, height: 20),
                  inputText(openingTimeController, "Opening Time",
                      width: 250, height: 20),
                  inputText(closingTimeController, "Closing Time",
                      width: 250, height: 20),
                  inputText(upiIdController, "UPI ID", width: 250, height: 20),
                ],
              ),
            ),
            Positioned(
              bottom: 12,
              left: (MediaQuery.of(context).size.width - 300) / 2 + 25,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      GestureDetector(
                        onTap: _isUpdating
                            ? null
                            : () {
                                if (_isEditable) {
                                  updateShop();
                                }
                              },
                        child: Container(
                          width: 100,
                          height: 35,
                          decoration: const BoxDecoration(
                            color: Color.fromRGBO(238, 118, 0, 1),
                            borderRadius: BorderRadius.all(Radius.circular(10)),
                          ),
                          child: Center(
                            child: _isUpdating
                                ? const CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white),
                                  )
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: const [
                                      Icon(
                                        Icons.update,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        "UPDATE",
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  BuyerSelectionScreen(shop: widget.shop),
                            ),
                          );
                        },
                        child: Container(
                          width: 100,
                          height: 35,
                          decoration: const BoxDecoration(
                            color: Colors.blue,
                            borderRadius: BorderRadius.all(Radius.circular(10)),
                          ),
                          child: const Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.chat,
                                  color: Colors.white,
                                  size: 20,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  "Chat",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Hàng 2: Nút Log Out | Change Role
                  GestureDetector(
                    onTap: logOut,
                    child: Container(
                      width: MediaQuery.of(context).size.width * 2 / 3,
                      height: 35,
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.exit_to_app,
                              color: Colors.white,
                              size: 18,
                            ),
                            SizedBox(width: 8),
                            Text(
                              "Log Out | Change Role",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (_showMessage && _updateMessage.isNotEmpty)
              Positioned(
                bottom: 570,
                left: 20,
                right: 20,
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _updateMessage.contains('Error')
                        ? Colors.redAccent
                        : Colors.green,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    _updateMessage,
                    style: const TextStyle(color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
