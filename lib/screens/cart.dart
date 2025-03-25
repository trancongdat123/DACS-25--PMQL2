import 'package:campus_catalogue/constants/colors.dart';
import 'package:campus_catalogue/constants/typography.dart';
import 'package:campus_catalogue/models/buyer_model.dart';
import 'package:campus_catalogue/screens/payment_info.dart';
import 'package:campus_catalogue/screens/shop_info.dart';
import 'package:campus_catalogue/services/database_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class Cart extends StatefulWidget {
  final Buyer buyer;

  const Cart({super.key, required this.buyer});

  @override
  CartState createState() => CartState();
}

class CartState extends State<Cart> with RouteAware {
  List<Map<String, dynamic>> items = [];
  List<int> quantities = [];
  num totalPrice = 0;
  String selectedVoucher = '';
  int discount = 0;
  TextEditingController voucherController = TextEditingController();

  final List<Map<String, dynamic>> vouchers = [
    {
      'label': '10% OFF',
      'icon': Icons.percent,
      'description': 'Save 10% on your order',
      'num': 10
    },
    {
      'label': '20% OFF',
      'icon': Icons.percent,
      'description': 'Get 20% discount on your total',
      'num': 20
    },
    {
      'label': '30% OFF',
      'icon': Icons.percent,
      'description': 'Enjoy free shipping on your order',
      'num': 30
    },
    {
      'label': '50% OFF',
      'icon': Icons.percent,
      'description': 'Get another item for free!',
      'num': 50
    },
  ];

  @override
  void initState() {
    super.initState();
    _initRetrieval();
  }

  void _initRetrieval() {
    DatabaseService().getOrders(widget.buyer.userName).listen((data) {
      setState(() {
        items = data
            .map((order) => {
                  'name': order['name'],
                  'price': order['price'],
                  'imgUrl': order['imgUrl'],
                })
            .toList();
        quantities = List<int>.filled(items.length, 1);
      });
      print(items);
    });
  }

  // void removeItem(int index) async {
  //   print(index);
  //   final itemName = items[index]['name'];

  //   // Xóa item khỏi Firebase
  //   await DatabaseService().deleteOrder(widget.buyer.userName, itemName);

  //   // Cập nhật lại danh sách items và quantities
  //   setState(() {
  //     items.removeAt(index);
  //     quantities.removeAt(index);
  //   });
  // }

  void removeItem(String itemName) async {
    // Xóa item khỏi Firebase
    await DatabaseService().deleteOrder(widget.buyer.userName, itemName);

    // Gọi setState để cập nhật lại giao diện
    setState(() {
      // Không cần xóa items và quantities thủ công ở đây
      // Vì StreamBuilder sẽ tự cập nhật lại khi Firestore thay đổi
    });
  }

  void addDiscount(int discount) async {
    FirebaseFirestore _firestore = FirebaseFirestore.instance;

    QuerySnapshot querySnapshot = await _firestore
        .collection('buy')
        .where('buyer_name', isEqualTo: widget.buyer.userName)
        .get();

    if (querySnapshot.docs.isNotEmpty) {
      for (QueryDocumentSnapshot doc in querySnapshot.docs) {
        await _firestore.collection('buy').doc(doc.id).update({
          'discount': discount,
        }).catchError((e) {
          print("Error updating discount: $e");
        });
      }
    } else {
      print('No documents found');
    }
  }

  void _updateQuantities() {
    for (var i = 0; i < items.length; i++) {
      final text = quantities[i].toString();
      quantities[i] = int.tryParse(text) ?? quantities[i]; // Update quantities
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundYellow,
      body: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 36),
        child: Column(
          children: [
            SizedBox(
              height: 200,
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: DatabaseService().getOrders(widget.buyer.userName),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(
                        child: Text('Có lỗi xảy ra: ${snapshot.error}'));
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 90),
                          Text(
                            'CAMPUS MEAL',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'No items in the cart. Please add in the shop',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  final data = snapshot.data!;

                  // Cập nhật danh sách items và quantities từ dữ liệu mới nhất
                  items = List.from(data);
                  if (quantities.length != data.length) {
                    quantities = List<int>.filled(data.length, 1);
                  }

                  return ListView.separated(
                    itemBuilder: (context, index) {
                      final order = data[index];
                      final imgUrl = order['imgUrl'] ?? '';

                      return ItemCard(
                        name: order['name'],
                        price: order['price'],
                        imgUrl:
                            imgUrl.isNotEmpty ? imgUrl : 'default_image_url',
                        count: quantities[index],
                        onQuantityChanged: (newCount) {
                          setState(() {
                            quantities[index] = newCount;
                          });
                        },
                        onRemove: () {
                          removeItem(order['name']);
                        },
                      );
                    },
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 10),
                    itemCount: data.length,
                  );
                },
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Voucher Discount',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: voucherController,
                          decoration: InputDecoration(
                            hintText: 'Enter voucher code',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.orange, width: 2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: DropdownButton<String>(
                          value:
                              selectedVoucher.isEmpty ? null : selectedVoucher,
                          hint: const Text('Select voucher'),
                          items: vouchers.map((voucher) {
                            return DropdownMenuItem<String>(
                              value: voucher['label'],
                              child: Row(
                                children: [
                                  Icon(voucher['icon'], color: Colors.orange),
                                  const SizedBox(width: 8),
                                  Text(voucher['label']),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              selectedVoucher = value ?? '';
                              var selected = vouchers.firstWhere(
                                  (voucher) => voucher['label'] == value);
                              discount = selected['num'] ?? 0;
                              voucherController.clear();
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: () async {
                addDiscount(discount);
                _updateQuantities();
                await DatabaseService().updateOrdersQuantities(
                    items, quantities, widget.buyer.userName);

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PaymentInfo(buyer: widget.buyer),
                  ),
                );
              },
              child: Row(
                mainAxisSize: MainAxisSize.max,
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: Container(
                        height: 40,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: const Color(0xffF57C51),
                        ),
                        child: Center(
                          child: Text(
                            "Pay",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
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
    );
  }
}

// ItemCard widget to display each cart item
class ItemCard extends StatefulWidget {
  final String name;
  final num price;
  final String imgUrl;
  final num count;
  final Function(int) onQuantityChanged;
  final Function() onRemove;

  const ItemCard({
    super.key,
    required this.name,
    required this.price,
    required this.imgUrl,
    required this.count,
    required this.onQuantityChanged,
    required this.onRemove,
  });

  @override
  State<ItemCard> createState() => _ItemCardState();
}

class _ItemCardState extends State<ItemCard> {
  final TextEditingController _controller = TextEditingController();
  int _count = 1;

  @override
  void initState() {
    super.initState();
    _count = widget.count.toInt();
    _controller.text = _count.toString();
  }

  void _increment() {
    Future.delayed(Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          _count++;
          _controller.text = _count.toString();
          widget.onQuantityChanged(_count);
        });
      }
    });
  }

  void _decrement() {
    setState(() {
      if (_count > 1) {
        _count--;
        _controller.text = _count.toString();
        widget.onQuantityChanged(_count);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(widget.name),
      direction: DismissDirection.endToStart,
      onDismissed: (direction) {
        widget.onRemove();
      },
      background: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.red, Colors.redAccent.shade700],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Icon(
              Icons.delete_forever,
              color: Colors.white,
              size: 30,
            ),
            const SizedBox(width: 10),
            Text(
              'Delete',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 5,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        padding: const EdgeInsets.all(10),
        margin: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFFF9203), width: 2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  widget.imgUrl,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Center(
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
                            : null,
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    "\$${widget.price}",
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.remove),
              onPressed: _decrement,
            ),
            SizedBox(
              width: 40,
              child: TextField(
                controller: _controller,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                onChanged: (value) {
                  setState(() {
                    _count = int.tryParse(value) ?? 1;
                  });
                  widget.onQuantityChanged(_count);
                },
              ),
            ),
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: _increment,
            ),
          ],
        ),
      ),
    );
  }
}
