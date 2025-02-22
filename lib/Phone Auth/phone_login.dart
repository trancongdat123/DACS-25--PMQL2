import 'package:campus_catalogue/Phone%20Auth/otp_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class PhoneAuthentication extends StatefulWidget {
  const PhoneAuthentication({super.key});

  @override
  State<PhoneAuthentication> createState() => _PhoneAuthenticationState();
}

class _PhoneAuthenticationState extends State<PhoneAuthentication> {
  TextEditingController phoneController = TextEditingController();
  bool isLoading = false;
  String? errorMessage; // Để hiển thị lỗi nếu có

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 0),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
        onPressed: () {
          // Hiển thị hộp thoại nhập số điện thoại khi người dùng bấm vào nút
          myDialogBox(context);
        },
        child: Row(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Image.network(
                "https://static.vecteezy.com/system/resources/thumbnails/010/829/986/small/phone-icon-in-trendy-flat-style-free-png.png",
                height: 20,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              "Sign in with Phone",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: Colors.white,
              ),
            )
          ],
        ),
      ),
    );
  }

  void myDialogBox(BuildContext context) {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: Colors.white,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const SizedBox(),
                      const Text(
                        "Phone Authentication",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: "+841234567890",
                      labelText: "Enter Phone Number",
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (errorMessage != null)
                    Text(
                      errorMessage!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  const SizedBox(height: 10),
                  isLoading
                      ? const CircularProgressIndicator()
                      : ElevatedButton(
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green),
                          onPressed: () async {
                            if (_validatePhoneNumber()) {
                              await _verifyPhoneNumber();
                            }
                          },
                          child: const Text(
                            "Send Code",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.white,
                            ),
                          ),
                        ),
                ],
              ),
            ),
          );
        });
  }

  