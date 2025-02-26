import 'dart:developer';
import 'dart:async';
import 'package:campus_catalogue/models/buyer_model.dart';
import 'package:campus_catalogue/models/order_model.dart';
import 'package:campus_catalogue/screens/Scanner/QRCodeScreen.dart';
import 'package:campus_catalogue/screens/Scanner/scanner.dart';
import 'package:campus_catalogue/screens/api_chart.dart';
import 'package:campus_catalogue/screens/cart.dart';
import 'package:campus_catalogue/screens/history_user_page.dart';
import 'package:campus_catalogue/screens/map_screen.dart';
// import 'package:campus_catalogue/screens/map_screen.dart';
import 'package:campus_catalogue/screens/ntf_user_page.dart';
import 'package:campus_catalogue/screens/profile_use_page.dart';
import 'package:campus_catalogue/screens/search_screen.dart';
import 'package:campus_catalogue/screens/shop_info.dart';
import 'package:campus_catalogue/screens/userType_screen.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:campus_catalogue/constants/colors.dart';
import 'package:campus_catalogue/constants/typography.dart';
import 'package:flutter/cupertino.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class ShopHeader extends StatelessWidget {
  final String name;
  const ShopHeader({super.key, required this.name});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topLeft,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 10, 0),
        child: Text(name,
            style: AppTypography.textMd.copyWith(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.secondary)),
      ),
    );
  }
}

class ShopCardWrapper extends StatelessWidget {
  final Buyer buyer;
  final List shops; // Map {name, imgURL, rating, location}

  const ShopCardWrapper({
    super.key,
    required this.shops,
    required this.buyer,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 200,
      child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(20, 0, 10, 0),
          itemCount: shops.length,
          shrinkWrap: true,
          itemBuilder: (BuildContext context, int index) {
            return Padding(
                padding: const EdgeInsets.fromLTRB(0, 0, 5, 0),
                child: GestureDetector(
                  onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => ShopPage(
                                name: shops[index]["shop_name"],
                                rating: "0",
                                location: shops[index]["location"],
                                menu: shops[index]["menu"],
                                ownerName: shops[index]["owner_name"],
                                upiID: shops[index]["upi_id"],
                                buyer: buyer,
                              ))),
                  child: ShopCard(
                      name: shops[index]["shop_name"],
                      // rating: "0",
                      location: shops[index]["location"],
                      menu: shops[index]["menu"],
                      ownerName: shops[index]["owner_name"],
                      upiID: shops[index]["upi_id"],
                      status: true,
                      imageUrl: shops[index]["img"]),
                ));
          }),
    );
  }
}

class ShopCard extends StatefulWidget {
  final String name;
  // final String rating;
  final String location;
  final List menu;
  final String ownerName;
  final String upiID;
  final bool status;
  final String imageUrl;
  const ShopCard({
    super.key,
    required this.name,
    required this.location,
    required this.menu,
    required this.ownerName,
    required this.upiID,
    required this.status,
    required this.imageUrl,
  });
  @override
  State<ShopCard> createState() => _ShopCardState();
}

class _ShopCardState extends State<ShopCard> {
  Future<double> getRating(String shopName) async {
    double totalRating = 0;
    int index = 0;
    QuerySnapshot snap = await FirebaseFirestore.instance
        .collection('orders')
        .where('shop_name', isEqualTo: shopName)
        .get();
    if (snap.docs.isNotEmpty) {
      for (var doc in snap.docs) {
        var ratingData = doc['rating'];
        double rating = (ratingData is num) ? ratingData.toDouble() : 0;
        if (rating > 0) {
          totalRating += rating;
          index++;
        }
      }
    }
    return index > 0 ? totalRating / index : 0;
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 125,
      width: MediaQuery.of(context).size.width * 0.6,
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        color: const Color(0xFFFFF2E0),
        child: Stack(
          children: [
            // Display image from Firebase
            ClipRRect(
              borderRadius: const BorderRadius.all(Radius.circular(10)),
              child: Image.network(
                widget.imageUrl,
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
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
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        widget.name,
                        style: AppTypography.textMd.copyWith(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        widget.location,
                        style: AppTypography.textSm.copyWith(
                          fontSize: 10,
                          fontWeight: FontWeight.w400,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  FutureBuilder<double>(
                    future: getRating(widget.name),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Text(
                          "Loading...",
                          style: AppTypography.textSm.copyWith(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        );
                      } else if (snapshot.hasError) {
                        return Text(
                          "Error",
                          style: AppTypography.textSm.copyWith(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        );
                      } else {
                        double rating = snapshot.data ?? 0;
                        int fullStars = rating.floor();
                        bool hasHalfStar = (rating - fullStars) >= 0.5;

                        return Row(
                          children: [
                            // Display full stars
                            for (int i = 0; i < fullStars; i++)
                              const Icon(
                                Icons.star,
                                size: 12,
                                color: Colors.yellow,
                              ),
                            // Display half star if needed
                            if (hasHalfStar)
                              const Icon(
                                Icons.star_half,
                                size: 12,
                                color: Colors.yellow,
                              ),
                            // Display empty stars
                            for (int i = 0;
                                i < (5 - fullStars - (hasHalfStar ? 1 : 0));
                                i++)
                              const Icon(
                                Icons.star_border,
                                size: 12,
                                color: Colors.grey,
                              ),
                            const SizedBox(width: 4),
                            Text(
                              rating.toStringAsFixed(1),
                              style: AppTypography.textSm.copyWith(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFFFFA500),
                              ),
                            ),
                          ],
                        );
                      }
                    },
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

class RunningBorderEffect extends StatefulWidget {
  final Widget child;

  const RunningBorderEffect({Key? key, required this.child}) : super(key: key);

  @override
  _RunningBorderEffectState createState() => _RunningBorderEffectState();
}

class _RunningBorderEffectState extends State<RunningBorderEffect>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 5),
      vsync: this,
    )..repeat();

    _animation = Tween<double>(begin: 0, end: 1).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.transparent,
              width: 0.005, // Extremely thin border widthcolors
            ),
            gradient: SweepGradient(
              startAngle: 0.0,
              endAngle: 6.28, // Approx 2π radians
              colors: [
                const Color.fromRGBO(255, 152, 0, 1),
                const Color.fromARGB(255, 255, 127, 88),
                Colors.yellow,
                const Color.fromARGB(255, 250, 177, 67),
              ],
              stops: [
                _animation.value - 0.1,
                _animation.value,
                _animation.value + 0.1,
                _animation.value + 0.2,
              ].map((stop) => (stop % 1.0)).toList(),
            ),
          ),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

class LocationCardWrapper extends StatefulWidget {
  final Buyer buyer;
  const LocationCardWrapper({super.key, required this.buyer});

  @override
  State<LocationCardWrapper> createState() => _LocationCardWrapperState();
}

class _LocationCardWrapperState extends State<LocationCardWrapper> {
  void getShopsFromLocation(shopLocation, context) async {
    List shopSearchResults = [];
    final searchResult = await FirebaseFirestore.instance
        .collection("shop")
        .where("location", isEqualTo: shopLocation)
        .get();
    for (var doc in searchResult.docs) {
      shopSearchResults.add(doc.data());
    }
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => SearchScreen(
                  shopResults: shopSearchResults,
                  isSearch: true,
                  title: "Explore IITG",
                  buyer: widget.buyer,
                )));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
        padding: const EdgeInsets.fromLTRB(20, 35, 10, 0),
        child: Align(
          alignment: Alignment.topLeft,
          child: Column(
            // crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Align(
                alignment: Alignment.topLeft,
                child: Text("What are you looking for?",
                    style: AppTypography.textMd.copyWith(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.secondary)),
              ),
              Align(
                alignment: Alignment.topLeft,
                child: Wrap(spacing: 8.8, runSpacing: 6.5, children: [
                  GestureDetector(
                    onTap: () =>
                        getShopsFromLocation("Hostel Canteen", context),
                    child: RunningBorderEffect(
                      child: LocationCard(
                        name: "Hostel Canteens",
                        imgURL: "assets/hostel_canteens.png",
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () =>
                        getShopsFromLocation("Hostel Juice Centre", context),
                    child: RunningBorderEffect(
                      child: LocationCard(
                          name: "Hostel Juice Phenikaa",
                          imgURL: "assets/core_canteens.png"),
                    ),
                  ),
                  GestureDetector(
                    onTap: () =>
                        getShopsFromLocation("Market Complex", context),
                    child: RunningBorderEffect(
                      child: LocationCard(
                          name: "Market Complex Phenikaa",
                          imgURL: "assets/market_complex.png"),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => getShopsFromLocation("Khokha Market", context),
                    child: RunningBorderEffect(
                      child: LocationCard(
                          name: "Khokha Market Phenikaa",
                          imgURL: "assets/khokha_stalls.png"),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => getShopsFromLocation("Food Court", context),
                    child: RunningBorderEffect(
                      child: LocationCard(
                          name: "Food Court Phenikaa",
                          imgURL: "assets/food_court.png"),
                    ),
                  ),
                  GestureDetector(
                    onTap: () =>
                        getShopsFromLocation("Swimming Pool Area", context),
                    child: RunningBorderEffect(
                      child: LocationCard(
                          name: "Swimming Pool Phe",
                          imgURL: "assets/food_van.png"),
                    ),
                  ),
                ]),
              ),
            ],
          ),
        ));
  }
}

class LocationCard extends StatelessWidget {
  final String name;
  final String imgURL;
  const LocationCard({super.key, required this.name, required this.imgURL});
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 130,
      width: MediaQuery.of(context).size.width * 0.285,
      child: Card(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          color: const Color(0xFFFFF2E0),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Image.asset(imgURL),
                Padding(
                  padding: const EdgeInsets.fromLTRB(0, 0, 0, 8),
                  child: Text(
                    name,
                    style: AppTypography.textMd.copyWith(fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                )
              ],
            ),
          )),
    );
  }
}

class SearchInput extends StatefulWidget {
  final Buyer buyer;
  const SearchInput({super.key, required this.buyer});

  @override
  State<SearchInput> createState() => _SearchInputState();
}

class _SearchInputState extends State<SearchInput> {
  final searchController = TextEditingController();
  List<String> searchTerms = [];
  List<dynamic> shopSearchResult = [];

  @override
  void dispose() {
    // Clean up the controller when the widget is disposed.
    searchController.dispose();
    super.dispose();
  }

  Future<List<dynamic>> getSearchResult(String searchTerm) async {
    final searchResult = await FirebaseFirestore.instance
        .collection("cache")
        .doc(searchTerm)
        .get();

    // Kiểm tra tài liệu có tồn tại không
    if (searchResult.exists) {
      return searchResult['list'] ?? [];
    } else {
      return [];
    }
  }

  void searchSubmit(BuildContext context) async {
    searchTerms = searchController.text.split(' ');
    Set<dynamic> shops = {};

    for (String term in searchTerms) {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection("shop")
          .where("shop_name", isGreaterThanOrEqualTo: term)
          .where("shop_name", isLessThanOrEqualTo: term + '\uf8ff')
          .get();

      for (var shopDoc in querySnapshot.docs) {
        shops.add(shopDoc.data());
      }
    }

    if (shops.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SearchScreen(
            shopResults: shops.toList(),
            isSearch: true,
            title: "Explore IITG",
            buyer: widget.buyer,
          ),
        ),
      );
    } else {
      // Hiển thị thông báo nếu không tìm thấy kết quả nào
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không tìm thấy kết quả nào.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 15, 25, 0),
      child: Column(
        children: [
          Row(
            children: [
              Flexible(
                flex: 1,
                child: TextField(
                  controller: searchController,
                  onSubmitted: (e) => searchSubmit(context),
                  autofocus: false,
                  cursorColor: Colors.grey,
                  decoration: InputDecoration(
                    isDense: true,
                    fillColor: Colors.white,
                    filled: true,
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(
                          width: 2.5, color: Color.fromARGB(255, 255, 146, 57)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(
                          width: 2.5, color: Color.fromARGB(255, 255, 146, 57)),
                    ),
                    hintText: 'Search',
                    hintStyle:
                        const TextStyle(color: Colors.grey, fontSize: 18),
                    suffixIcon: const Icon(
                      Icons.search,
                      color: AppColors.secondary,
                      size: 30,
                    ),
                  ),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }
}

class AutoScrollShopList extends StatefulWidget {
  final List
      shops; // Map {name, imgURL, rating, location, menu, ownerName, upiID}
  final Buyer buyer;

  const AutoScrollShopList({
    Key? key,
    required this.shops,
    required this.buyer,
  }) : super(key: key);

  @override
  _AutoScrollShopListState createState() => _AutoScrollShopListState();
}

class _AutoScrollShopListState extends State<AutoScrollShopList> {
  late final PageController _pageController;
  int _currentPage = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.8);

    // Thiết lập Timer để tự động cuộn
    _timer = Timer.periodic(Duration(seconds: 3), (timer) {
      if (_currentPage < widget.shops.length - 1) {
        _currentPage++;
      } else {
        _currentPage = 0;
      }
      _pageController.animateToPage(
        _currentPage,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 200,
      width: 400,
      child: PageView.builder(
        controller: _pageController,
        itemCount: widget.shops.length,
        itemBuilder: (context, index) {
          final shop = widget.shops[index];
          return GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ShopPage(
                  name: shop["shop_name"],
                  rating: "0",
                  location: shop["location"],
                  menu: shop["menu"],
                  ownerName: shop["owner_name"],
                  upiID: shop["upi_id"],
                  buyer: widget.buyer,
                ),
              ),
            ),
            child: ShopCard(
              name: shop["shop_name"],
              location: shop["location"],
              menu: shop["menu"],
              ownerName: shop["owner_name"],
              upiID: shop["upi_id"],
              status: true,
              imageUrl: shop["img"],
            ),
          );
        },
      ),
    );
  }
}
