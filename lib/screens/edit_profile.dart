import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../controller/controller.dart';

class EditProfile extends StatelessWidget {
  final userName;
  final url;
  final number;

  EditProfile(this.userName, this.url, this.number);

  final TextEditingController _nameController = TextEditingController();
  // final TextEditingController _emailController = TextEditingController();
  // final TextEditingController _aboutController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    _nameController.value = _nameController.value.copyWith(
      text: userName,
    );

    var isLoading = false.obs;

    PickedFile? imageFile;
    Future _takePicture() async {
      imageFile = await ImagePicker.platform.pickImage(
        source: ImageSource.gallery,
        maxWidth: 600,
      );
      if (imageFile == null) {
        return;
      }
      Get.find<Controller>().setUserProfileImage(
        File(imageFile!.path),
      );
    }

    return Obx(
      () => Stack(
        children: [
          Scaffold(
            backgroundColor: Colors.white,
            appBar: AppBar(
              backgroundColor: Colors.white,
              elevation: 0,
              leading: IconButton(
                icon: Icon(
                  Icons.arrow_back,
                  color: Colors.black,
                ),
                onPressed: () {
                  Get.back();
                },
              ),
              actions: [
                GestureDetector(
                  onTap: () async {
                    FocusManager.instance.primaryFocus?.unfocus();
                    isLoading.value = true;
                    var url;
                    if (Get.find<Controller>().userProfileImage != null) {
                      final ref = FirebaseStorage.instance
                          .ref()
                          .child('user_image')
                          .child(
                              "${FirebaseAuth.instance.currentUser?.uid}.jpg");
                      await ref
                          .putFile(Get.find<Controller>().userProfileImage);
                      url = await ref.getDownloadURL();
                    }
                    await FirebaseFirestore.instance
                        .collection("users")
                        .doc(FirebaseAuth.instance.currentUser?.uid)
                        .update({
                      'username': _nameController.text,
                      'profileUrl': url ?? url,
                    });
                    isLoading.value = false;

                    Get.back();
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(15.0),
                    child: Icon(
                      Icons.save,
                      color: Colors.black,
                    ),
                  ),
                ),
              ],
              centerTitle: true,
              title: const Text(
                "Edit Profile",
                style: TextStyle(
                  color: Colors.black,
                  letterSpacing: 1,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            body: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 25.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Center(
                          child: Column(
                            children: [
                              SizedBox(
                                height: 20,
                              ),
                              Stack(
                                children: [
                                  GetBuilder<Controller>(
                                    builder: (getController) => CircleAvatar(
                                      radius: 65,
                                      backgroundColor: Color(0xFFedeff0),
                                      backgroundImage: url == null
                                          ? null
                                          : NetworkImage(url),
                                      child: CircleAvatar(
                                        radius: 65,
                                        backgroundColor: Colors.transparent,
                                        backgroundImage: getController
                                                    .userProfileImage ==
                                                null
                                            ? null
                                            : FileImage(
                                                getController.userProfileImage),
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    bottom: 0,
                                    right: 0,
                                    child: FloatingActionButton.small(
                                      onPressed: () {
                                        _takePicture();
                                      },
                                      child: const Icon(Icons.edit),
                                    ),
                                  )
                                ],
                              ),
                              SizedBox(
                                height: 15,
                              ),
                              Text(
                                userName,
                                style: TextStyle(
                                  fontSize: 25,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              SizedBox(
                                height: 15,
                              ),
                              Text(
                                number,
                                style: TextStyle(
                                  fontSize: 15,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(
                          height: 30,
                        ),
                        Text(
                          "Username",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w400,
                            color: Colors.grey,
                          ),
                        ),
                        TextField(
                          controller: _nameController,
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold),
                          textCapitalization: TextCapitalization.sentences,
                        ),
                        // SizedBox(
                        //   height: 30,
                        // ),
                        // Text(
                        //   "Email Address",
                        //   style: TextStyle(
                        //     fontSize: 20,
                        //     fontWeight: FontWeight.w400,
                        //     color: Colors.grey,
                        //   ),
                        // ),
                        // TextField(
                        //   controller: _emailController,
                        //   keyboardType: TextInputType.emailAddress,
                        //   style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        // ),
                        // SizedBox(
                        //   height: 30,
                        // ),
                        // Text(
                        //   "About",
                        //   style: TextStyle(
                        //     fontSize: 20,
                        //     fontWeight: FontWeight.w400,
                        //     color: Colors.grey,
                        //   ),
                        // ),
                        // TextField(
                        //   controller: _aboutController,
                        //   style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        //   textCapitalization: TextCapitalization.sentences,
                        // ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isLoading.value)
            Container(
              color: Color(0x85000000),
              child: Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }
}
